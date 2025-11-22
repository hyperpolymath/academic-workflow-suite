// Output Validation Tests for AI-generated content
// Ensures AI outputs don't contain PII

use regex::Regex;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct AIOutput {
    pub content: String,
    pub source: String,
    pub timestamp: String,
}

#[derive(Debug, PartialEq)]
pub enum ValidationResult {
    Pass,
    Fail(Vec<String>),
}

pub struct OutputValidator {
    pii_patterns: Vec<(String, Regex)>,
}

impl OutputValidator {
    pub fn new() -> Self {
        let mut pii_patterns = Vec::new();

        // Email pattern
        pii_patterns.push((
            "Email".to_string(),
            Regex::new(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b").unwrap(),
        ));

        // Phone pattern
        pii_patterns.push((
            "Phone".to_string(),
            Regex::new(r"\b\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b").unwrap(),
        ));

        // SSN pattern
        pii_patterns.push((
            "SSN".to_string(),
            Regex::new(r"\b\d{3}-\d{2}-\d{4}\b").unwrap(),
        ));

        // Numeric student ID (not hashed)
        pii_patterns.push((
            "Student ID".to_string(),
            Regex::new(r"(?i)student\s*id[:\s]+\d{6,10}(?!\w)").unwrap(),
        ));

        // Credit card
        pii_patterns.push((
            "Credit Card".to_string(),
            Regex::new(r"\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b").unwrap(),
        ));

        OutputValidator { pii_patterns }
    }

    pub fn validate(&self, output: &AIOutput) -> ValidationResult {
        let mut violations = Vec::new();

        for (pattern_name, pattern) in &self.pii_patterns {
            if let Some(matched) = pattern.find(&output.content) {
                // Skip if it's a hashed/anonymized ID
                if pattern_name == "Student ID" && output.content.contains("sha256:") {
                    continue;
                }

                violations.push(format!(
                    "{} detected: {} in output from {}",
                    pattern_name,
                    matched.as_str(),
                    output.source
                ));
            }
        }

        if violations.is_empty() {
            ValidationResult::Pass
        } else {
            ValidationResult::Fail(violations)
        }
    }

    pub fn validate_batch(&self, outputs: &[AIOutput]) -> Vec<(usize, ValidationResult)> {
        outputs
            .iter()
            .enumerate()
            .map(|(idx, output)| (idx, self.validate(output)))
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validates_clean_output() {
        let validator = OutputValidator::new();
        let output = AIOutput {
            content: "This assignment demonstrates good understanding of the topic.".to_string(),
            source: "grading_ai".to_string(),
            timestamp: "2025-01-01T00:00:00Z".to_string(),
        };

        assert_eq!(validator.validate(&output), ValidationResult::Pass);
    }

    #[test]
    fn test_detects_email() {
        let validator = OutputValidator::new();
        let output = AIOutput {
            content: "Contact student at john.doe@university.edu for clarification.".to_string(),
            source: "feedback_ai".to_string(),
            timestamp: "2025-01-01T00:00:00Z".to_string(),
        };

        match validator.validate(&output) {
            ValidationResult::Fail(violations) => {
                assert!(violations[0].contains("Email detected"));
            }
            _ => panic!("Expected failure"),
        }
    }

    #[test]
    fn test_allows_anonymized_student_id() {
        let validator = OutputValidator::new();
        let output = AIOutput {
            content: "Student ID: sha256:9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08".to_string(),
            source: "grading_ai".to_string(),
            timestamp: "2025-01-01T00:00:00Z".to_string(),
        };

        assert_eq!(validator.validate(&output), ValidationResult::Pass);
    }

    #[test]
    fn test_detects_plain_student_id() {
        let validator = OutputValidator::new();
        let output = AIOutput {
            content: "Student ID: 12345678 received a grade of A.".to_string(),
            source: "grading_ai".to_string(),
            timestamp: "2025-01-01T00:00:00Z".to_string(),
        };

        match validator.validate(&output) {
            ValidationResult::Fail(violations) => {
                assert!(violations[0].contains("Student ID detected"));
            }
            _ => panic!("Expected failure"),
        }
    }

    #[test]
    fn test_batch_validation() {
        let validator = OutputValidator::new();
        let outputs = vec![
            AIOutput {
                content: "Good work on the assignment.".to_string(),
                source: "ai1".to_string(),
                timestamp: "2025-01-01T00:00:00Z".to_string(),
            },
            AIOutput {
                content: "Contact at test@example.com".to_string(),
                source: "ai2".to_string(),
                timestamp: "2025-01-01T00:00:00Z".to_string(),
            },
        ];

        let results = validator.validate_batch(&outputs);

        assert_eq!(results[0].1, ValidationResult::Pass);
        assert!(matches!(results[1].1, ValidationResult::Fail(_)));
    }
}

fn main() {
    println!("AI Output Validation Test Suite");
    println!("================================\n");

    let validator = OutputValidator::new();

    let test_outputs = vec![
        AIOutput {
            content: "Excellent work! The analysis is thorough and well-structured.".to_string(),
            source: "feedback_generator".to_string(),
            timestamp: "2025-01-01T10:00:00Z".to_string(),
        },
        AIOutput {
            content: "Student ID: 12345678 needs to improve citations.".to_string(),
            source: "grading_system".to_string(),
            timestamp: "2025-01-01T10:05:00Z".to_string(),
        },
        AIOutput {
            content: "Please contact student@university.edu for follow-up.".to_string(),
            source: "communication_ai".to_string(),
            timestamp: "2025-01-01T10:10:00Z".to_string(),
        },
        AIOutput {
            content: "Student sha256:abc123... demonstrated strong analytical skills.".to_string(),
            source: "feedback_generator".to_string(),
            timestamp: "2025-01-01T10:15:00Z".to_string(),
        },
    ];

    let results = validator.validate_batch(&test_outputs);
    let mut total_violations = 0;

    for (idx, result) in results {
        println!("Output #{}: {}", idx + 1, test_outputs[idx].source);
        match result {
            ValidationResult::Pass => {
                println!("✓ PASS: No PII detected\n");
            }
            ValidationResult::Fail(violations) => {
                println!("✗ FAIL: PII detected!");
                for violation in &violations {
                    println!("  - {}", violation);
                    total_violations += 1;
                }
                println!();
            }
        }
    }

    println!("================================");
    println!("Total outputs checked: {}", test_outputs.len());
    println!("Total violations: {}", total_violations);

    if total_violations > 0 {
        println!("\n⚠ CRITICAL: AI outputs contain PII!");
        std::process::exit(1);
    } else {
        println!("\n✓ All outputs passed validation");
        std::process::exit(0);
    }
}
