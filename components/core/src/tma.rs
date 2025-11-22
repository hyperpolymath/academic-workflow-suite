//! TMA (Tutor-Marked Assignment) Processing
//!
//! Core data structures and logic for handling TMA submissions,
//! validation, and rubric matching.

use serde::{Deserialize, Serialize};
use thiserror::Error;
use uuid::Uuid;

/// Errors that can occur during TMA validation
#[derive(Debug, Error)]
pub enum ValidationError {
    #[error("Student ID cannot be empty")]
    EmptyStudentId,

    #[error("Module code cannot be empty")]
    EmptyModuleCode,

    #[error("Invalid module code format: {0}")]
    InvalidModuleCode(String),

    #[error("Question number must be greater than 0")]
    InvalidQuestionNumber,

    #[error("TMA content cannot be empty")]
    EmptyContent,

    #[error("TMA content exceeds maximum length of {max} characters (got {actual})")]
    ContentTooLong { max: usize, actual: usize },

    #[error("Rubric cannot be empty")]
    EmptyRubric,
}

/// Status of a TMA in the processing pipeline
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum TMAStatus {
    /// TMA has been submitted but not yet processed
    Submitted,
    /// TMA is being anonymized
    Anonymizing,
    /// TMA is being processed by AI
    Processing,
    /// Feedback has been generated
    FeedbackGenerated,
    /// Grade has been assigned
    Graded,
    /// TMA processing failed
    Failed,
}

/// A Tutor-Marked Assignment submission
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TMA {
    /// Unique identifier for this TMA
    pub id: Uuid,
    /// Student identifier (will be anonymized before AI processing)
    pub student_id: String,
    /// Module code (e.g., "TM112", "M250")
    pub module_code: String,
    /// Question number within the TMA
    pub question_number: u32,
    /// Student's answer content
    pub content: String,
    /// Rubric/marking criteria for this question
    pub rubric: String,
    /// Current processing status
    pub status: TMAStatus,
    /// Anonymized student ID (populated during anonymization)
    pub anonymized_id: Option<String>,
}

impl TMA {
    /// Maximum allowed content length (100KB)
    pub const MAX_CONTENT_LENGTH: usize = 100 * 1024;

    /// Create a new TMA submission
    ///
    /// # Arguments
    ///
    /// * `student_id` - The student's identifier
    /// * `module_code` - The OU module code
    /// * `question_number` - Question number (1-based)
    /// * `content` - The student's answer
    /// * `rubric` - Marking criteria/rubric
    ///
    /// # Example
    ///
    /// ```
    /// use aws_core::TMA;
    ///
    /// let tma = TMA::new(
    ///     "student123".to_string(),
    ///     "TM112".to_string(),
    ///     1,
    ///     "My answer to question 1...".to_string(),
    ///     "Rubric: Award marks for...".to_string(),
    /// );
    /// ```
    pub fn new(
        student_id: String,
        module_code: String,
        question_number: u32,
        content: String,
        rubric: String,
    ) -> Self {
        Self {
            id: Uuid::new_v4(),
            student_id,
            module_code,
            question_number,
            content,
            rubric,
            status: TMAStatus::Submitted,
            anonymized_id: None,
        }
    }

    /// Validate the TMA submission
    ///
    /// # Errors
    ///
    /// Returns `ValidationError` if any validation fails:
    /// - Student ID is empty
    /// - Module code is empty or invalid format
    /// - Question number is 0
    /// - Content is empty or too long
    /// - Rubric is empty
    pub fn validate(&self) -> Result<(), ValidationError> {
        // Validate student ID
        if self.student_id.trim().is_empty() {
            return Err(ValidationError::EmptyStudentId);
        }

        // Validate module code
        if self.module_code.trim().is_empty() {
            return Err(ValidationError::EmptyModuleCode);
        }

        if !Self::is_valid_module_code(&self.module_code) {
            return Err(ValidationError::InvalidModuleCode(self.module_code.clone()));
        }

        // Validate question number
        if self.question_number == 0 {
            return Err(ValidationError::InvalidQuestionNumber);
        }

        // Validate content
        if self.content.trim().is_empty() {
            return Err(ValidationError::EmptyContent);
        }

        if self.content.len() > Self::MAX_CONTENT_LENGTH {
            return Err(ValidationError::ContentTooLong {
                max: Self::MAX_CONTENT_LENGTH,
                actual: self.content.len(),
            });
        }

        // Validate rubric
        if self.rubric.trim().is_empty() {
            return Err(ValidationError::EmptyRubric);
        }

        Ok(())
    }

    /// Check if a module code follows the Open University format
    ///
    /// Valid formats:
    /// - Letter(s) followed by digits (e.g., "TM112", "M250", "MST124")
    /// - Typically 1-4 letters followed by 3 digits
    fn is_valid_module_code(code: &str) -> bool {
        let code = code.trim().to_uppercase();

        // Must be 4-7 characters
        if code.len() < 4 || code.len() > 7 {
            return false;
        }

        // Must start with letters and end with digits
        let mut chars = code.chars();
        let mut has_letters = false;
        let mut has_digits = false;

        // Check for letters at the start
        while let Some(c) = chars.next() {
            if c.is_ascii_alphabetic() {
                has_letters = true;
            } else if c.is_ascii_digit() {
                has_digits = true;
                break;
            } else {
                return false;
            }
        }

        // Rest should be digits
        for c in chars {
            if !c.is_ascii_digit() {
                return false;
            }
            has_digits = true;
        }

        has_letters && has_digits
    }

    /// Update the TMA status
    pub fn set_status(&mut self, status: TMAStatus) {
        self.status = status;
    }

    /// Set the anonymized student ID
    pub fn set_anonymized_id(&mut self, anonymized_id: String) {
        self.anonymized_id = Some(anonymized_id);
    }

    /// Extract rubric criteria as structured items
    ///
    /// This is a simple implementation that splits rubric by common delimiters.
    /// In production, this would be more sophisticated.
    pub fn parse_rubric_criteria(&self) -> Vec<RubricCriterion> {
        let mut criteria = Vec::new();
        let mut current_num = 0;

        for line in self.rubric.lines() {
            let trimmed = line.trim();
            if trimmed.is_empty() {
                continue;
            }

            // Look for numbered criteria or bullet points
            if trimmed.starts_with(|c: char| c.is_ascii_digit())
                || trimmed.starts_with("•")
                || trimmed.starts_with("-")
                || trimmed.starts_with("*")
            {
                current_num += 1;
                criteria.push(RubricCriterion {
                    number: current_num,
                    description: trimmed.to_string(),
                    max_marks: None, // Would need parsing to extract marks
                });
            }
        }

        // If no structured criteria found, treat entire rubric as one criterion
        if criteria.is_empty() {
            criteria.push(RubricCriterion {
                number: 1,
                description: self.rubric.clone(),
                max_marks: None,
            });
        }

        criteria
    }

    /// Get a sanitized version of the TMA content
    ///
    /// This removes any PII that might have been missed and prepares
    /// the content for AI processing.
    pub fn sanitized_content(&self) -> String {
        // In production, this would do more sophisticated sanitization
        // For now, just trim whitespace
        self.content.trim().to_string()
    }
}

/// A single criterion from a rubric
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RubricCriterion {
    pub number: u32,
    pub description: String,
    pub max_marks: Option<f32>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_new_tma() {
        let tma = TMA::new(
            "student123".to_string(),
            "TM112".to_string(),
            1,
            "My answer".to_string(),
            "Rubric criteria".to_string(),
        );

        assert_eq!(tma.student_id, "student123");
        assert_eq!(tma.module_code, "TM112");
        assert_eq!(tma.question_number, 1);
        assert_eq!(tma.status, TMAStatus::Submitted);
        assert!(tma.anonymized_id.is_none());
    }

    #[test]
    fn test_validate_valid_tma() {
        let tma = TMA::new(
            "student123".to_string(),
            "TM112".to_string(),
            1,
            "My answer".to_string(),
            "Rubric criteria".to_string(),
        );

        assert!(tma.validate().is_ok());
    }

    #[test]
    fn test_validate_empty_student_id() {
        let tma = TMA::new(
            "".to_string(),
            "TM112".to_string(),
            1,
            "My answer".to_string(),
            "Rubric criteria".to_string(),
        );

        assert!(matches!(tma.validate(), Err(ValidationError::EmptyStudentId)));
    }

    #[test]
    fn test_validate_empty_content() {
        let tma = TMA::new(
            "student123".to_string(),
            "TM112".to_string(),
            1,
            "".to_string(),
            "Rubric criteria".to_string(),
        );

        assert!(matches!(tma.validate(), Err(ValidationError::EmptyContent)));
    }

    #[test]
    fn test_validate_invalid_question_number() {
        let tma = TMA::new(
            "student123".to_string(),
            "TM112".to_string(),
            0,
            "My answer".to_string(),
            "Rubric criteria".to_string(),
        );

        assert!(matches!(tma.validate(), Err(ValidationError::InvalidQuestionNumber)));
    }

    #[test]
    fn test_validate_content_too_long() {
        let long_content = "a".repeat(TMA::MAX_CONTENT_LENGTH + 1);
        let tma = TMA::new(
            "student123".to_string(),
            "TM112".to_string(),
            1,
            long_content,
            "Rubric criteria".to_string(),
        );

        assert!(matches!(tma.validate(), Err(ValidationError::ContentTooLong { .. })));
    }

    #[test]
    fn test_valid_module_codes() {
        assert!(TMA::is_valid_module_code("TM112"));
        assert!(TMA::is_valid_module_code("M250"));
        assert!(TMA::is_valid_module_code("MST124"));
        assert!(TMA::is_valid_module_code("TM111"));
        assert!(TMA::is_valid_module_code("tm112")); // lowercase
    }

    #[test]
    fn test_invalid_module_codes() {
        assert!(!TMA::is_valid_module_code(""));
        assert!(!TMA::is_valid_module_code("ABC"));
        assert!(!TMA::is_valid_module_code("123"));
        assert!(!TMA::is_valid_module_code("TM-112"));
        assert!(!TMA::is_valid_module_code("TOOLONG123"));
    }

    #[test]
    fn test_set_status() {
        let mut tma = TMA::new(
            "student123".to_string(),
            "TM112".to_string(),
            1,
            "My answer".to_string(),
            "Rubric criteria".to_string(),
        );

        tma.set_status(TMAStatus::Processing);
        assert_eq!(tma.status, TMAStatus::Processing);
    }

    #[test]
    fn test_set_anonymized_id() {
        let mut tma = TMA::new(
            "student123".to_string(),
            "TM112".to_string(),
            1,
            "My answer".to_string(),
            "Rubric criteria".to_string(),
        );

        tma.set_anonymized_id("anon123".to_string());
        assert_eq!(tma.anonymized_id, Some("anon123".to_string()));
    }

    #[test]
    fn test_parse_rubric_criteria_numbered() {
        let tma = TMA::new(
            "student123".to_string(),
            "TM112".to_string(),
            1,
            "My answer".to_string(),
            "1. First criterion\n2. Second criterion\n3. Third criterion".to_string(),
        );

        let criteria = tma.parse_rubric_criteria();
        assert_eq!(criteria.len(), 3);
        assert_eq!(criteria[0].number, 1);
        assert!(criteria[0].description.contains("First criterion"));
    }

    #[test]
    fn test_parse_rubric_criteria_bullets() {
        let tma = TMA::new(
            "student123".to_string(),
            "TM112".to_string(),
            1,
            "My answer".to_string(),
            "• First point\n• Second point\n• Third point".to_string(),
        );

        let criteria = tma.parse_rubric_criteria();
        assert_eq!(criteria.len(), 3);
    }

    #[test]
    fn test_parse_rubric_criteria_unstructured() {
        let tma = TMA::new(
            "student123".to_string(),
            "TM112".to_string(),
            1,
            "My answer".to_string(),
            "This is just plain text rubric without structure".to_string(),
        );

        let criteria = tma.parse_rubric_criteria();
        assert_eq!(criteria.len(), 1);
        assert_eq!(criteria[0].number, 1);
    }
}
