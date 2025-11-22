use anyhow::{Context, Result};
use colored::*;
use dialoguer::Confirm;
use indicatif::{ProgressBar, ProgressStyle};
use std::process::Command;

pub async fn run(services: Vec<String>, force: bool) -> Result<()> {
    println!("{}", "Stopping AWS services...".cyan().bold());

    if !force {
        let confirm = Confirm::new()
            .with_prompt("Are you sure you want to stop AWS services?")
            .default(false)
            .interact()?;

        if !confirm {
            println!("{}", "Cancelled.".yellow());
            return Ok(());
        }
    }

    let pb = ProgressBar::new_spinner();
    pb.set_style(
        ProgressStyle::default_spinner()
            .template("{spinner:.green} {msg}")?
            .tick_strings(&["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]),
    );

    pb.set_message("Stopping services...");

    let mut cmd = Command::new("docker-compose");
    cmd.arg("down");

    if !services.is_empty() {
        // Stop specific services
        for service in &services {
            cmd.arg(service);
        }
    }

    if force {
        cmd.arg("--remove-orphans");
    }

    let output = cmd.output().context("Failed to stop services")?;

    if !output.status.success() {
        let error = String::from_utf8_lossy(&output.stderr);
        pb.finish_with_message(format!("{} Failed to stop services", "✗".red().bold()));
        eprintln!("{}", error);
        return Err(anyhow::anyhow!("Failed to stop services"));
    }

    pb.finish_with_message(format!("{} Services stopped", "✓".green().bold()));

    println!();
    println!("{}", "✓ AWS services stopped successfully!".green().bold());

    if services.is_empty() {
        println!();
        println!("All services have been stopped.");
        println!("Run {} to start them again.", "aws start".cyan());
    }

    Ok(())
}
