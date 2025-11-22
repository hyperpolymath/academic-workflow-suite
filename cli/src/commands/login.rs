use anyhow::{Context, Result};
use colored::*;
use dialoguer::{Input, Password};
use serde::{Deserialize, Serialize};
use std::fs;

use crate::api_client::ApiClient;
use crate::config::Config;

#[derive(Serialize, Deserialize)]
struct Credentials {
    username: String,
    token: String,
    moodle_url: String,
}

pub async fn run(username: Option<String>, url: Option<String>, save: bool) -> Result<()> {
    let config = Config::load(".aws/config.yaml").context("Failed to load configuration")?;

    println!("{}", "Login to Moodle".cyan().bold());
    println!();

    // Get Moodle URL
    let moodle_url = if let Some(u) = url {
        u
    } else if let Some(u) = &config.moodle_url {
        u.clone()
    } else {
        Input::new()
            .with_prompt("Moodle URL")
            .interact_text()?
    };

    // Get username
    let user = if let Some(u) = username {
        u
    } else {
        Input::new()
            .with_prompt("Username")
            .interact_text()?
    };

    // Get password
    let password = Password::new()
        .with_prompt("Password")
        .interact()?;

    println!();
    println!("{}", "Authenticating...".yellow());

    // Authenticate
    let client = ApiClient::new(&config.backend_url)?;
    let auth_result = client.moodle_login(&moodle_url, &user, &password).await?;

    println!("{}", "✓ Authentication successful!".green().bold());
    println!();
    println!("User: {}", auth_result.username.cyan());
    println!("Name: {}", auth_result.full_name.unwrap_or_default());

    // Save credentials if requested
    if save {
        let credentials = Credentials {
            username: user,
            token: auth_result.token,
            moodle_url: moodle_url.clone(),
        };

        let credentials_json = serde_json::to_string_pretty(&credentials)?;
        fs::write(".aws/credentials.json", credentials_json)?;

        println!();
        println!("{}", "✓ Credentials saved".green().bold());
        println!("File: {}", ".aws/credentials.json".yellow());
        println!();
        println!(
            "{}",
            "Warning: Keep this file secure and do not commit to version control!".yellow()
        );

        // Update Moodle URL in config if not set
        if config.moodle_url.is_none() {
            let mut updated_config = config;
            updated_config.moodle_url = Some(moodle_url);
            updated_config.save(".aws/config.yaml")?;
        }
    }

    println!();
    println!("Next steps:");
    println!("  • Sync assignments: {}", "aws sync --download".cyan());
    println!("  • Upload feedback: {}", "aws sync --upload".cyan());

    Ok(())
}
