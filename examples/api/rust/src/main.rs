use anyhow::{Context, Result};
use clap::Parser;
use colored::*;
use reqwest::multipart;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::time::Duration;

/// Academic Workflow API Rust Client
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Path to TMA PDF file
    #[arg(short, long)]
    file: PathBuf,

    /// Student ID
    #[arg(short, long, default_value = "student001")]
    student_id: String,

    /// Rubric to use
    #[arg(short, long, default_value = "default")]
    rubric: String,

    /// API base URL
    #[arg(short, long, default_value = "http://localhost:8080")]
    api_url: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct UploadResponse {
    tma_id: String,
    message: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct MarkRequest {
    rubric: String,
    auto_feedback: bool,
}

#[derive(Debug, Serialize, Deserialize)]
struct MarkResponse {
    job_id: String,
    status: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct JobStatus {
    job_id: String,
    status: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
struct Feedback {
    summary: String,
    strengths: Vec<String>,
    areas_for_improvement: Vec<String>,
    detailed_comments: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
struct MarkingResult {
    tma_id: String,
    student_id: String,
    score: f64,
    grade: String,
    feedback: Feedback,
    marked_at: String,
}

/// Academic Workflow API Client
struct AwapClient {
    client: reqwest::Client,
    base_url: String,
}

impl AwapClient {
    fn new(base_url: String) -> Self {
        let client = reqwest::Client::builder()
            .timeout(Duration::from_secs(300))
            .build()
            .unwrap();

        Self { client, base_url }
    }

    /// Upload a TMA file
    async fn upload_tma(
        &self,
        file_path: &PathBuf,
        student_id: &str,
        rubric: &str,
    ) -> Result<String> {
        println!("{} Uploading TMA...", "Step 1:".green().bold());

        let file_name = file_path
            .file_name()
            .context("Invalid file path")?
            .to_string_lossy()
            .to_string();

        let file_content = tokio::fs::read(file_path)
            .await
            .context("Failed to read TMA file")?;

        let file_part = multipart::Part::bytes(file_content)
            .file_name(file_name)
            .mime_str("application/pdf")?;

        let form = multipart::Form::new()
            .part("file", file_part)
            .text("student_id", student_id.to_string())
            .text("rubric", rubric.to_string());

        let url = format!("{}/api/v1/tma/upload", self.base_url);

        let response = self
            .client
            .post(&url)
            .multipart(form)
            .send()
            .await
            .context("Upload request failed")?;

        if !response.status().is_success() {
            anyhow::bail!("Upload failed with status: {}", response.status());
        }

        let upload_result: UploadResponse = response.json().await?;

        println!("  {} TMA uploaded successfully", "✓".green());
        println!("  TMA ID: {}", upload_result.tma_id.cyan());

        Ok(upload_result.tma_id)
    }

    /// Submit TMA for marking
    async fn submit_for_marking(&self, tma_id: &str, rubric: &str) -> Result<String> {
        println!("\n{} Submitting for marking...", "Step 2:".green().bold());

        let url = format!("{}/api/v1/tma/{}/mark", self.base_url, tma_id);

        let request = MarkRequest {
            rubric: rubric.to_string(),
            auto_feedback: true,
        };

        let response = self
            .client
            .post(&url)
            .json(&request)
            .send()
            .await
            .context("Marking request failed")?;

        if !response.status().is_success() {
            anyhow::bail!("Marking submission failed: {}", response.status());
        }

        let mark_result: MarkResponse = response.json().await?;

        println!("  {} Marking job submitted", "✓".green());
        println!("  Job ID: {}", mark_result.job_id.cyan());

        Ok(mark_result.job_id)
    }

    /// Wait for marking to complete
    async fn wait_for_results(&self, job_id: &str, tma_id: &str) -> Result<MarkingResult> {
        println!("\n{} Waiting for results...", "Step 3:".green().bold());

        let timeout = Duration::from_secs(300);
        let start = std::time::Instant::now();

        loop {
            if start.elapsed() > timeout {
                anyhow::bail!("Timeout: Marking took too long");
            }

            let url = format!("{}/api/v1/jobs/{}", self.base_url, job_id);
            let response = self.client.get(&url).send().await?;

            if !response.status().is_success() {
                anyhow::bail!("Status check failed: {}", response.status());
            }

            let status: JobStatus = response.json().await?;

            match status.status.as_str() {
                "completed" => {
                    println!("  {} Marking completed!\n", "✓".green());

                    // Get detailed results
                    let results_url = format!("{}/api/v1/tma/{}/results", self.base_url, tma_id);
                    let results_response = self.client.get(&results_url).send().await?;

                    if !results_response.status().is_success() {
                        anyhow::bail!("Failed to retrieve results: {}", results_response.status());
                    }

                    let results: MarkingResult = results_response.json().await?;
                    return Ok(results);
                }
                "failed" => {
                    let error = status.error.unwrap_or_else(|| "Unknown error".to_string());
                    anyhow::bail!("Marking failed: {}", error);
                }
                _ => {
                    print!(".");
                    use std::io::Write;
                    std::io::stdout().flush()?;
                    tokio::time::sleep(Duration::from_secs(5)).await;
                }
            }
        }
    }
}

fn display_results(results: &MarkingResult) {
    println!("{}", "Results:".blue().bold());
    println!("{}", "=".repeat(50));

    println!("\n{}: {}", "Score".bold(), results.score);
    println!("{}: {}", "Grade".bold(), results.grade.green().bold());

    println!("\n{}", "Feedback Summary:".blue().bold());
    println!("{}", results.feedback.summary);

    println!("\n{}", "Strengths:".green().bold());
    for strength in &results.feedback.strengths {
        println!("  • {}", strength);
    }

    println!("\n{}", "Areas for Improvement:".yellow().bold());
    for area in &results.feedback.areas_for_improvement {
        println!("  • {}", area);
    }

    println!("\n{}", "Detailed Comments:".blue().bold());
    for comment in &results.feedback.detailed_comments {
        println!("  • {}", comment);
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    // Validate file exists
    if !args.file.exists() {
        anyhow::bail!("TMA file not found: {}", args.file.display());
    }

    println!("{}", "Academic Workflow Suite - Rust Client".blue().bold());
    println!("{}\n", "======================================".blue());

    // Create client
    let client = AwapClient::new(args.api_url);

    // Step 1: Upload TMA
    let tma_id = client
        .upload_tma(&args.file, &args.student_id, &args.rubric)
        .await?;

    // Step 2: Submit for marking
    let job_id = client.submit_for_marking(&tma_id, &args.rubric).await?;

    // Step 3: Wait for results
    let results = client.wait_for_results(&job_id, &tma_id).await?;

    // Display results
    display_results(&results);

    // Save results to file
    let output_file = args.file.with_extension("feedback.json");
    let json = serde_json::to_string_pretty(&results)?;
    tokio::fs::write(&output_file, json).await?;

    println!("\n{} {}", "Full feedback saved to:".green(), output_file.display());

    Ok(())
}
