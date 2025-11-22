use anyhow::{Context, Result};
use colored::*;
use std::process::Command;

use crate::api_client::ApiClient;
use crate::config::Config;
use crate::output;

#[derive(Debug)]
struct ServiceStatus {
    name: String,
    status: String,
    health: String,
    ports: String,
}

pub async fn run(detailed: bool) -> Result<()> {
    let config = Config::load(".aws/config.yaml").context("Failed to load configuration")?;

    println!("{}", "AWS Service Status".cyan().bold());
    println!();

    // Check Docker services
    let output = Command::new("docker-compose")
        .arg("ps")
        .arg("--format")
        .arg("json")
        .output()
        .context("Failed to check service status")?;

    if !output.status.success() {
        println!(
            "{}",
            "No services running or docker-compose not available".yellow()
        );
        return Ok(());
    }

    let docker_output = String::from_utf8_lossy(&output.stdout);

    // Parse service status
    let mut services = Vec::new();

    // Simple parsing (in production, use proper JSON parsing)
    for line in docker_output.lines() {
        if line.trim().is_empty() {
            continue;
        }

        // This is a simplified version - in production, parse the JSON properly
        services.push(ServiceStatus {
            name: "backend".to_string(),
            status: "running".to_string(),
            health: "healthy".to_string(),
            ports: "8000:8000".to_string(),
        });
    }

    // Check backend health
    println!("{}", "Backend Services:".bold());
    let client = ApiClient::new(&config.backend_url)?;

    match client.health_check().await {
        Ok(health) => {
            println!(
                "  {} Backend API - {} ({})",
                "✓".green().bold(),
                "Healthy".green(),
                config.backend_url
            );
            if detailed {
                println!("    Version: {}", health.version.unwrap_or_default());
                println!("    Uptime: {}", health.uptime.unwrap_or_default());
                println!(
                    "    Database: {}",
                    if health.database { "Connected" } else { "Disconnected" }
                );
            }
        }
        Err(_) => {
            println!(
                "  {} Backend API - {}",
                "✗".red().bold(),
                "Unreachable".red()
            );
        }
    }

    // Check Moodle connection if configured
    if let Some(moodle_url) = &config.moodle_url {
        println!();
        println!("{}", "External Services:".bold());
        match client.check_moodle_connection().await {
            Ok(connected) => {
                if connected {
                    println!(
                        "  {} Moodle - {} ({})",
                        "✓".green().bold(),
                        "Connected".green(),
                        moodle_url
                    );
                } else {
                    println!(
                        "  {} Moodle - {}",
                        "✗".red().bold(),
                        "Not connected".yellow()
                    );
                }
            }
            Err(_) => {
                println!(
                    "  {} Moodle - {}",
                    "✗".red().bold(),
                    "Connection error".red()
                );
            }
        }
    }

    // Show statistics if detailed
    if detailed {
        println!();
        println!("{}", "Statistics:".bold());

        match client.get_statistics().await {
            Ok(stats) => {
                println!("  Total TMAs marked: {}", stats.total_marked);
                println!("  Pending reviews: {}", stats.pending_reviews);
                println!("  Average grade: {:.1}", stats.average_grade);
                println!("  Last sync: {}", stats.last_sync.unwrap_or("Never".to_string()));
            }
            Err(_) => {
                println!("  {}", "Unable to fetch statistics".yellow());
            }
        }
    }

    println!();
    println!("{}", "Configuration:".bold());
    println!("  Project: {}", config.project_name.cyan());
    println!("  Backend: {}", config.backend_url);
    if let Some(moodle) = &config.moodle_url {
        println!("  Moodle: {}", moodle);
    }
    println!("  Auto-sync: {}", if config.auto_sync { "Enabled" } else { "Disabled" });

    println!();
    println!("Run {} for detailed logs", "aws doctor".cyan());

    Ok(())
}
