use anyhow::{Context, Result};
use colored::*;
use indicatif::{MultiProgress, ProgressBar, ProgressStyle};
use std::path::Path;
use tokio::sync::Semaphore;
use walkdir::WalkDir;

use crate::api_client::ApiClient;
use crate::config::Config;
use crate::models::TmaSubmission;

pub async fn run(directory: String, pattern: String, concurrency: usize) -> Result<()> {
    let config = Config::load(".aws/config.yaml").context("Failed to load configuration")?;
    let client = ApiClient::new(&config.backend_url)?;

    println!("{}", "Batch Marking TMAs...".cyan().bold());
    println!();

    // Find matching files
    let dir_path = Path::new(&directory);
    if !dir_path.exists() {
        return Err(anyhow::anyhow!("Directory not found: {}", directory));
    }

    let mut files = Vec::new();
    for entry in WalkDir::new(dir_path).max_depth(2) {
        let entry = entry?;
        if entry.file_type().is_file() {
            let file_name = entry.file_name().to_string_lossy();

            // Simple pattern matching (in production, use glob crate)
            if pattern == "*.pdf" && file_name.ends_with(".pdf")
                || pattern == "*.docx" && file_name.ends_with(".docx")
                || pattern == "*" && (file_name.ends_with(".pdf") || file_name.ends_with(".docx"))
            {
                files.push(entry.path().to_path_buf());
            }
        }
    }

    if files.is_empty() {
        println!("{}", "No matching files found.".yellow());
        return Ok(());
    }

    println!(
        "Found {} file(s) matching pattern '{}'",
        files.len().to_string().cyan().bold(),
        pattern.yellow()
    );
    println!();

    // Create progress bars
    let multi_progress = MultiProgress::new();
    let overall_pb = multi_progress.add(ProgressBar::new(files.len() as u64));
    overall_pb.set_style(
        ProgressStyle::default_bar()
            .template("{msg}\n{bar:40.cyan/blue} {pos}/{len} ({eta})")?
            .progress_chars("#>-"),
    );
    overall_pb.set_message("Overall progress:");

    // Semaphore for concurrency control
    let semaphore = std::sync::Arc::new(Semaphore::new(concurrency));
    let mut tasks = Vec::new();

    for file_path in files {
        let client = client.clone();
        let semaphore = semaphore.clone();
        let overall_pb = overall_pb.clone();
        let multi_progress = multi_progress.clone();

        let task = tokio::spawn(async move {
            let _permit = semaphore.acquire().await.unwrap();

            // Create progress bar for this file
            let pb = multi_progress.add(ProgressBar::new_spinner());
            pb.set_style(
                ProgressStyle::default_spinner()
                    .template("{spinner:.green} {msg}")?
                    .tick_strings(&["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]),
            );

            let file_name = file_path.file_name().unwrap().to_string_lossy().to_string();
            pb.set_message(format!("Processing {}...", file_name));

            // Upload and mark
            let submission = TmaSubmission {
                file_path: file_path.to_string_lossy().to_string(),
                ..Default::default()
            };

            let result = match client.upload_tma(&submission).await {
                Ok(upload_result) => match client.mark_tma(&upload_result.id).await {
                    Ok(marking_result) => {
                        pb.finish_with_message(format!(
                            "{} {} - Grade: {}/100",
                            "✓".green().bold(),
                            file_name,
                            marking_result.grade
                        ));

                        // Save feedback
                        let feedback_path = format!(".aws/feedback/{}.txt", upload_result.id);
                        if let Some(feedback) = &marking_result.feedback {
                            let _ = std::fs::write(&feedback_path, feedback);
                        }

                        Ok((file_name, marking_result.grade))
                    }
                    Err(e) => {
                        pb.finish_with_message(format!(
                            "{} {} - Error: {}",
                            "✗".red().bold(),
                            file_name,
                            e
                        ));
                        Err(e)
                    }
                },
                Err(e) => {
                    pb.finish_with_message(format!(
                        "{} {} - Upload failed: {}",
                        "✗".red().bold(),
                        file_name,
                        e
                    ));
                    Err(e)
                }
            };

            overall_pb.inc(1);
            result
        });

        tasks.push(task);
    }

    // Wait for all tasks
    let results = futures::future::join_all(tasks).await;

    overall_pb.finish_with_message("Batch marking complete!");

    // Summarize results
    println!();
    println!("{}", "Batch Marking Summary".bold());
    println!("{}", "─".repeat(50));

    let mut successful = 0;
    let mut failed = 0;
    let mut total_grade = 0.0;

    for result in results {
        match result {
            Ok(Ok((_, grade))) => {
                successful += 1;
                total_grade += grade as f64;
            }
            _ => {
                failed += 1;
            }
        }
    }

    println!("Total processed: {}", (successful + failed).to_string().cyan().bold());
    println!("{} Successful: {}", "✓".green().bold(), successful);
    if failed > 0 {
        println!("{} Failed: {}", "✗".red().bold(), failed);
    }

    if successful > 0 {
        let average = total_grade / successful as f64;
        println!();
        println!("Average grade: {:.1}/100", average);
    }

    println!();
    println!("Feedback files saved to: {}", ".aws/feedback/".yellow());
    println!();
    println!("Next steps:");
    println!("  • Review feedback files");
    println!("  • Upload to Moodle: {}", "aws sync --upload".cyan());

    Ok(())
}
