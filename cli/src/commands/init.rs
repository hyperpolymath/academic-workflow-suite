use anyhow::{Context, Result};
use colored::*;
use dialoguer::{Confirm, Input};
use std::fs;
use std::path::Path;

use crate::config::Config;
use crate::output;

pub async fn run(name: Option<String>, skip_prompts: bool) -> Result<()> {
    println!("{}", "Initializing Academic Workflow Suite...".cyan().bold());

    // Check if already initialized
    if Path::new(".aws").exists() {
        if !skip_prompts {
            let overwrite = Confirm::new()
                .with_prompt("AWS is already initialized. Overwrite?")
                .default(false)
                .interact()?;

            if !overwrite {
                println!("{}", "Initialization cancelled.".yellow());
                return Ok(());
            }
        }
    }

    // Get project name
    let project_name = if let Some(n) = name {
        n
    } else if skip_prompts {
        std::env::current_dir()?
            .file_name()
            .unwrap()
            .to_string_lossy()
            .to_string()
    } else {
        Input::new()
            .with_prompt("Project name")
            .default(
                std::env::current_dir()?
                    .file_name()
                    .unwrap()
                    .to_string_lossy()
                    .to_string(),
            )
            .interact_text()?
    };

    // Create directory structure
    println!("{}", "Creating directory structure...".green());
    fs::create_dir_all(".aws")?;
    fs::create_dir_all(".aws/submissions")?;
    fs::create_dir_all(".aws/feedback")?;
    fs::create_dir_all(".aws/logs")?;

    // Create default configuration
    let mut config = Config::default();
    config.project_name = project_name.clone();

    if !skip_prompts {
        // Interactive configuration
        let backend_url = Input::new()
            .with_prompt("Backend API URL")
            .default("http://localhost:8000".to_string())
            .interact_text()?;
        config.backend_url = backend_url;

        let moodle_url = Input::new()
            .with_prompt("Moodle URL (optional)")
            .allow_empty(true)
            .interact_text()?;
        if !moodle_url.is_empty() {
            config.moodle_url = Some(moodle_url);
        }

        let auto_sync = Confirm::new()
            .with_prompt("Enable automatic Moodle sync?")
            .default(false)
            .interact()?;
        config.auto_sync = auto_sync;
    }

    // Save configuration
    config
        .save(".aws/config.yaml")
        .context("Failed to save configuration")?;

    // Create .gitignore
    let gitignore_content = r#"# AWS CLI files
.aws/submissions/
.aws/feedback/
.aws/logs/
.aws/credentials.json
.aws/*.log
"#;
    fs::write(".aws/.gitignore", gitignore_content)?;

    // Create README
    let readme_content = format!(
        r#"# {}

This directory has been initialized with Academic Workflow Suite.

## Directory Structure

- `.aws/` - AWS configuration and data
  - `config.yaml` - Project configuration
  - `submissions/` - Downloaded TMA submissions
  - `feedback/` - Generated feedback files
  - `logs/` - Application logs

## Quick Start

1. Start services:
   ```
   aws start
   ```

2. Check status:
   ```
   aws status
   ```

3. Mark a TMA:
   ```
   aws mark --interactive
   ```

4. View feedback:
   ```
   aws feedback <student-id>
   ```

For more information, run `aws --help`.
"#,
        project_name
    );
    fs::write("AWS_README.md", readme_content)?;

    println!();
    println!("{}", "✓ Initialization complete!".green().bold());
    println!();
    println!("Project: {}", project_name.cyan());
    println!("Configuration: {}", ".aws/config.yaml".yellow());
    println!();
    println!("Next steps:");
    println!("  1. Review configuration: {}", "aws config show".cyan());
    println!("  2. Start services: {}", "aws start".cyan());
    println!("  3. Check status: {}", "aws status".cyan());

    Ok(())
}
