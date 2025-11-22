// PII Leakage Detection Tests
// Automated tests to detect personally identifiable information leakage

use regex::Regex;
use std::fs;
use std::path::Path;

#[derive(Debug)]
pub struct PIIPattern {
    name: String,
    pattern: Regex,
    severity: Severity,
}

#[derive(Debug, PartialEq)]
pub enum Severity {
    Critical,
    High,
    Medium,
    Low,
}

pub struct PIIDetector {
    patterns: Vec<PIIPattern>,
}

impl PIIDetector {
    pub fn new() -> Self {
        let mut patterns = Vec::new();

        // Student ID patterns
        patterns.push(PIIPattern {
            name: "Student ID (Numeric)".to_string(),
            pattern: Regex::new(r"\b\d{6,10}\b").unwrap(),
            severity: Severity::High,
        });

        // Email addresses
        patterns.push(PIIPattern {
            name: "Email Address".to_string(),
            pattern: Regex::new(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b").unwrap(),
            severity: Severity::High,
        });

        // Phone numbers
        patterns.push(PIIPattern {
            name: "Phone Number".to_string(),
            pattern: Regex::new(r"\b(\+?1[-.]?)?\(?\d{3}\)?[-.]?\d{3}[-.]?\d{4}\b").unwrap(),
            severity: Severity::Medium,
        });

        // Social Security Numbers
        patterns.push(PIIPattern {
            name: "Social Security Number".to_string(),
            pattern: Regex::new(r"\b\d{3}-\d{2}-\d{4}\b").unwrap(),
            severity: Severity::Critical,
        });

        // Credit card numbers (simple pattern)
        patterns.push(PIIPattern {
            name: "Credit Card Number".to_string(),
            pattern: Regex::new(r"\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b").unwrap(),
            severity: Severity::Critical,
        });

        // Addresses
        patterns.push(PIIPattern {
            name: "Street Address".to_string(),
            pattern: Regex::new(r"\b\d{1,5}\s+[A-Z][a-z]+\s+(Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd)\b").unwrap(),
            severity: Severity::Medium,
        });

        // IP Addresses (might be PII in some contexts)
        patterns.push(PIIPattern {
            name: "IP Address".to_string(),
            pattern: Regex::new(r"\b(?:\d{1,3}\.){3}\d{1,3}\b").unwrap(),
            severity: Severity::Low,
        });

        // Names (simple pattern - first and last name)
        patterns.push(PIIPattern {
            name: "Full Name Pattern".to_string(),
            pattern: Regex::new(r"\b[A-Z][a-z]+\s+[A-Z][a-z]+\b").unwrap(),
            severity: Severity::Medium,
        });

        PIIDetector { patterns }
    }

    pub fn scan_text(&self, text: &str) -> Vec<(String, String, Severity)> {
        let mut findings = Vec::new();

        for pattern in &self.patterns {
            for matched in pattern.pattern.find_iter(text) {
                findings.push((
                    pattern.name.clone(),
                    matched.as_str().to_string(),
                    match pattern.severity {
                        Severity::Critical => Severity::Critical,
                        Severity::High => Severity::High,
                        Severity::Medium => Severity::Medium,
                        Severity::Low => Severity::Low,
                    },
                ));
            }
        }

        findings
    }

    pub fn scan_file(&self, file_path: &Path) -> Result<Vec<(String, String, Severity)>, std::io::Error> {
        let content = fs::read_to_string(file_path)?;
        Ok(self.scan_text(&content))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_detect_email() {
        let detector = PIIDetector::new();
        let text = "Contact student at john.doe@university.edu";
        let findings = detector.scan_text(text);

        assert!(findings.iter().any(|(name, _, _)| name == "Email Address"));
    }

    #[test]
    fn test_detect_ssn() {
        let detector = PIIDetector::new();
        let text = "SSN: 123-45-6789";
        let findings = detector.scan_text(text);

        assert!(findings.iter().any(|(name, _, severity)| 
            name == "Social Security Number" && *severity == Severity::Critical
        ));
    }

    #[test]
    fn test_detect_phone() {
        let detector = PIIDetector::new();
        let text = "Call me at (555) 123-4567";
        let findings = detector.scan_text(text);

        assert!(findings.iter().any(|(name, _, _)| name == "Phone Number"));
    }

    #[test]
    fn test_no_false_positives_on_hashes() {
        let detector = PIIDetector::new();
        // SHA-256 hash should not be detected as PII
        let text = "Hash: a3c5e7f9d1b2e4a6c8f0e2d4b6a8c0e2f4d6b8a0c2e4f6d8b0a2c4e6f8d0b2a4";
        let findings = detector.scan_text(text);

        // Should not detect SSN or credit card in hash
        assert!(!findings.iter().any(|(name, _, severity)| 
            *severity == Severity::Critical
        ));
    }

    #[test]
    fn test_anonymized_student_id() {
        let detector = PIIDetector::new();
        // Hashed/anonymized IDs should be safe
        let text = "Student ID: sha256:9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08";
        let findings = detector.scan_text(text);

        // Should not match simple numeric pattern due to hash prefix
        // This tests that our anonymization approach works
        let high_findings: Vec<_> = findings.iter()
            .filter(|(_, matched, _)| matched.contains("9f86d081"))
            .collect();

        assert_eq!(high_findings.len(), 0, "Hashed IDs should not be detected as numeric student IDs");
    }
}

fn main() {
    println!("PII Leakage Detection Test Suite");
    println!("=================================\n");

    let detector = PIIDetector::new();

    // Example test cases
    let test_cases = vec![
        ("Safe: Student sha256:abc123", "Should be safe (anonymized)"),
        ("Unsafe: Student ID 12345678", "Should detect student ID"),
        ("Email: student@university.edu", "Should detect email"),
        ("Phone: (555) 123-4567", "Should detect phone number"),
        ("Address: 123 Main Street", "Should detect address"),
    ];

    let mut total_findings = 0;

    for (text, description) in test_cases {
        println!("Test: {}", description);
        println!("Text: {}", text);

        let findings = detector.scan_text(text);

        if findings.is_empty() {
            println!("✓ No PII detected\n");
        } else {
            println!("✗ PII detected:");
            for (name, matched, severity) in findings {
                println!("  - {}: {} ({:?})", name, matched, severity);
                total_findings += 1;
            }
            println!();
        }
    }

    println!("=================================");
    println!("Total PII instances found: {}", total_findings);

    if total_findings > 0 {
        std::process::exit(1);
    }
}
