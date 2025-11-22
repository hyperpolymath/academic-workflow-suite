use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TmaSubmission {
    pub student_id: Option<String>,
    pub assignment_id: Option<String>,
    pub file_path: String,
    pub rubric_path: Option<String>,
    #[serde(default)]
    pub metadata: SubmissionMetadata,
}

impl Default for TmaSubmission {
    fn default() -> Self {
        Self {
            student_id: None,
            assignment_id: None,
            file_path: String::new(),
            rubric_path: None,
            metadata: SubmissionMetadata::default(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct SubmissionMetadata {
    pub submitted_at: Option<DateTime<Utc>>,
    pub file_size: Option<u64>,
    pub file_type: Option<String>,
    pub checksum: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Feedback {
    pub id: String,
    pub tma_id: String,
    pub content: String,
    pub grade: u32,
    pub created_at: DateTime<Utc>,
    pub updated_at: Option<DateTime<Utc>>,
    pub sections: Vec<FeedbackSection>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FeedbackSection {
    pub title: String,
    pub content: String,
    pub score: Option<u32>,
    pub max_score: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Assignment {
    pub id: String,
    pub name: String,
    pub description: Option<String>,
    pub due_date: Option<DateTime<Utc>>,
    pub max_grade: u32,
    pub course_id: String,
    pub status: AssignmentStatus,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum AssignmentStatus {
    Open,
    Closed,
    Draft,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Student {
    pub id: String,
    pub name: String,
    pub email: Option<String>,
    pub course_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MarkingResult {
    pub id: String,
    pub tma_id: String,
    pub grade: u32,
    pub feedback: String,
    pub rubric_scores: Vec<RubricScore>,
    pub marked_at: DateTime<Utc>,
    pub marker: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RubricScore {
    pub criterion: String,
    pub score: u32,
    pub max_score: u32,
    pub comment: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Course {
    pub id: String,
    pub name: String,
    pub code: String,
    pub description: Option<String>,
    pub start_date: Option<DateTime<Utc>>,
    pub end_date: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServiceStatus {
    pub name: String,
    pub status: ServiceState,
    pub uptime: Option<u64>,
    pub version: Option<String>,
    pub health: HealthStatus,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ServiceState {
    Running,
    Stopped,
    Starting,
    Error,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum HealthStatus {
    Healthy,
    Unhealthy,
    Degraded,
    Unknown,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncStatus {
    pub last_sync: Option<DateTime<Utc>>,
    pub sync_status: String,
    pub items_synced: u32,
    pub errors: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CliConfig {
    pub output_format: String,
    pub color_enabled: bool,
    pub verbose: bool,
    pub api_timeout: u64,
}

impl Default for CliConfig {
    fn default() -> Self {
        Self {
            output_format: "text".to_string(),
            color_enabled: true,
            verbose: false,
            api_timeout: 30,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tma_submission_default() {
        let submission = TmaSubmission::default();
        assert!(submission.student_id.is_none());
        assert!(submission.assignment_id.is_none());
        assert_eq!(submission.file_path, "");
    }

    #[test]
    fn test_serialization() {
        let submission = TmaSubmission {
            student_id: Some("12345".to_string()),
            assignment_id: Some("TMA01".to_string()),
            file_path: "/path/to/file.pdf".to_string(),
            rubric_path: None,
            metadata: SubmissionMetadata::default(),
        };

        let json = serde_json::to_string(&submission).unwrap();
        let deserialized: TmaSubmission = serde_json::from_str(&json).unwrap();

        assert_eq!(submission.student_id, deserialized.student_id);
        assert_eq!(submission.assignment_id, deserialized.assignment_id);
    }
}
