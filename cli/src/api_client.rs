use anyhow::Result;
use reqwest::{Client, ClientBuilder};
use serde::{Deserialize, Serialize};
use std::time::Duration;

use crate::models::*;

#[derive(Clone)]
pub struct ApiClient {
    client: Client,
    base_url: String,
}

#[derive(Serialize, Deserialize)]
pub struct HealthResponse {
    pub status: String,
    pub version: Option<String>,
    pub uptime: Option<String>,
    pub database: bool,
}

#[derive(Serialize, Deserialize)]
pub struct UploadResponse {
    pub id: String,
    pub status: String,
    pub message: String,
}

#[derive(Serialize, Deserialize)]
pub struct MarkingResponse {
    pub id: String,
    pub grade: u32,
    pub feedback: Option<String>,
    pub student_id: Option<String>,
    pub assignment_id: Option<String>,
}

#[derive(Serialize, Deserialize)]
pub struct AuthResponse {
    pub token: String,
    pub username: String,
    pub full_name: Option<String>,
}

#[derive(Serialize, Deserialize)]
pub struct Statistics {
    pub total_marked: u32,
    pub pending_reviews: u32,
    pub average_grade: f32,
    pub last_sync: Option<String>,
}

#[derive(Serialize, Deserialize)]
pub struct Assignment {
    pub id: String,
    pub name: String,
    pub due_date: Option<String>,
    pub submissions: Vec<Submission>,
}

#[derive(Serialize, Deserialize)]
pub struct Submission {
    pub student_id: String,
    pub url: String,
}

impl ApiClient {
    pub fn new(base_url: &str) -> Result<Self> {
        let client = ClientBuilder::new()
            .timeout(Duration::from_secs(30))
            .cookie_store(true)
            .build()?;

        Ok(Self {
            client,
            base_url: base_url.trim_end_matches('/').to_string(),
        })
    }

    pub async fn health_check(&self) -> Result<HealthResponse> {
        let url = format!("{}/api/health", self.base_url);
        let response = self.client.get(&url).send().await?;

        if !response.status().is_success() {
            return Err(anyhow::anyhow!("Health check failed"));
        }

        let health = response.json::<HealthResponse>().await?;
        Ok(health)
    }

    pub async fn upload_tma(&self, submission: &TmaSubmission) -> Result<UploadResponse> {
        let url = format!("{}/api/tma/upload", self.base_url);

        // In a real implementation, this would use multipart form data
        let form = reqwest::multipart::Form::new()
            .text("student_id", submission.student_id.clone().unwrap_or_default())
            .text(
                "assignment_id",
                submission.assignment_id.clone().unwrap_or_default(),
            );

        // Add file if it exists
        let form = if std::path::Path::new(&submission.file_path).exists() {
            let file_content = std::fs::read(&submission.file_path)?;
            let file_name = std::path::Path::new(&submission.file_path)
                .file_name()
                .unwrap()
                .to_string_lossy()
                .to_string();
            form.part(
                "file",
                reqwest::multipart::Part::bytes(file_content).file_name(file_name),
            )
        } else {
            form
        };

        let response = self.client.post(&url).multipart(form).send().await?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            return Err(anyhow::anyhow!("Upload failed: {}", error_text));
        }

        let result = response.json::<UploadResponse>().await?;
        Ok(result)
    }

    pub async fn mark_tma(&self, tma_id: &str) -> Result<MarkingResponse> {
        let url = format!("{}/api/tma/{}/mark", self.base_url, tma_id);
        let response = self.client.post(&url).send().await?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            return Err(anyhow::anyhow!("Marking failed: {}", error_text));
        }

        let result = response.json::<MarkingResponse>().await?;
        Ok(result)
    }

    pub async fn get_feedback(&self, tma_id: &str) -> Result<Feedback> {
        let url = format!("{}/api/tma/{}/feedback", self.base_url, tma_id);
        let response = self.client.get(&url).send().await?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            return Err(anyhow::anyhow!("Failed to get feedback: {}", error_text));
        }

        let feedback = response.json::<Feedback>().await?;
        Ok(feedback)
    }

    pub async fn update_feedback(&self, tma_id: &str, content: &str) -> Result<()> {
        let url = format!("{}/api/tma/{}/feedback", self.base_url, tma_id);

        #[derive(Serialize)]
        struct UpdateRequest {
            content: String,
        }

        let response = self
            .client
            .put(&url)
            .json(&UpdateRequest {
                content: content.to_string(),
            })
            .send()
            .await?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            return Err(anyhow::anyhow!("Failed to update feedback: {}", error_text));
        }

        Ok(())
    }

    pub async fn check_moodle_connection(&self) -> Result<bool> {
        let url = format!("{}/api/moodle/status", self.base_url);
        let response = self.client.get(&url).send().await?;

        if !response.status().is_success() {
            return Ok(false);
        }

        #[derive(Deserialize)]
        struct MoodleStatus {
            connected: bool,
        }

        let status = response.json::<MoodleStatus>().await?;
        Ok(status.connected)
    }

    pub async fn get_statistics(&self) -> Result<Statistics> {
        let url = format!("{}/api/statistics", self.base_url);
        let response = self.client.get(&url).send().await?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            return Err(anyhow::anyhow!("Failed to get statistics: {}", error_text));
        }

        let stats = response.json::<Statistics>().await?;
        Ok(stats)
    }

    pub async fn moodle_login(
        &self,
        moodle_url: &str,
        username: &str,
        password: &str,
    ) -> Result<AuthResponse> {
        let url = format!("{}/api/moodle/login", self.base_url);

        #[derive(Serialize)]
        struct LoginRequest {
            moodle_url: String,
            username: String,
            password: String,
        }

        let response = self
            .client
            .post(&url)
            .json(&LoginRequest {
                moodle_url: moodle_url.to_string(),
                username: username.to_string(),
                password: password.to_string(),
            })
            .send()
            .await?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            return Err(anyhow::anyhow!("Login failed: {}", error_text));
        }

        let auth = response.json::<AuthResponse>().await?;
        Ok(auth)
    }

    pub async fn get_moodle_assignments(
        &self,
        moodle_url: &str,
        token: &str,
    ) -> Result<Vec<Assignment>> {
        let url = format!("{}/api/moodle/assignments", self.base_url);

        #[derive(Serialize)]
        struct AssignmentsRequest {
            moodle_url: String,
            token: String,
        }

        let response = self
            .client
            .post(&url)
            .json(&AssignmentsRequest {
                moodle_url: moodle_url.to_string(),
                token: token.to_string(),
            })
            .send()
            .await?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            return Err(anyhow::anyhow!(
                "Failed to get assignments: {}",
                error_text
            ));
        }

        let assignments = response.json::<Vec<Assignment>>().await?;
        Ok(assignments)
    }

    pub async fn download_submission(&self, url: &str, output_path: &str) -> Result<()> {
        let response = self.client.get(url).send().await?;

        if !response.status().is_success() {
            return Err(anyhow::anyhow!("Failed to download submission"));
        }

        let content = response.bytes().await?;
        std::fs::write(output_path, content)?;

        Ok(())
    }

    pub async fn upload_moodle_feedback(
        &self,
        moodle_url: &str,
        token: &str,
        assignment_id: &str,
        feedback: &str,
    ) -> Result<()> {
        let url = format!("{}/api/moodle/feedback", self.base_url);

        #[derive(Serialize)]
        struct FeedbackRequest {
            moodle_url: String,
            token: String,
            assignment_id: String,
            feedback: String,
        }

        let response = self
            .client
            .post(&url)
            .json(&FeedbackRequest {
                moodle_url: moodle_url.to_string(),
                token: token.to_string(),
                assignment_id: assignment_id.to_string(),
                feedback: feedback.to_string(),
            })
            .send()
            .await?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            return Err(anyhow::anyhow!("Failed to upload feedback: {}", error_text));
        }

        Ok(())
    }
}
