use anyhow::Result;
use clap::{Parser, Subcommand};
use colored::*;
use std::process;

mod api_client;
mod commands;
mod config;
mod interactive;
mod models;
mod output;

use commands::*;

#[derive(Parser)]
#[command(name = "aws")]
#[command(author, version, about, long_about = None)]
#[command(propagate_version = true)]
struct Cli {
    #[command(subcommand)]
    command: Commands,

    /// Enable verbose output
    #[arg(short, long, global = true)]
    verbose: bool,

    /// Disable colored output
    #[arg(long, global = true)]
    no_color: bool,

    /// Path to configuration file
    #[arg(short, long, global = true)]
    config: Option<String>,

    /// Output format (text, json)
    #[arg(long, global = true, default_value = "text")]
    format: String,
}

#[derive(Subcommand)]
enum Commands {
    /// Initialize AWS in the current directory
    Init {
        /// Project name
        #[arg(short, long)]
        name: Option<String>,

        /// Skip interactive prompts
        #[arg(short, long)]
        yes: bool,
    },

    /// Start AWS services
    Start {
        /// Services to start (all if not specified)
        services: Vec<String>,

        /// Run in detached mode
        #[arg(short, long)]
        detach: bool,
    },

    /// Stop AWS services
    Stop {
        /// Services to stop (all if not specified)
        services: Vec<String>,

        /// Force stop
        #[arg(short, long)]
        force: bool,
    },

    /// Show service status
    Status {
        /// Show detailed status
        #[arg(short, long)]
        detailed: bool,
    },

    /// Mark a TMA (Tutor-Marked Assignment)
    Mark {
        /// TMA file path
        file: Option<String>,

        /// Student ID
        #[arg(short, long)]
        student: Option<String>,

        /// Assignment ID
        #[arg(short, long)]
        assignment: Option<String>,

        /// Interactive mode
        #[arg(short, long)]
        interactive: bool,
    },

    /// Batch mark multiple TMAs
    Batch {
        /// Directory containing TMAs
        directory: String,

        /// Pattern to match TMA files
        #[arg(short, long, default_value = "*.pdf")]
        pattern: String,

        /// Maximum concurrent marking jobs
        #[arg(short, long, default_value = "5")]
        concurrency: usize,
    },

    /// View or edit generated feedback
    Feedback {
        /// TMA ID or student ID
        id: String,

        /// Edit the feedback
        #[arg(short, long)]
        edit: bool,

        /// Export feedback to file
        #[arg(short, long)]
        output: Option<String>,
    },

    /// Manage configuration
    Config {
        #[command(subcommand)]
        action: ConfigAction,
    },

    /// Login to Moodle
    Login {
        /// Moodle username
        #[arg(short, long)]
        username: Option<String>,

        /// Moodle URL
        #[arg(short = 'u', long)]
        url: Option<String>,

        /// Save credentials
        #[arg(short, long)]
        save: bool,
    },

    /// Sync with Moodle
    Sync {
        /// Download new assignments
        #[arg(short, long)]
        download: bool,

        /// Upload marked assignments
        #[arg(short = 'u', long)]
        upload: bool,

        /// Dry run (show what would be synced)
        #[arg(short = 'n', long)]
        dry_run: bool,
    },

    /// Update AWS to the latest version
    Update {
        /// Update to specific version
        #[arg(short, long)]
        version: Option<String>,

        /// Check for updates without installing
        #[arg(short, long)]
        check: bool,
    },

    /// Diagnose and fix common issues
    Doctor {
        /// Fix issues automatically
        #[arg(short, long)]
        fix: bool,
    },
}

#[derive(Subcommand)]
enum ConfigAction {
    /// Show current configuration
    Show,

    /// Set a configuration value
    Set {
        /// Configuration key
        key: String,

        /// Configuration value
        value: String,
    },

    /// Get a configuration value
    Get {
        /// Configuration key
        key: String,
    },

    /// Reset configuration to defaults
    Reset {
        /// Skip confirmation
        #[arg(short, long)]
        yes: bool,
    },

    /// Edit configuration interactively
    Edit,
}

#[tokio::main]
async fn main() {
    let cli = Cli::parse();

    // Disable colors if requested
    if cli.no_color {
        colored::control::set_override(false);
    }

    // Set verbose mode
    if cli.verbose {
        std::env::set_var("RUST_LOG", "debug");
    }

    // Run the command
    let result = match cli.command {
        Commands::Init { name, yes } => init::run(name, yes).await,
        Commands::Start { services, detach } => start::run(services, detach).await,
        Commands::Stop { services, force } => stop::run(services, force).await,
        Commands::Status { detailed } => status::run(detailed).await,
        Commands::Mark {
            file,
            student,
            assignment,
            interactive,
        } => mark::run(file, student, assignment, interactive).await,
        Commands::Batch {
            directory,
            pattern,
            concurrency,
        } => batch::run(directory, pattern, concurrency).await,
        Commands::Feedback { id, edit, output } => feedback::run(id, edit, output).await,
        Commands::Config { action } => match action {
            ConfigAction::Show => config_cmd::show().await,
            ConfigAction::Set { key, value } => config_cmd::set(key, value).await,
            ConfigAction::Get { key } => config_cmd::get(key).await,
            ConfigAction::Reset { yes } => config_cmd::reset(yes).await,
            ConfigAction::Edit => config_cmd::edit().await,
        },
        Commands::Login {
            username,
            url,
            save,
        } => login::run(username, url, save).await,
        Commands::Sync {
            download,
            upload,
            dry_run,
        } => sync::run(download, upload, dry_run).await,
        Commands::Update { version, check } => update::run(version, check).await,
        Commands::Doctor { fix } => doctor::run(fix).await,
    };

    // Handle errors
    if let Err(e) = result {
        eprintln!("{} {}", "Error:".red().bold(), e);
        if cli.verbose {
            eprintln!("\n{}", "Backtrace:".yellow());
            eprintln!("{:?}", e);
        }
        process::exit(1);
    }
}
