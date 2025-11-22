use anyhow::{Context, Result};
use colored::*;
use indicatif::{ProgressBar, ProgressStyle};
use std::path::Path;

use crate::api_client::ApiClient;
use crate::config::Config;
use crate::interactive;
use crate::models::TmaSubmission;

pub async fn run(
    file: Option<String>,
    student: Option<String>,
    assignment: Option<String>,
    interactive_mode: bool,
) -> Result<()> {
    let config = Config::load(".aws/config.yaml").context("Failed to load configuration")?;
    let client = ApiClient::new(&config.backend_url)?;

    if interactive_mode {
        return interactive::mark_tma_interactive(&client).await;
    }

    // Non-interactive mode
    let file_path = file.ok_or_else(|| anyhow::anyhow!("TMA file path is required"))?;

    if !Path::new(&file_path).exists() {
        return Err(anyhow::anyhow!("File not found: {}", file_path));
    }

    println!("{}", "Marking TMA...".cyan().bold());
    println!();
    println!("File: {}", file_path.yellow());

    // Upload file
    let pb = ProgressBar::new_spinner();
    pb.set_style(
        ProgressStyle::default_spinner()
            .template("{spinner:.green} {msg}")?
            .tick_strings(&["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]),
    );

    pb.set_message("Uploading TMA...");

    let submission = TmaSubmission {
        student_id: student.clone(),
        assignment_id: assignment.clone(),
        file_path: file_path.clone(),
        ..Default::default()
    };

    let upload_result = client.upload_tma(&submission).await?;
    pb.finish_and_clear();

    println!("{} TMA uploaded (ID: {})", "✓".green().bold(), upload_result.id);

    // Start marking
    let pb = ProgressBar::new_spinner();
    pb.set_style(
        ProgressStyle::default_spinner()
            .template("{spinner:.green} {msg}")?
            .tick_strings(&["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]),
    );

    pb.set_message("AI is marking the TMA...");

    let marking_result = client.mark_tma(&upload_result.id).await?;

    pb.finish_and_clear();

    // Display results
    println!();
    println!("{}", "✓ Marking complete!".green().bold());
    println!();
    println!("{}", "Results:".bold());
    println!("  Grade: {}", format!("{}/100", marking_result.grade).cyan().bold());
    println!("  Student: {}", marking_result.student_id.unwrap_or_default());
    println!("  Assignment: {}", marking_result.assignment_id.unwrap_or_default());
    println!();

    // Show summary feedback
    if let Some(feedback) = &marking_result.feedback {
        println!("{}", "Feedback Summary:".bold());
        println!("{}", "─".repeat(50));

        // Show first 5 lines of feedback
        let lines: Vec<&str> = feedback.lines().take(5).collect();
        for line in lines {
            println!("  {}", line);
        }

        if feedback.lines().count() > 5 {
            println!("  ...");
            println!();
            println!("View full feedback: {}", format!("aws feedback {}", upload_result.id).cyan());
        }
    }

    // Save feedback locally
    let feedback_path = format!(".aws/feedback/{}.txt", upload_result.id);
    if let Some(feedback) = &marking_result.feedback {
        std::fs::write(&feedback_path, feedback)?;
        println!();
        println!("Feedback saved to: {}", feedback_path.yellow());
    }

    println!();
    println!("Next steps:");
    println!("  • Review feedback: {}", format!("aws feedback {} --edit", upload_result.id).cyan());
    println!("  • Upload to Moodle: {}", "aws sync --upload".cyan());

    Ok(())
}
