use anyhow::{Context, Result};
use colored::*;
use indicatif::{ProgressBar, ProgressStyle};
use std::process::Command;
use std::thread;
use std::time::Duration;

use crate::api_client::ApiClient;
use crate::config::Config;

pub async fn run(services: Vec<String>, detach: bool) -> Result<()> {
    let config = Config::load(".aws/config.yaml").context("Failed to load configuration")?;

    println!("{}", "Starting AWS services...".cyan().bold());
    println!();

    let all_services = vec![
        "backend",
        "frontend",
        "database",
        "ai-service",
        "moodle-connector",
    ];

    let services_to_start = if services.is_empty() {
        all_services.clone()
    } else {
        services
            .iter()
            .filter(|s| all_services.contains(&s.as_str()))
            .map(|s| s.to_string())
            .collect()
    };

    if services_to_start.is_empty() {
        println!("{}", "No valid services specified.".yellow());
        return Ok(());
    }

    // Start services using docker-compose
    let pb = ProgressBar::new(services_to_start.len() as u64);
    pb.set_style(
        ProgressStyle::default_bar()
            .template("{spinner:.green} [{bar:40.cyan/blue}] {pos}/{len} {msg}")?
            .progress_chars("#>-"),
    );

    for service in &services_to_start {
        pb.set_message(format!("Starting {}...", service));

        let mut cmd = Command::new("docker-compose");
        cmd.arg("up").arg("-d");

        if !services.is_empty() {
            cmd.arg(service);
        }

        let output = cmd
            .output()
            .context(format!("Failed to start {}", service))?;

        if !output.status.success() {
            let error = String::from_utf8_lossy(&output.stderr);
            println!(
                "{} Failed to start {}: {}",
                "✗".red().bold(),
                service,
                error
            );
            pb.inc(1);
            continue;
        }

        println!("{} {} started", "✓".green().bold(), service);
        pb.inc(1);
    }

    pb.finish_and_clear();

    // Wait for services to be healthy
    if !detach {
        println!();
        println!("{}", "Waiting for services to be healthy...".cyan());

        let health_pb = ProgressBar::new_spinner();
        health_pb.set_style(
            ProgressStyle::default_spinner()
                .template("{spinner:.green} {msg}")?
                .tick_strings(&["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]),
        );

        health_pb.set_message("Checking backend health...");

        // Try to connect to the backend
        let client = ApiClient::new(&config.backend_url)?;
        let mut attempts = 0;
        let max_attempts = 30;

        loop {
            health_pb.tick();

            match client.health_check().await {
                Ok(_) => {
                    health_pb.finish_with_message("All services are healthy!".green().to_string());
                    break;
                }
                Err(_) => {
                    attempts += 1;
                    if attempts >= max_attempts {
                        health_pb.finish_with_message(
                            "Services started but health check timed out".yellow().to_string(),
                        );
                        break;
                    }
                    thread::sleep(Duration::from_secs(1));
                }
            }
        }
    }

    println!();
    println!("{}", "✓ AWS services started successfully!".green().bold());
    println!();
    println!("Access points:");
    println!("  Frontend: {}", "http://localhost:3000".cyan());
    println!("  Backend API: {}", config.backend_url.cyan());
    println!();
    println!("Run {} to check service status", "aws status".cyan());

    Ok(())
}
