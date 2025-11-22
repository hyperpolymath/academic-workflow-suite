use anyhow::{Context, Result};
use colored::*;
use indicatif::{ProgressBar, ProgressStyle};
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;

use crate::api_client::ApiClient;
use crate::config::Config;

#[derive(Serialize, Deserialize)]
struct Credentials {
    username: String,
    token: String,
    moodle_url: String,
}

pub async fn run(download: bool, upload: bool, dry_run: bool) -> Result<()> {
    let config = Config::load(".aws/config.yaml").context("Failed to load configuration")?;

    // Load credentials
    let credentials_path = ".aws/credentials.json";
    if !Path::new(credentials_path).exists() {
        return Err(anyhow::anyhow!(
            "Not logged in. Run {} first.",
            "aws login".cyan()
        ));
    }

    let credentials_json = fs::read_to_string(credentials_path)?;
    let credentials: Credentials = serde_json::from_str(&credentials_json)?;

    let client = ApiClient::new(&config.backend_url)?;

    println!("{}", "Syncing with Moodle...".cyan().bold());
    println!();

    if dry_run {
        println!("{}", "DRY RUN MODE - No changes will be made".yellow().bold());
        println!();
    }

    // Download assignments
    if download || (!download && !upload) {
        println!("{}", "Downloading assignments...".bold());

        let pb = ProgressBar::new_spinner();
        pb.set_style(
            ProgressStyle::default_spinner()
                .template("{spinner:.green} {msg}")?
                .tick_strings(&["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]),
        );

        pb.set_message("Fetching assignment list...");

        let assignments = client
            .get_moodle_assignments(&credentials.moodle_url, &credentials.token)
            .await?;

        pb.finish_and_clear();

        println!(
            "{} Found {} assignment(s)",
            "✓".green().bold(),
            assignments.len().to_string().cyan().bold()
        );

        if assignments.is_empty() {
            println!("  {}", "No new assignments to download".yellow());
        } else {
            for (i, assignment) in assignments.iter().enumerate() {
                println!(
                    "  {}. {} (Due: {})",
                    i + 1,
                    assignment.name,
                    assignment.due_date.as_ref().unwrap_or(&"N/A".to_string())
                );

                if !dry_run {
                    // Download submissions
                    let submissions_dir = format!(".aws/submissions/{}", assignment.id);
                    fs::create_dir_all(&submissions_dir)?;

                    for submission in &assignment.submissions {
                        let file_path = format!(
                            "{}/{}_{}.pdf",
                            submissions_dir, submission.student_id, assignment.id
                        );

                        client
                            .download_submission(&submission.url, &file_path)
                            .await?;
                    }

                    println!(
                        "    Downloaded {} submission(s)",
                        assignment.submissions.len()
                    );
                }
            }
        }

        println!();
    }

    // Upload feedback
    if upload || (!download && !upload) {
        println!("{}", "Uploading feedback...".bold());

        // Find feedback files
        let feedback_dir = Path::new(".aws/feedback");
        if !feedback_dir.exists() {
            println!("  {}", "No feedback files to upload".yellow());
        } else {
            let feedback_files: Vec<_> = fs::read_dir(feedback_dir)?
                .filter_map(|e| e.ok())
                .filter(|e| e.path().extension().map_or(false, |ext| ext == "txt"))
                .collect();

            println!(
                "{} Found {} feedback file(s)",
                "✓".green().bold(),
                feedback_files.len().to_string().cyan().bold()
            );

            if feedback_files.is_empty() {
                println!("  {}", "No feedback to upload".yellow());
            } else {
                let pb = ProgressBar::new(feedback_files.len() as u64);
                pb.set_style(
                    ProgressStyle::default_bar()
                        .template("{msg}\n{bar:40.cyan/blue} {pos}/{len}")?
                        .progress_chars("#>-"),
                );
                pb.set_message("Uploading feedback:");

                for file in feedback_files {
                    let file_path = file.path();
                    let file_name = file_path.file_stem().unwrap().to_string_lossy();

                    if !dry_run {
                        let feedback_content = fs::read_to_string(&file_path)?;

                        client
                            .upload_moodle_feedback(
                                &credentials.moodle_url,
                                &credentials.token,
                                &file_name,
                                &feedback_content,
                            )
                            .await?;

                        println!("  {} Uploaded feedback for {}", "✓".green().bold(), file_name);
                    } else {
                        println!("  Would upload feedback for {}", file_name);
                    }

                    pb.inc(1);
                }

                pb.finish_and_clear();
            }
        }
    }

    println!();
    if dry_run {
        println!("{}", "DRY RUN COMPLETE - No changes were made".yellow().bold());
        println!("Run without {} to apply changes", "--dry-run".cyan());
    } else {
        println!("{}", "✓ Sync complete!".green().bold());
    }

    Ok(())
}
