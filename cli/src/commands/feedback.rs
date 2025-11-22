use anyhow::{Context, Result};
use colored::*;
use std::fs;
use std::io::Write;
use std::path::Path;
use std::process::Command;

use crate::api_client::ApiClient;
use crate::config::Config;

pub async fn run(id: String, edit: bool, output: Option<String>) -> Result<()> {
    let config = Config::load(".aws/config.yaml").context("Failed to load configuration")?;
    let client = ApiClient::new(&config.backend_url)?;

    println!("{}", "Retrieving feedback...".cyan().bold());

    // Try to find feedback locally first
    let local_path = format!(".aws/feedback/{}.txt", id);
    let feedback_content = if Path::new(&local_path).exists() {
        fs::read_to_string(&local_path)?
    } else {
        // Fetch from API
        let feedback = client.get_feedback(&id).await?;

        // Save locally
        fs::write(&local_path, &feedback.content)?;
        feedback.content
    };

    if edit {
        // Open in editor
        let editor = std::env::var("EDITOR").unwrap_or_else(|_| "nano".to_string());

        println!("Opening in {}...", editor);
        println!();

        let status = Command::new(&editor)
            .arg(&local_path)
            .status()
            .context("Failed to open editor")?;

        if !status.success() {
            return Err(anyhow::anyhow!("Editor exited with error"));
        }

        // Read the edited content
        let edited_content = fs::read_to_string(&local_path)?;

        // Ask if user wants to save back to API
        println!();
        use dialoguer::Confirm;
        let save = Confirm::new()
            .with_prompt("Save changes back to server?")
            .default(true)
            .interact()?;

        if save {
            client.update_feedback(&id, &edited_content).await?;
            println!("{}", "✓ Feedback updated".green().bold());
        }
    } else {
        // Display feedback
        println!();
        println!("{}", "Feedback Content".bold());
        println!("{}", "─".repeat(80));
        println!();
        println!("{}", feedback_content);
        println!();
        println!("{}", "─".repeat(80));
        println!();
        println!("Feedback ID: {}", id.cyan());
        println!("File: {}", local_path.yellow());
    }

    // Export to file if requested
    if let Some(output_path) = output {
        fs::write(&output_path, &feedback_content)?;
        println!();
        println!("{} Feedback exported to: {}", "✓".green().bold(), output_path.yellow());
    }

    if !edit {
        println!();
        println!("Edit feedback: {}", format!("aws feedback {} --edit", id).cyan());
    }

    Ok(())
}
