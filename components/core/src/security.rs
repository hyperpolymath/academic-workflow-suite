//! Privacy-First Security and Anonymization
//!
//! Provides cryptographic hashing for student IDs and PII detection
//! to ensure privacy before AI processing.

use anyhow::Result;
use regex::Regex;
use serde::{Deserialize, Serialize};
use sha3::{Digest, Sha3_256};
use std::collections::HashMap;

/// Result of anonymization operation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AnonymizationResult {
    /// Original value (for audit trail only - should not be sent to AI)
    pub original: String,
    /// Anonymized hash
    pub anonymized: String,
    /// Salt used (if any)
    pub salt: Option<String>,
}

/// PII (Personally Identifiable Information) detection result
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PIIDetectionResult {
    /// Whether PII was found
    pub found: bool,
    /// Types of PII detected
    pub pii_types: Vec<PIIType>,
    /// Locations of detected PII (line numbers)
    pub locations: Vec<PIILocation>,
}

/// Types of PII that can be detected
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum PIIType {
    Email,
    PhoneNumber,
    Name,
    StudentId,
    PostalCode,
    Url,
}

/// Location of detected PII
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PIILocation {
    pub pii_type: PIIType,
    pub line: usize,
    pub column: usize,
    pub matched_text: String,
}

/// Security service for anonymization and PII detection
pub struct SecurityService {
    /// Regex patterns for PII detection
    patterns: HashMap<PIIType, Regex>,
}

impl SecurityService {
    /// Create a new security service
    pub fn new() -> Self {
        let mut patterns = HashMap::new();

        // Email pattern
        patterns.insert(
            PIIType::Email,
            Regex::new(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b")
                .expect("Invalid email regex"),
        );

        // UK phone number pattern (various formats)
        patterns.insert(
            PIIType::PhoneNumber,
            Regex::new(r"\b(?:(?:\+44\s?|0)(?:\d\s?){9,10})\b")
                .expect("Invalid phone regex"),
        );

        // UK postal code pattern
        patterns.insert(
            PIIType::PostalCode,
            Regex::new(r"\b[A-Z]{1,2}\d{1,2}\s?\d[A-Z]{2}\b")
                .expect("Invalid postal code regex"),
        );

        // URL pattern (might contain identifying info)
        patterns.insert(
            PIIType::Url,
            Regex::new(r"https?://[^\s]+")
                .expect("Invalid URL regex"),
        );

        // Student ID pattern (typically alphanumeric, 6-10 chars)
        // This is a generic pattern - customize based on OU format
        patterns.insert(
            PIIType::StudentId,
            Regex::new(r"\b[A-Z]\d{7}\b")
                .expect("Invalid student ID regex"),
        );

        Self { patterns }
    }

    /// Anonymize a student ID using SHA3-256
    ///
    /// This is a one-way hash - the original ID cannot be recovered.
    ///
    /// # Arguments
    ///
    /// * `student_id` - The student ID to anonymize
    ///
    /// # Example
    ///
    /// ```
    /// use aws_core::SecurityService;
    ///
    /// let security = SecurityService::new();
    /// let result = security.anonymize_student_id("student123").unwrap();
    /// assert_ne!(result.anonymized, "student123");
    /// ```
    pub fn anonymize_student_id(&self, student_id: &str) -> Result<AnonymizationResult> {
        let trimmed = student_id.trim();
        if trimmed.is_empty() {
            anyhow::bail!("Student ID cannot be empty");
        }

        let hash = self.hash_sha3(trimmed.as_bytes());

        Ok(AnonymizationResult {
            original: trimmed.to_string(),
            anonymized: hash,
            salt: None,
        })
    }

    /// Anonymize a student ID with a custom salt
    ///
    /// Use this when you need deterministic hashing with a secret salt.
    pub fn anonymize_student_id_with_salt(
        &self,
        student_id: &str,
        salt: &str,
    ) -> Result<AnonymizationResult> {
        let trimmed = student_id.trim();
        if trimmed.is_empty() {
            anyhow::bail!("Student ID cannot be empty");
        }

        let salted = format!("{}{}", salt, trimmed);
        let hash = self.hash_sha3(salted.as_bytes());

        Ok(AnonymizationResult {
            original: trimmed.to_string(),
            anonymized: hash,
            salt: Some(salt.to_string()),
        })
    }

    /// Compute SHA3-256 hash and return as hex string
    fn hash_sha3(&self, data: &[u8]) -> String {
        let mut hasher = Sha3_256::new();
        hasher.update(data);
        let result = hasher.finalize();
        hex::encode(result)
    }

    /// Detect PII in text content
    ///
    /// Scans the text for common PII patterns and returns detected instances.
    ///
    /// # Arguments
    ///
    /// * `content` - The text to scan for PII
    ///
    /// # Example
    ///
    /// ```
    /// use aws_core::SecurityService;
    ///
    /// let security = SecurityService::new();
    /// let result = security.detect_pii("Contact me at john@example.com");
    /// assert!(result.found);
    /// ```
    pub fn detect_pii(&self, content: &str) -> PIIDetectionResult {
        let mut locations = Vec::new();
        let mut pii_types = Vec::new();

        for (line_num, line) in content.lines().enumerate() {
            for (pii_type, pattern) in &self.patterns {
                for capture in pattern.find_iter(line) {
                    if !pii_types.contains(pii_type) {
                        pii_types.push(pii_type.clone());
                    }

                    locations.push(PIILocation {
                        pii_type: pii_type.clone(),
                        line: line_num + 1,
                        column: capture.start(),
                        matched_text: capture.as_str().to_string(),
                    });
                }
            }
        }

        PIIDetectionResult {
            found: !locations.is_empty(),
            pii_types,
            locations,
        }
    }

    /// Sanitize content by replacing PII with placeholders
    ///
    /// This is a destructive operation - use with caution.
    /// For audit trail, save the original content before sanitization.
    pub fn sanitize_content(&self, content: &str) -> String {
        let mut sanitized = content.to_string();

        // Replace emails
        if let Some(email_pattern) = self.patterns.get(&PIIType::Email) {
            sanitized = email_pattern
                .replace_all(&sanitized, "[EMAIL_REDACTED]")
                .to_string();
        }

        // Replace phone numbers
        if let Some(phone_pattern) = self.patterns.get(&PIIType::PhoneNumber) {
            sanitized = phone_pattern
                .replace_all(&sanitized, "[PHONE_REDACTED]")
                .to_string();
        }

        // Replace postal codes
        if let Some(postal_pattern) = self.patterns.get(&PIIType::PostalCode) {
            sanitized = postal_pattern
                .replace_all(&sanitized, "[POSTCODE_REDACTED]")
                .to_string();
        }

        // Replace URLs (might contain personal info)
        if let Some(url_pattern) = self.patterns.get(&PIIType::Url) {
            sanitized = url_pattern
                .replace_all(&sanitized, "[URL_REDACTED]")
                .to_string();
        }

        // Replace student IDs
        if let Some(id_pattern) = self.patterns.get(&PIIType::StudentId) {
            sanitized = id_pattern
                .replace_all(&sanitized, "[STUDENT_ID_REDACTED]")
                .to_string();
        }

        sanitized
    }

    /// Validate that output from AI doesn't contain PII
    ///
    /// This should be called on AI-generated content before returning
    /// it to the lecturer to ensure no PII leaked through.
    pub fn validate_output(&self, output: &str) -> Result<()> {
        let detection = self.detect_pii(output);

        if detection.found {
            anyhow::bail!(
                "PII detected in AI output: found {} instances of {} types",
                detection.locations.len(),
                detection.pii_types.len()
            );
        }

        Ok(())
    }

    /// Create a redaction report for audit purposes
    pub fn create_redaction_report(&self, content: &str) -> RedactionReport {
        let detection = self.detect_pii(content);

        RedactionReport {
            original_length: content.len(),
            pii_found: detection.found,
            pii_count: detection.locations.len(),
            pii_types: detection.pii_types,
            timestamp: chrono::Utc::now(),
        }
    }
}

impl Default for SecurityService {
    fn default() -> Self {
        Self::new()
    }
}

/// Report of redaction operations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RedactionReport {
    pub original_length: usize,
    pub pii_found: bool,
    pub pii_count: usize,
    pub pii_types: Vec<PIIType>,
    pub timestamp: chrono::DateTime<chrono::Utc>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_anonymize_student_id() {
        let security = SecurityService::new();
        let result = security.anonymize_student_id("student123").unwrap();

        assert_eq!(result.original, "student123");
        assert_ne!(result.anonymized, "student123");
        assert_eq!(result.anonymized.len(), 64); // SHA3-256 produces 64 hex chars
    }

    #[test]
    fn test_anonymize_student_id_deterministic() {
        let security = SecurityService::new();
        let result1 = security.anonymize_student_id("student123").unwrap();
        let result2 = security.anonymize_student_id("student123").unwrap();

        assert_eq!(result1.anonymized, result2.anonymized);
    }

    #[test]
    fn test_anonymize_student_id_with_salt() {
        let security = SecurityService::new();
        let result = security
            .anonymize_student_id_with_salt("student123", "my-salt")
            .unwrap();

        assert_eq!(result.salt, Some("my-salt".to_string()));
        assert_ne!(result.anonymized, security.anonymize_student_id("student123").unwrap().anonymized);
    }

    #[test]
    fn test_anonymize_empty_student_id() {
        let security = SecurityService::new();
        let result = security.anonymize_student_id("");

        assert!(result.is_err());
    }

    #[test]
    fn test_detect_email() {
        let security = SecurityService::new();
        let result = security.detect_pii("Contact me at john.doe@example.com for details");

        assert!(result.found);
        assert!(result.pii_types.contains(&PIIType::Email));
        assert_eq!(result.locations.len(), 1);
        assert_eq!(result.locations[0].matched_text, "john.doe@example.com");
    }

    #[test]
    fn test_detect_phone_number() {
        let security = SecurityService::new();
        let result = security.detect_pii("Call me on 07123456789");

        assert!(result.found);
        assert!(result.pii_types.contains(&PIIType::PhoneNumber));
    }

    #[test]
    fn test_detect_postal_code() {
        let security = SecurityService::new();
        let result = security.detect_pii("My address is MK7 6AA");

        assert!(result.found);
        assert!(result.pii_types.contains(&PIIType::PostalCode));
    }

    #[test]
    fn test_detect_url() {
        let security = SecurityService::new();
        let result = security.detect_pii("Visit https://example.com/myprofile");

        assert!(result.found);
        assert!(result.pii_types.contains(&PIIType::Url));
    }

    #[test]
    fn test_detect_no_pii() {
        let security = SecurityService::new();
        let result = security.detect_pii("This is a clean answer with no personal information");

        assert!(!result.found);
        assert!(result.locations.is_empty());
    }

    #[test]
    fn test_sanitize_content() {
        let security = SecurityService::new();
        let content = "Email me at john@example.com or call 07123456789";
        let sanitized = security.sanitize_content(content);

        assert!(!sanitized.contains("john@example.com"));
        assert!(!sanitized.contains("07123456789"));
        assert!(sanitized.contains("[EMAIL_REDACTED]"));
        assert!(sanitized.contains("[PHONE_REDACTED]"));
    }

    #[test]
    fn test_validate_output_clean() {
        let security = SecurityService::new();
        let result = security.validate_output("This is clean feedback with no PII");

        assert!(result.is_ok());
    }

    #[test]
    fn test_validate_output_with_pii() {
        let security = SecurityService::new();
        let result = security.validate_output("Good work! Email me at john@example.com");

        assert!(result.is_err());
    }

    #[test]
    fn test_create_redaction_report() {
        let security = SecurityService::new();
        let content = "Contact john@example.com or call 07123456789";
        let report = security.create_redaction_report(content);

        assert!(report.pii_found);
        assert_eq!(report.pii_count, 2);
        assert!(report.pii_types.contains(&PIIType::Email));
        assert!(report.pii_types.contains(&PIIType::PhoneNumber));
    }

    #[test]
    fn test_multiple_pii_on_same_line() {
        let security = SecurityService::new();
        let result = security.detect_pii("Email john@example.com or jane@example.com");

        assert!(result.found);
        assert_eq!(result.locations.len(), 2);
        assert!(result.locations.iter().all(|loc| loc.pii_type == PIIType::Email));
    }
}
