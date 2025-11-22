//! Shared error types and utilities for the Academic Workflow Suite.
//!
//! This module provides a comprehensive set of error types that can be used
//! across all components of the suite, ensuring consistent error handling
//! and user-friendly error messages.

use std::fmt;
use thiserror::Error;

/// Result type alias using our shared error type.
pub type Result<T> = std::result::Result<T, SharedError>;

/// Main error type for the shared utilities library.
#[derive(Error, Debug, Clone, PartialEq)]
pub enum SharedError {
    /// Cryptographic operation failed
    #[error("Cryptographic error: {0}")]
    Crypto(String),

    /// Validation failed
    #[error("Validation error: {0}")]
    Validation(ValidationError),

    /// Sanitization failed
    #[error("Sanitization error: {0}")]
    Sanitization(String),

    /// Time/date operation failed
    #[error("Time error: {0}")]
    Time(String),

    /// I/O operation failed
    #[error("I/O error: {0}")]
    Io(String),

    /// Configuration error
    #[error("Configuration error: {0}")]
    Config(String),

    /// Generic error with custom message
    #[error("{0}")]
    Generic(String),
}

/// Specific validation errors with detailed context.
#[derive(Debug, Clone, PartialEq)]
pub enum ValidationError {
    /// Invalid email address format
    InvalidEmail { value: String, reason: String },

    /// Invalid phone number format
    InvalidPhoneNumber { value: String, reason: String },

    /// Invalid OU student ID format
    InvalidStudentId { value: String, reason: String },

    /// Invalid OU module code format
    InvalidModuleCode { value: String, reason: String },

    /// Invalid UK postcode format
    InvalidPostcode { value: String, reason: String },

    /// Invalid URL format
    InvalidUrl { value: String, reason: String },

    /// Value too short
    TooShort {
        field: String,
        min_length: usize,
        actual_length: usize,
    },

    /// Value too long
    TooLong {
        field: String,
        max_length: usize,
        actual_length: usize,
    },

    /// Value out of range
    OutOfRange {
        field: String,
        min: i64,
        max: i64,
        actual: i64,
    },

    /// Required field is missing
    Missing { field: String },

    /// Invalid format
    InvalidFormat { field: String, expected: String },

    /// Custom validation error
    Custom(String),
}

impl fmt::Display for ValidationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ValidationError::InvalidEmail { value, reason } => {
                write!(f, "Invalid email '{}': {}", redact_pii(value), reason)
            }
            ValidationError::InvalidPhoneNumber { value, reason } => {
                write!(f, "Invalid phone number '{}': {}", redact_pii(value), reason)
            }
            ValidationError::InvalidStudentId { value, reason } => {
                write!(f, "Invalid student ID '{}': {}", redact_pii(value), reason)
            }
            ValidationError::InvalidModuleCode { value, reason } => {
                write!(f, "Invalid module code '{}': {}", value, reason)
            }
            ValidationError::InvalidPostcode { value, reason } => {
                write!(f, "Invalid postcode '{}': {}", value, reason)
            }
            ValidationError::InvalidUrl { value, reason } => {
                write!(f, "Invalid URL '{}': {}", value, reason)
            }
            ValidationError::TooShort {
                field,
                min_length,
                actual_length,
            } => {
                write!(
                    f,
                    "Field '{}' is too short (minimum: {}, actual: {})",
                    field, min_length, actual_length
                )
            }
            ValidationError::TooLong {
                field,
                max_length,
                actual_length,
            } => {
                write!(
                    f,
                    "Field '{}' is too long (maximum: {}, actual: {})",
                    field, max_length, actual_length
                )
            }
            ValidationError::OutOfRange {
                field,
                min,
                max,
                actual,
            } => {
                write!(
                    f,
                    "Field '{}' is out of range (min: {}, max: {}, actual: {})",
                    field, min, max, actual
                )
            }
            ValidationError::Missing { field } => {
                write!(f, "Required field '{}' is missing", field)
            }
            ValidationError::InvalidFormat { field, expected } => {
                write!(f, "Field '{}' has invalid format (expected: {})", field, expected)
            }
            ValidationError::Custom(msg) => write!(f, "{}", msg),
        }
    }
}

impl std::error::Error for ValidationError {}

/// Redact personally identifiable information for safe logging.
///
/// This function masks part of the input to prevent PII leakage in logs.
///
/// # Examples
///
/// ```
/// use academic_shared::errors::redact_pii;
///
/// assert_eq!(redact_pii("user@example.com"), "u***@example.com");
/// assert_eq!(redact_pii("short"), "s***t");
/// ```
pub fn redact_pii(value: &str) -> String {
    if value.is_empty() {
        return String::from("[empty]");
    }

    if value.len() <= 2 {
        return "***".to_string();
    }

    // For email addresses, show first char and domain
    if let Some(at_pos) = value.find('@') {
        let first = value.chars().next().unwrap();
        let domain = &value[at_pos..];
        return format!("{}***{}", first, domain);
    }

    // For other values, show first and last char
    let first = value.chars().next().unwrap();
    let last = value.chars().last().unwrap();
    format!("{}***{}", first, last)
}

/// Convert an error into a user-friendly message.
///
/// This function removes technical details and provides clear,
/// actionable error messages for end users.
pub fn user_friendly_message(error: &SharedError) -> String {
    match error {
        SharedError::Crypto(_) => {
            "A security operation failed. Please try again or contact support.".to_string()
        }
        SharedError::Validation(ve) => match ve {
            ValidationError::InvalidEmail { .. } => {
                "Please enter a valid email address.".to_string()
            }
            ValidationError::InvalidPhoneNumber { .. } => {
                "Please enter a valid UK phone number.".to_string()
            }
            ValidationError::InvalidStudentId { .. } => {
                "Please enter a valid OU student ID (e.g., A1234567).".to_string()
            }
            ValidationError::InvalidModuleCode { .. } => {
                "Please enter a valid OU module code (e.g., TM112, M250).".to_string()
            }
            ValidationError::InvalidPostcode { .. } => {
                "Please enter a valid UK postcode.".to_string()
            }
            ValidationError::InvalidUrl { .. } => {
                "Please enter a valid URL starting with http:// or https://.".to_string()
            }
            ValidationError::TooShort { field, min_length, .. } => {
                format!("{} must be at least {} characters long.", field, min_length)
            }
            ValidationError::TooLong { field, max_length, .. } => {
                format!("{} must be no more than {} characters long.", field, max_length)
            }
            ValidationError::Missing { field } => {
                format!("{} is required.", field)
            }
            _ => ve.to_string(),
        },
        SharedError::Sanitization(_) => {
            "Invalid input detected. Please check your data and try again.".to_string()
        }
        SharedError::Time(msg) => {
            format!("Date/time error: {}", msg)
        }
        SharedError::Io(_) => {
            "An I/O operation failed. Please check permissions and try again.".to_string()
        }
        SharedError::Config(_) => {
            "Configuration error. Please check your settings.".to_string()
        }
        SharedError::Generic(msg) => msg.clone(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_redact_pii() {
        assert_eq!(redact_pii("user@example.com"), "u***@example.com");
        assert_eq!(redact_pii("testuser@domain.org"), "t***@domain.org");
        assert_eq!(redact_pii("short"), "s***t");
        assert_eq!(redact_pii("ab"), "***");
        assert_eq!(redact_pii(""), "[empty]");
    }

    #[test]
    fn test_validation_error_display() {
        let err = ValidationError::InvalidEmail {
            value: "invalid".to_string(),
            reason: "missing @ symbol".to_string(),
        };
        assert!(err.to_string().contains("Invalid email"));
        assert!(err.to_string().contains("i***d"));
    }

    #[test]
    fn test_user_friendly_message() {
        let err = SharedError::Validation(ValidationError::InvalidEmail {
            value: "test".to_string(),
            reason: "test".to_string(),
        });
        let msg = user_friendly_message(&err);
        assert_eq!(msg, "Please enter a valid email address.");
    }

    #[test]
    fn test_error_clone() {
        let err1 = SharedError::Generic("test".to_string());
        let err2 = err1.clone();
        assert_eq!(err1, err2);
    }
}
