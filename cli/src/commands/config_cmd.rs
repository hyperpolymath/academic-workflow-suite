use anyhow::{Context, Result};
use colored::*;
use dialoguer::{Confirm, Input};

use crate::config::Config;

pub async fn show() -> Result<()> {
    let config = Config::load(".aws/config.yaml").context("Failed to load configuration")?;

    println!("{}", "AWS Configuration".cyan().bold());
    println!();

    println!("{}", "Project Settings:".bold());
    println!("  project_name: {}", config.project_name.cyan());
    println!("  backend_url: {}", config.backend_url);

    if let Some(moodle_url) = &config.moodle_url {
        println!("  moodle_url: {}", moodle_url);
    }

    println!();
    println!("{}", "Features:".bold());
    println!("  auto_sync: {}", if config.auto_sync { "enabled" } else { "disabled" });
    println!(
        "  ai_model: {}",
        config.ai_model.as_ref().unwrap_or(&"default".to_string())
    );

    if let Some(marking_rubric) = &config.marking_rubric {
        println!("  marking_rubric: {}", marking_rubric);
    }

    println!();
    println!("Configuration file: {}", ".aws/config.yaml".yellow());
    println!();
    println!("Edit: {}", "aws config edit".cyan());

    Ok(())
}

pub async fn set(key: String, value: String) -> Result<()> {
    let mut config = Config::load(".aws/config.yaml").context("Failed to load configuration")?;

    match key.as_str() {
        "project_name" => config.project_name = value.clone(),
        "backend_url" => config.backend_url = value.clone(),
        "moodle_url" => config.moodle_url = Some(value.clone()),
        "auto_sync" => {
            config.auto_sync = value.parse::<bool>().context("Invalid boolean value")?
        }
        "ai_model" => config.ai_model = Some(value.clone()),
        "marking_rubric" => config.marking_rubric = Some(value.clone()),
        _ => {
            return Err(anyhow::anyhow!("Unknown configuration key: {}", key));
        }
    }

    config
        .save(".aws/config.yaml")
        .context("Failed to save configuration")?;

    println!("{} Configuration updated", "✓".green().bold());
    println!("  {} = {}", key.cyan(), value);

    Ok(())
}

pub async fn get(key: String) -> Result<()> {
    let config = Config::load(".aws/config.yaml").context("Failed to load configuration")?;

    let value = match key.as_str() {
        "project_name" => Some(config.project_name),
        "backend_url" => Some(config.backend_url),
        "moodle_url" => config.moodle_url,
        "auto_sync" => Some(config.auto_sync.to_string()),
        "ai_model" => config.ai_model,
        "marking_rubric" => config.marking_rubric,
        _ => {
            return Err(anyhow::anyhow!("Unknown configuration key: {}", key));
        }
    };

    if let Some(v) = value {
        println!("{}", v);
    } else {
        println!("{}", "(not set)".yellow());
    }

    Ok(())
}

pub async fn reset(skip_confirm: bool) -> Result<()> {
    if !skip_confirm {
        let confirm = Confirm::new()
            .with_prompt("Reset configuration to defaults? This cannot be undone.")
            .default(false)
            .interact()?;

        if !confirm {
            println!("{}", "Cancelled.".yellow());
            return Ok(());
        }
    }

    let config = Config::default();
    config
        .save(".aws/config.yaml")
        .context("Failed to save configuration")?;

    println!("{}", "✓ Configuration reset to defaults".green().bold());
    println!();
    println!("Run {} to configure interactively", "aws config edit".cyan());

    Ok(())
}

pub async fn edit() -> Result<()> {
    let mut config = Config::load(".aws/config.yaml").context("Failed to load configuration")?;

    println!("{}", "Interactive Configuration".cyan().bold());
    println!();

    // Project name
    let project_name = Input::new()
        .with_prompt("Project name")
        .default(config.project_name.clone())
        .interact_text()?;
    config.project_name = project_name;

    // Backend URL
    let backend_url = Input::new()
        .with_prompt("Backend API URL")
        .default(config.backend_url.clone())
        .interact_text()?;
    config.backend_url = backend_url;

    // Moodle URL
    let moodle_url = Input::new()
        .with_prompt("Moodle URL (optional)")
        .default(config.moodle_url.clone().unwrap_or_default())
        .allow_empty(true)
        .interact_text()?;
    if !moodle_url.is_empty() {
        config.moodle_url = Some(moodle_url);
    }

    // Auto sync
    let auto_sync = Confirm::new()
        .with_prompt("Enable automatic Moodle sync?")
        .default(config.auto_sync)
        .interact()?;
    config.auto_sync = auto_sync;

    // AI model
    let ai_model = Input::new()
        .with_prompt("AI model (optional)")
        .default(config.ai_model.clone().unwrap_or_default())
        .allow_empty(true)
        .interact_text()?;
    if !ai_model.is_empty() {
        config.ai_model = Some(ai_model);
    }

    // Save configuration
    config
        .save(".aws/config.yaml")
        .context("Failed to save configuration")?;

    println!();
    println!("{}", "✓ Configuration saved".green().bold());
    println!();
    println!("View configuration: {}", "aws config show".cyan());

    Ok(())
}
