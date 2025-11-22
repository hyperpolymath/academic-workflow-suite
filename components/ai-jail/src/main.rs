//! AI Jail - Network-isolated AI inference container
//!
//! This binary provides a secure, isolated environment for running AI inference
//! on academic TMA submissions. It communicates solely via stdin/stdout and has
//! no network access.
//!
//! # Architecture
//!
//! - Reads JSON requests from stdin
//! - Loads Mistral 7B model from local storage
//! - Generates feedback using Candle ML framework
//! - Writes JSON responses to stdout
//! - Runs in Podman container with network disabled
//!
//! # Usage
//!
//! ```bash
//! echo '{"tma_content":"...","rubric":"...","question_number":1}' | ai-jail
//! ```

use anyhow::{Context, Result};
use std::io::{self, BufRead, Write};
use tracing_subscriber::EnvFilter;

mod inference;
mod model;
mod protocol;

use inference::InferenceEngine;
use model::{LoadedModel, ModelConfig};
use protocol::{ErrorResponse, InferenceRequest, Response};

/// Main entry point
fn main() {
    // Initialize logging
    if let Err(e) = init_logging() {
        eprintln!("Failed to initialize logging: {}", e);
        std::process::exit(1);
    }

    tracing::info!("AI Jail starting...");

    // Run the main loop
    if let Err(e) = run() {
        let error_response = Response::Error(ErrorResponse {
            error_type: "initialization_error".to_string(),
            message: e.to_string(),
            details: Some(format!("{:?}", e)),
        });

        if let Err(e) = write_response(&error_response) {
            eprintln!("Failed to write error response: {}", e);
        }

        std::process::exit(1);
    }

    tracing::info!("AI Jail shutting down");
}

/// Initialize tracing/logging
fn init_logging() -> Result<()> {
    let filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new("info"));

    tracing_subscriber::fmt()
        .with_env_filter(filter)
        .with_writer(io::stderr) // Write logs to stderr, keep stdout for IPC
        .with_target(false)
        .with_thread_ids(false)
        .with_file(true)
        .with_line_number(true)
        .init();

    Ok(())
}

/// Main execution loop
fn run() -> Result<()> {
    // Load model configuration
    tracing::info!("Loading model configuration...");
    let config = ModelConfig::from_env()
        .context("Failed to load model configuration")?;

    // Validate model files exist
    validate_model_files(&config)?;

    // Load model
    tracing::info!("Loading model (this may take a few minutes)...");
    let model = LoadedModel::load(config)
        .context("Failed to load model")?;

    let memory_usage = model.estimate_memory_usage();
    tracing::info!(
        "Model loaded. Estimated memory usage: {:.2} GB",
        memory_usage as f64 / 1_073_741_824.0
    );

    // Create inference engine
    let mut engine = InferenceEngine::new(model);

    // Process requests from stdin
    tracing::info!("Ready to process requests");
    process_requests(&mut engine)?;

    Ok(())
}

/// Validate that required model files exist
fn validate_model_files(config: &ModelConfig) -> Result<()> {
    if !config.model_path.exists() {
        anyhow::bail!(
            "Model file not found: {}",
            config.model_path.display()
        );
    }

    if !config.tokenizer_path.exists() {
        anyhow::bail!(
            "Tokenizer file not found: {}",
            config.tokenizer_path.display()
        );
    }

    tracing::info!("Model files validated");
    Ok(())
}

/// Process inference requests from stdin
fn process_requests(engine: &mut InferenceEngine) -> Result<()> {
    let stdin = io::stdin();
    let mut reader = stdin.lock();
    let mut line = String::new();

    loop {
        line.clear();

        // Read line from stdin
        match reader.read_line(&mut line) {
            Ok(0) => {
                // EOF reached
                tracing::info!("EOF reached, shutting down");
                break;
            }
            Ok(_) => {
                // Process the request
                if let Err(e) = process_single_request(engine, &line) {
                    tracing::error!("Error processing request: {}", e);

                    let error_response = Response::Error(ErrorResponse {
                        error_type: "processing_error".to_string(),
                        message: e.to_string(),
                        details: Some(format!("{:?}", e)),
                    });

                    write_response(&error_response)?;
                }
            }
            Err(e) => {
                tracing::error!("Error reading from stdin: {}", e);
                break;
            }
        }
    }

    Ok(())
}

/// Process a single inference request
fn process_single_request(engine: &mut InferenceEngine, line: &str) -> Result<()> {
    let line = line.trim();

    // Skip empty lines
    if line.is_empty() {
        return Ok(());
    }

    tracing::info!("Processing request");

    // Parse request
    let request: InferenceRequest = serde_json::from_str(line)
        .context("Failed to parse JSON request")?;

    tracing::debug!("Request: question {}", request.question_number);

    // Generate feedback
    let response = engine.generate(&request)
        .context("Inference failed")?;

    // Write response
    let success_response = Response::Success(response);
    write_response(&success_response)?;

    Ok(())
}

/// Write a response to stdout
fn write_response(response: &Response) -> Result<()> {
    let json = serde_json::to_string(response)
        .context("Failed to serialize response")?;

    // Write to stdout with newline
    let mut stdout = io::stdout();
    writeln!(stdout, "{}", json)
        .context("Failed to write to stdout")?;

    stdout.flush()
        .context("Failed to flush stdout")?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_init_logging() {
        // This should not panic
        assert!(init_logging().is_ok());
    }

    #[test]
    fn test_validate_model_files_missing() {
        let config = ModelConfig {
            model_path: "/nonexistent/model.safetensors".into(),
            tokenizer_path: "/nonexistent/tokenizer.json".into(),
            quantization: model::QuantizationMode::Q4,
            device: candle_core::Device::Cpu,
            use_flash_attn: false,
        };

        assert!(validate_model_files(&config).is_err());
    }
}
