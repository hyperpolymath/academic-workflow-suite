use anyhow::Result;
use colored::*;
use dialoguer::{theme::ColorfulTheme, Confirm, Input, Select};
use std::fs;
use std::path::Path;

use crate::api_client::ApiClient;
use crate::models::TmaSubmission;

pub async fn mark_tma_interactive(client: &ApiClient) -> Result<()> {
    println!("{}", "Interactive TMA Marking".cyan().bold());
    println!();

    // Step 1: Select file
    println!("{}", "Step 1: Select TMA file".bold());

    let file_selection = Select::with_theme(&ColorfulTheme::default())
        .with_prompt("Choose how to select the file")
        .items(&["Browse local files", "Enter file path manually"])
        .default(0)
        .interact()?;

    let file_path = if file_selection == 0 {
        // Browse files
        let submissions_dir = ".aws/submissions";
        if !Path::new(submissions_dir).exists() {
            fs::create_dir_all(submissions_dir)?;
        }

        let mut files = Vec::new();
        if let Ok(entries) = fs::read_dir(submissions_dir) {
            for entry in entries.flatten() {
                if entry.path().is_file() {
                    files.push(entry.path().to_string_lossy().to_string());
                }
            }
        }

        if files.is_empty() {
            println!(
                "{}",
                "No files found in .aws/submissions/".yellow()
            );
            Input::new()
                .with_prompt("Enter file path")
                .interact_text()?
        } else {
            files.push("Enter path manually...".to_string());
            let selection = Select::with_theme(&ColorfulTheme::default())
                .with_prompt("Select a file")
                .items(&files)
                .default(0)
                .interact()?;

            if selection == files.len() - 1 {
                Input::new()
                    .with_prompt("Enter file path")
                    .interact_text()?
            } else {
                files[selection].clone()
            }
        }
    } else {
        Input::new()
            .with_prompt("Enter file path")
            .interact_text()?
    };

    if !Path::new(&file_path).exists() {
        return Err(anyhow::anyhow!("File not found: {}", file_path));
    }

    println!();
    println!("Selected file: {}", file_path.yellow());

    // Step 2: Student information
    println!();
    println!("{}", "Step 2: Student information".bold());

    let student_id: String = Input::new()
        .with_prompt("Student ID (optional)")
        .allow_empty(true)
        .interact_text()?;

    let assignment_id: String = Input::new()
        .with_prompt("Assignment ID (optional)")
        .allow_empty(true)
        .interact_text()?;

    // Step 3: Marking options
    println!();
    println!("{}", "Step 3: Marking options".bold());

    let use_custom_rubric = Confirm::new()
        .with_prompt("Use custom marking rubric?")
        .default(false)
        .interact()?;

    let rubric_path = if use_custom_rubric {
        Some(
            Input::new()
                .with_prompt("Rubric file path")
                .interact_text()?,
        )
    } else {
        None
    };

    // Step 4: Confirmation
    println!();
    println!("{}", "Review submission:".bold());
    println!("  File: {}", file_path);
    if !student_id.is_empty() {
        println!("  Student ID: {}", student_id);
    }
    if !assignment_id.is_empty() {
        println!("  Assignment ID: {}", assignment_id);
    }
    if let Some(rubric) = &rubric_path {
        println!("  Rubric: {}", rubric);
    }
    println!();

    let confirm = Confirm::new()
        .with_prompt("Proceed with marking?")
        .default(true)
        .interact()?;

    if !confirm {
        println!("{}", "Cancelled.".yellow());
        return Ok(());
    }

    // Step 5: Upload and mark
    println!();
    println!("{}", "Processing...".cyan().bold());

    use indicatif::{ProgressBar, ProgressStyle};

    let pb = ProgressBar::new_spinner();
    pb.set_style(
        ProgressStyle::default_spinner()
            .template("{spinner:.green} {msg}")?
            .tick_strings(&["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]),
    );

    pb.set_message("Uploading TMA...");

    let submission = TmaSubmission {
        student_id: if student_id.is_empty() {
            None
        } else {
            Some(student_id.clone())
        },
        assignment_id: if assignment_id.is_empty() {
            None
        } else {
            Some(assignment_id.clone())
        },
        file_path: file_path.clone(),
        rubric_path,
    };

    let upload_result = client.upload_tma(&submission).await?;
    pb.set_message("AI is marking the TMA...");

    let marking_result = client.mark_tma(&upload_result.id).await?;
    pb.finish_and_clear();

    // Step 6: Display results
    println!();
    println!("{}", "✓ Marking complete!".green().bold());
    println!();
    println!("{}", "Results:".bold());
    println!("{}", "─".repeat(50));
    println!("  Grade: {}", format!("{}/100", marking_result.grade).cyan().bold());

    if let Some(sid) = &marking_result.student_id {
        println!("  Student: {}", sid);
    }
    if let Some(aid) = &marking_result.assignment_id {
        println!("  Assignment: {}", aid);
    }

    println!();

    // Show feedback preview
    if let Some(feedback) = &marking_result.feedback {
        println!("{}", "Feedback Preview:".bold());
        println!("{}", "─".repeat(50));

        let lines: Vec<&str> = feedback.lines().take(10).collect();
        for line in lines {
            println!("  {}", line);
        }

        if feedback.lines().count() > 10 {
            println!("  ...");
        }

        println!("{}", "─".repeat(50));

        // Save feedback
        let feedback_path = format!(".aws/feedback/{}.txt", upload_result.id);
        fs::write(&feedback_path, feedback)?;
        println!();
        println!("Feedback saved to: {}", feedback_path.yellow());
    }

    // Step 7: Next actions
    println!();
    println!("{}", "What would you like to do next?".bold());

    let next_actions = vec![
        "View full feedback",
        "Edit feedback",
        "Mark another TMA",
        "Upload to Moodle",
        "Exit",
    ];

    let action = Select::with_theme(&ColorfulTheme::default())
        .with_prompt("Select an action")
        .items(&next_actions)
        .default(0)
        .interact()?;

    match action {
        0 => {
            // View full feedback
            if let Some(feedback) = &marking_result.feedback {
                println!();
                println!("{}", "Full Feedback:".bold());
                println!("{}", "─".repeat(80));
                println!("{}", feedback);
                println!("{}", "─".repeat(80));
            }
        }
        1 => {
            // Edit feedback
            println!();
            println!("Run: {}", format!("aws feedback {} --edit", upload_result.id).cyan());
        }
        2 => {
            // Mark another TMA
            return mark_tma_interactive(client).await;
        }
        3 => {
            // Upload to Moodle
            println!();
            println!("Run: {}", "aws sync --upload".cyan());
        }
        4 => {
            // Exit
            println!();
            println!("{}", "Thank you for using AWS!".cyan());
        }
        _ => {}
    }

    Ok(())
}
