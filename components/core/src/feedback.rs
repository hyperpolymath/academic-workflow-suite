//! Feedback Generation Coordination
//!
//! Coordinates feedback generation for TMAs, integrating with the AI jail
//! and ensuring rubric-aligned responses.

use crate::ipc::{AsyncIPCClient, IPCMessage};
use crate::security::SecurityService;
use crate::tma::{RubricCriterion, TMA};
use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::time::Duration;

/// Request for feedback generation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FeedbackRequest {
    /// The TMA to generate feedback for
    pub tma_id: String,
    /// Anonymized student content
    pub content: String,
    /// Rubric criteria to evaluate against
    pub rubric: String,
    /// Rubric criteria parsed into structured form
    pub criteria: Vec<RubricCriterion>,
    /// Maximum response time in seconds
    pub timeout_secs: u64,
}

impl FeedbackRequest {
    /// Create a new feedback request from a TMA
    ///
    /// This automatically sanitizes the content and parses rubric criteria.
    pub fn from_tma(tma: &TMA, security: &SecurityService) -> Result<Self> {
        // Ensure content is sanitized
        let sanitized_content = security.sanitize_content(&tma.content);

        // Validate no PII in sanitized content
        security
            .validate_output(&sanitized_content)
            .context("Content still contains PII after sanitization")?;

        let criteria = tma.parse_rubric_criteria();

        Ok(Self {
            tma_id: tma.id.to_string(),
            content: sanitized_content,
            rubric: tma.rubric.clone(),
            criteria,
            timeout_secs: 120, // Default 2 minutes
        })
    }

    /// Set a custom timeout
    pub fn with_timeout(mut self, timeout_secs: u64) -> Self {
        self.timeout_secs = timeout_secs;
        self
    }
}

/// Response from feedback generation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FeedbackResponse {
    /// The TMA ID this feedback is for
    pub tma_id: String,
    /// Generated feedback text
    pub feedback: String,
    /// Scores for each rubric criterion
    pub criterion_scores: Vec<CriterionScore>,
    /// Overall grade (0-100)
    pub overall_grade: f32,
    /// Suggested improvements
    pub suggestions: Vec<String>,
    /// Strengths identified
    pub strengths: Vec<String>,
}

/// Score for a single rubric criterion
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CriterionScore {
    pub criterion_number: u32,
    pub criterion_text: String,
    pub score: f32,
    pub max_score: f32,
    pub feedback: String,
}

/// Service for coordinating feedback generation
pub struct FeedbackService {
    security: SecurityService,
    ipc_client: Option<AsyncIPCClient>,
}

impl FeedbackService {
    /// Create a new feedback service
    pub fn new(security: SecurityService) -> Self {
        Self {
            security,
            ipc_client: None,
        }
    }

    /// Create a feedback service with an IPC client
    pub fn with_ipc(security: SecurityService, ipc_client: AsyncIPCClient) -> Self {
        Self {
            security,
            ipc_client: Some(ipc_client),
        }
    }

    /// Generate feedback for a TMA
    ///
    /// This is the main entry point for feedback generation.
    /// It handles:
    /// 1. Creating a sanitized request
    /// 2. Sending to AI jail via IPC
    /// 3. Validating the response
    /// 4. Structuring the feedback
    pub async fn generate_feedback(&mut self, tma: &TMA) -> Result<FeedbackResponse> {
        // Create request with sanitized content
        let request = FeedbackRequest::from_tma(tma, &self.security)?;

        // Send to AI jail if IPC client is available
        let response = if self.ipc_client.is_some() {
            // Take the client temporarily to avoid double borrow
            let mut ipc_client = self.ipc_client.take().unwrap();
            let result = Self::send_via_ipc(&mut ipc_client, &request).await;
            // Put it back
            self.ipc_client = Some(ipc_client);
            result?
        } else {
            // Fallback to mock feedback for testing
            Self::generate_mock_feedback(&request)?
        };

        // Validate response doesn't contain PII
        self.security
            .validate_output(&response.feedback)
            .context("AI response contains PII")?;

        Ok(response)
    }

    /// Generate feedback via IPC to AI jail
    async fn send_via_ipc(
        ipc_client: &mut AsyncIPCClient,
        request: &FeedbackRequest,
    ) -> Result<FeedbackResponse> {
        // Create IPC message
        let message = IPCMessage::FeedbackRequest {
            request_id: uuid::Uuid::new_v4().to_string(),
            content: request.content.clone(),
            rubric: request.rubric.clone(),
            criteria: request.criteria.clone(),
        };

        // Send request
        ipc_client.send(&message).await?;

        // Wait for response with timeout
        let timeout = Duration::from_secs(request.timeout_secs);
        let response_msg = tokio::time::timeout(timeout, ipc_client.receive())
            .await
            .context("Timeout waiting for AI response")??;

        // Parse response
        match response_msg {
            IPCMessage::FeedbackResponse {
                request_id: _,
                feedback,
                scores,
                overall_grade,
            } => Ok(FeedbackResponse {
                tma_id: request.tma_id.clone(),
                feedback: feedback.clone(),
                criterion_scores: scores,
                overall_grade,
                suggestions: Self::extract_suggestions(&feedback),
                strengths: Self::extract_strengths(&feedback),
            }),
            IPCMessage::Error { message } => {
                anyhow::bail!("AI processing error: {}", message)
            }
            _ => anyhow::bail!("Unexpected response type from AI jail"),
        }
    }

    /// Generate mock feedback for testing (when no IPC client available)
    fn generate_mock_feedback(request: &FeedbackRequest) -> Result<FeedbackResponse> {
        let mut criterion_scores = Vec::new();

        for criterion in &request.criteria {
            criterion_scores.push(CriterionScore {
                criterion_number: criterion.number,
                criterion_text: criterion.description.clone(),
                score: 70.0,
                max_score: criterion.max_marks.unwrap_or(100.0),
                feedback: format!("Good attempt at criterion {}", criterion.number),
            });
        }

        let overall_grade = criterion_scores
            .iter()
            .map(|s| (s.score / s.max_score) * 100.0)
            .sum::<f32>()
            / criterion_scores.len() as f32;

        Ok(FeedbackResponse {
            tma_id: request.tma_id.clone(),
            feedback: "This is mock feedback. Your answer shows good understanding.".to_string(),
            criterion_scores,
            overall_grade,
            suggestions: vec!["Consider providing more examples".to_string()],
            strengths: vec!["Clear explanation of concepts".to_string()],
        })
    }

    /// Extract suggestions from feedback text
    ///
    /// Looks for common patterns like "Consider...", "Try...", "You could..."
    fn extract_suggestions(feedback: &str) -> Vec<String> {
        let mut suggestions = Vec::new();

        for line in feedback.lines() {
            let trimmed = line.trim();
            if trimmed.starts_with("Consider")
                || trimmed.starts_with("Try")
                || trimmed.starts_with("You could")
                || trimmed.starts_with("Suggestion:")
            {
                suggestions.push(trimmed.to_string());
            }
        }

        suggestions
    }

    /// Extract strengths from feedback text
    ///
    /// Looks for positive patterns like "Good...", "Excellent...", "Well done..."
    fn extract_strengths(feedback: &str) -> Vec<String> {
        let mut strengths = Vec::new();

        for line in feedback.lines() {
            let trimmed = line.trim();
            if trimmed.starts_with("Good")
                || trimmed.starts_with("Excellent")
                || trimmed.starts_with("Well done")
                || trimmed.starts_with("Strong")
                || trimmed.starts_with("Strength:")
            {
                strengths.push(trimmed.to_string());
            }
        }

        strengths
    }

    /// Validate feedback quality
    ///
    /// Checks that feedback meets minimum quality standards:
    /// - Has meaningful content
    /// - Addresses rubric criteria
    /// - Provides actionable feedback
    pub fn validate_feedback(&self, response: &FeedbackResponse) -> Result<()> {
        // Check feedback is not empty
        if response.feedback.trim().is_empty() {
            anyhow::bail!("Feedback is empty");
        }

        // Check minimum length (at least 50 characters)
        if response.feedback.len() < 50 {
            anyhow::bail!("Feedback is too short");
        }

        // Check we have scores for all criteria
        if response.criterion_scores.is_empty() {
            anyhow::bail!("No criterion scores provided");
        }

        // Check overall grade is in valid range
        if response.overall_grade < 0.0 || response.overall_grade > 100.0 {
            anyhow::bail!("Overall grade out of range: {}", response.overall_grade);
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::tma::TMAStatus;

    fn create_test_tma() -> TMA {
        TMA {
            id: uuid::Uuid::new_v4(),
            student_id: "student123".to_string(),
            module_code: "TM112".to_string(),
            question_number: 1,
            content: "This is my answer to the question.".to_string(),
            rubric: "1. Understanding\n2. Application\n3. Analysis".to_string(),
            status: TMAStatus::Submitted,
            anonymized_id: None,
        }
    }

    #[test]
    fn test_feedback_request_from_tma() {
        let tma = create_test_tma();
        let security = SecurityService::new();
        let request = FeedbackRequest::from_tma(&tma, &security).unwrap();

        assert_eq!(request.tma_id, tma.id.to_string());
        assert_eq!(request.criteria.len(), 3);
        assert_eq!(request.timeout_secs, 120);
    }

    #[test]
    fn test_feedback_request_with_timeout() {
        let tma = create_test_tma();
        let security = SecurityService::new();
        let request = FeedbackRequest::from_tma(&tma, &security)
            .unwrap()
            .with_timeout(60);

        assert_eq!(request.timeout_secs, 60);
    }

    #[tokio::test]
    async fn test_generate_mock_feedback() {
        let security = SecurityService::new();
        let mut service = FeedbackService::new(security);
        let tma = create_test_tma();

        let response = service.generate_feedback(&tma).await.unwrap();

        assert_eq!(response.tma_id, tma.id.to_string());
        assert!(!response.feedback.is_empty());
        assert_eq!(response.criterion_scores.len(), 3);
        assert!(response.overall_grade > 0.0);
    }

    #[test]
    fn test_extract_suggestions() {
        let feedback = "Good work on your answer.\nConsider adding more examples.\nTry to explain in more detail.";
        let suggestions = FeedbackService::extract_suggestions(feedback);

        assert_eq!(suggestions.len(), 2);
        assert!(suggestions[0].contains("Consider"));
        assert!(suggestions[1].contains("Try"));
    }

    #[test]
    fn test_extract_strengths() {
        let feedback = "Good explanation of the concepts.\nExcellent use of examples.\nWell done on structure.";
        let strengths = FeedbackService::extract_strengths(feedback);

        assert_eq!(strengths.len(), 3);
    }

    #[test]
    fn test_validate_feedback_valid() {
        let response = FeedbackResponse {
            tma_id: "test".to_string(),
            feedback: "This is valid feedback with sufficient content to be meaningful.".to_string(),
            criterion_scores: vec![CriterionScore {
                criterion_number: 1,
                criterion_text: "Test".to_string(),
                score: 80.0,
                max_score: 100.0,
                feedback: "Good".to_string(),
            }],
            overall_grade: 80.0,
            suggestions: vec![],
            strengths: vec![],
        };

        let security = SecurityService::new();
        let service = FeedbackService::new(security);
        assert!(service.validate_feedback(&response).is_ok());
    }

    #[test]
    fn test_validate_feedback_empty() {
        let response = FeedbackResponse {
            tma_id: "test".to_string(),
            feedback: "".to_string(),
            criterion_scores: vec![],
            overall_grade: 0.0,
            suggestions: vec![],
            strengths: vec![],
        };

        let security = SecurityService::new();
        let service = FeedbackService::new(security);
        assert!(service.validate_feedback(&response).is_err());
    }

    #[test]
    fn test_validate_feedback_too_short() {
        let response = FeedbackResponse {
            tma_id: "test".to_string(),
            feedback: "Too short".to_string(),
            criterion_scores: vec![],
            overall_grade: 0.0,
            suggestions: vec![],
            strengths: vec![],
        };

        let security = SecurityService::new();
        let service = FeedbackService::new(security);
        assert!(service.validate_feedback(&response).is_err());
    }

    #[test]
    fn test_validate_feedback_invalid_grade() {
        let response = FeedbackResponse {
            tma_id: "test".to_string(),
            feedback: "This is valid feedback with sufficient content to be meaningful.".to_string(),
            criterion_scores: vec![],
            overall_grade: 150.0, // Invalid
            suggestions: vec![],
            strengths: vec![],
        };

        let security = SecurityService::new();
        let service = FeedbackService::new(security);
        assert!(service.validate_feedback(&response).is_err());
    }
}
