use anyhow::{Context, Result};
use colored::*;
use std::path::Path;
use std::process::Command;

use crate::api_client::ApiClient;
use crate::config::Config;

#[derive(Debug)]
struct DiagnosticResult {
    name: String,
    status: bool,
    message: String,
    fix_available: bool,
}

pub async fn run(auto_fix: bool) -> Result<()> {
    println!("{}", "AWS Diagnostics".cyan().bold());
    println!("{}", "─".repeat(50));
    println!();

    let mut results = Vec::new();
    let mut issues_found = 0;

    // Check 1: Configuration file exists
    println!("{}", "Checking configuration...".bold());
    let config_exists = Path::new(".aws/config.yaml").exists();
    results.push(DiagnosticResult {
        name: "Configuration file".to_string(),
        status: config_exists,
        message: if config_exists {
            "Configuration file found".to_string()
        } else {
            "Configuration file missing".to_string()
        },
        fix_available: !config_exists,
    });

    if !config_exists {
        issues_found += 1;
        println!(
            "  {} Configuration file missing",
            "✗".red().bold()
        );
        if auto_fix {
            println!("    Fixing: Running aws init...");
            // Would call init command here
        } else {
            println!("    Fix: Run {}", "aws init".cyan());
        }
    } else {
        println!("  {} Configuration file exists", "✓".green().bold());
    }

    // Check 2: Directory structure
    println!("{}", "Checking directory structure...".bold());
    let required_dirs = vec![".aws", ".aws/submissions", ".aws/feedback", ".aws/logs"];
    let mut all_dirs_exist = true;

    for dir in &required_dirs {
        if !Path::new(dir).exists() {
            all_dirs_exist = false;
            println!("  {} Missing directory: {}", "✗".red().bold(), dir);
            if auto_fix {
                println!("    Fixing: Creating directory...");
                std::fs::create_dir_all(dir)?;
                println!("    {} Created {}", "✓".green().bold(), dir);
            } else {
                println!("    Fix: Run {}", "aws init".cyan());
            }
            issues_found += 1;
        }
    }

    if all_dirs_exist {
        println!("  {} All directories exist", "✓".green().bold());
    }

    results.push(DiagnosticResult {
        name: "Directory structure".to_string(),
        status: all_dirs_exist,
        message: if all_dirs_exist {
            "All directories exist".to_string()
        } else {
            "Some directories missing".to_string()
        },
        fix_available: !all_dirs_exist,
    });

    // Check 3: Docker availability
    println!("{}", "Checking Docker...".bold());
    let docker_available = Command::new("docker")
        .arg("--version")
        .output()
        .is_ok();

    results.push(DiagnosticResult {
        name: "Docker".to_string(),
        status: docker_available,
        message: if docker_available {
            "Docker is available".to_string()
        } else {
            "Docker not found".to_string()
        },
        fix_available: false,
    });

    if docker_available {
        println!("  {} Docker is available", "✓".green().bold());
    } else {
        println!("  {} Docker not found", "✗".red().bold());
        println!("    Install Docker: https://docs.docker.com/get-docker/");
        issues_found += 1;
    }

    // Check 4: Docker Compose availability
    println!("{}", "Checking Docker Compose...".bold());
    let compose_available = Command::new("docker-compose")
        .arg("--version")
        .output()
        .is_ok();

    results.push(DiagnosticResult {
        name: "Docker Compose".to_string(),
        status: compose_available,
        message: if compose_available {
            "Docker Compose is available".to_string()
        } else {
            "Docker Compose not found".to_string()
        },
        fix_available: false,
    });

    if compose_available {
        println!("  {} Docker Compose is available", "✓".green().bold());
    } else {
        println!("  {} Docker Compose not found", "✗".red().bold());
        println!("    Install Docker Compose: https://docs.docker.com/compose/install/");
        issues_found += 1;
    }

    // Check 5: Backend connectivity
    if config_exists {
        println!("{}", "Checking backend connectivity...".bold());
        let config = Config::load(".aws/config.yaml").context("Failed to load configuration")?;
        let client = ApiClient::new(&config.backend_url)?;

        match client.health_check().await {
            Ok(_) => {
                println!("  {} Backend is reachable", "✓".green().bold());
                results.push(DiagnosticResult {
                    name: "Backend connectivity".to_string(),
                    status: true,
                    message: "Backend is healthy".to_string(),
                    fix_available: false,
                });
            }
            Err(e) => {
                println!("  {} Backend is unreachable", "✗".red().bold());
                println!("    Error: {}", e);
                println!("    Fix: Run {}", "aws start".cyan());
                issues_found += 1;
                results.push(DiagnosticResult {
                    name: "Backend connectivity".to_string(),
                    status: false,
                    message: format!("Backend unreachable: {}", e),
                    fix_available: true,
                });
            }
        }

        // Check 6: Moodle connectivity (if configured)
        if config.moodle_url.is_some() {
            println!("{}", "Checking Moodle connectivity...".bold());
            if Path::new(".aws/credentials.json").exists() {
                match client.check_moodle_connection().await {
                    Ok(connected) => {
                        if connected {
                            println!("  {} Moodle is connected", "✓".green().bold());
                        } else {
                            println!("  {} Moodle not connected", "✗".red().bold());
                            println!("    Fix: Run {}", "aws login".cyan());
                            issues_found += 1;
                        }
                    }
                    Err(e) => {
                        println!("  {} Moodle connection error", "✗".red().bold());
                        println!("    Error: {}", e);
                        issues_found += 1;
                    }
                }
            } else {
                println!("  {} Not logged in to Moodle", "✗".red().bold());
                println!("    Fix: Run {}", "aws login".cyan());
                issues_found += 1;
            }
        }
    }

    // Summary
    println!();
    println!("{}", "Diagnostic Summary".bold());
    println!("{}", "─".repeat(50));

    let total_checks = results.len();
    let passed_checks = results.iter().filter(|r| r.status).count();

    println!();
    println!("Total checks: {}", total_checks);
    println!("{} Passed: {}", "✓".green().bold(), passed_checks);
    if issues_found > 0 {
        println!("{} Issues: {}", "✗".red().bold(), issues_found);
    }

    println!();
    if issues_found == 0 {
        println!("{}", "✓ All systems operational!".green().bold());
    } else {
        println!(
            "{}",
            format!("Found {} issue(s) that need attention", issues_found)
                .yellow()
                .bold()
        );
        if !auto_fix {
            println!();
            println!("Run {} to automatically fix issues", "aws doctor --fix".cyan());
        }
    }

    Ok(())
}
