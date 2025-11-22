//! IPC protocol definitions for stdin/stdout communication
//!
//! This module defines the request/response protocol used for communication
//! between the orchestrator and the AI jail container.

use serde::{Deserialize, Serialize};

/// Request sent from orchestrator to AI jail via stdin
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InferenceRequest {
    /// Anonymized TMA content (student answers removed)
    pub tma_content: String,

    /// Grading rubric for this question
    pub rubric: String,

    /// Question number being graded
    pub question_number: u32,

    /// Optional: Student's answer (anonymized)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub student_answer: Option<String>,

    /// Optional: Maximum tokens to generate
    #[serde(default = "default_max_tokens")]
    pub max_tokens: usize,

    /// Optional: Temperature for sampling (0.0-2.0)
    #[serde(default = "default_temperature")]
    pub temperature: f64,

    /// Optional: Top-p sampling threshold
    #[serde(default = "default_top_p")]
    pub top_p: f64,
}

/// Response sent from AI jail to orchestrator via stdout
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InferenceResponse {
    /// Generated feedback text
    pub feedback: String,

    /// Model confidence score (0.0-1.0)
    pub confidence: f32,

    /// How well the feedback aligns with the rubric (0.0-1.0)
    pub rubric_alignment: f32,

    /// Tokens generated
    pub tokens_generated: usize,

    /// Inference time in milliseconds
    pub inference_time_ms: u64,
}

/// Error response when inference fails
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ErrorResponse {
    /// Error type
    pub error_type: String,

    /// Human-readable error message
    pub message: String,

    /// Optional detailed error information
    #[serde(skip_serializing_if = "Option::is_none")]
    pub details: Option<String>,
}

/// Wrapper for all responses
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "status")]
pub enum Response {
    #[serde(rename = "success")]
    Success(InferenceResponse),

    #[serde(rename = "error")]
    Error(ErrorResponse),
}

fn default_max_tokens() -> usize {
    512
}

fn default_temperature() -> f64 {
    0.7
}

fn default_top_p() -> f64 {
    0.9
}

impl InferenceRequest {
    /// Validate request parameters
    pub fn validate(&self) -> Result<(), String> {
        if self.tma_content.is_empty() {
            return Err("TMA content cannot be empty".to_string());
        }

        if self.rubric.is_empty() {
            return Err("Rubric cannot be empty".to_string());
        }

        if self.temperature < 0.0 || self.temperature > 2.0 {
            return Err("Temperature must be between 0.0 and 2.0".to_string());
        }

        if self.top_p < 0.0 || self.top_p > 1.0 {
            return Err("Top-p must be between 0.0 and 1.0".to_string());
        }

        if self.max_tokens == 0 || self.max_tokens > 4096 {
            return Err("Max tokens must be between 1 and 4096".to_string());
        }

        Ok(())
    }

    /// Format the request into a prompt for the model
    pub fn to_prompt(&self) -> String {
        let mut prompt = String::new();

        prompt.push_str("<|im_start|>system\n");
        prompt.push_str("You are an expert academic grader assistant. ");
        prompt.push_str("Your task is to provide constructive feedback on student answers ");
        prompt.push_str("based on the provided rubric. Be objective, specific, and helpful.\n");
        prompt.push_str("<|im_end|>\n");

        prompt.push_str("<|im_start|>user\n");
        prompt.push_str(&format!("Question {}\n\n", self.question_number));
        prompt.push_str("TMA Context:\n");
        prompt.push_str(&self.tma_content);
        prompt.push_str("\n\nGrading Rubric:\n");
        prompt.push_str(&self.rubric);

        if let Some(answer) = &self.student_answer {
            prompt.push_str("\n\nStudent Answer:\n");
            prompt.push_str(answer);
        }

        prompt.push_str("\n\nProvide detailed feedback based on the rubric:\n");
        prompt.push_str("<|im_end|>\n");
        prompt.push_str("<|im_start|>assistant\n");

        prompt
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_request_validation() {
        let mut req = InferenceRequest {
            tma_content: "Test content".to_string(),
            rubric: "Test rubric".to_string(),
            question_number: 1,
            student_answer: None,
            max_tokens: 512,
            temperature: 0.7,
            top_p: 0.9,
        };

        assert!(req.validate().is_ok());

        // Test invalid temperature
        req.temperature = 3.0;
        assert!(req.validate().is_err());

        req.temperature = 0.7;

        // Test invalid max_tokens
        req.max_tokens = 0;
        assert!(req.validate().is_err());
    }

    #[test]
    fn test_prompt_formatting() {
        let req = InferenceRequest {
            tma_content: "Discuss the impact of climate change.".to_string(),
            rubric: "Award 10 marks for comprehensive discussion.".to_string(),
            question_number: 1,
            student_answer: Some("Climate change affects weather patterns.".to_string()),
            max_tokens: 512,
            temperature: 0.7,
            top_p: 0.9,
        };

        let prompt = req.to_prompt();
        assert!(prompt.contains("Question 1"));
        assert!(prompt.contains("climate change"));
        assert!(prompt.contains("weather patterns"));
    }

    #[test]
    fn test_serde_roundtrip() {
        let req = InferenceRequest {
            tma_content: "Test".to_string(),
            rubric: "Rubric".to_string(),
            question_number: 1,
            student_answer: None,
            max_tokens: 512,
            temperature: 0.7,
            top_p: 0.9,
        };

        let json = serde_json::to_string(&req).unwrap();
        let decoded: InferenceRequest = serde_json::from_str(&json).unwrap();

        assert_eq!(req.tma_content, decoded.tma_content);
        assert_eq!(req.rubric, decoded.rubric);
        assert_eq!(req.question_number, decoded.question_number);
    }
}
