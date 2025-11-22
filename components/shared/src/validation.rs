//! Input validation utilities for the Academic Workflow Suite.
//!
//! This module provides validation functions for various types of academic
//! and UK-specific data formats including:
//! - Email addresses
//! - UK phone numbers
//! - Open University student IDs
//! - Open University module codes
//! - UK postcodes
//! - URLs

use crate::errors::{Result, SharedError, ValidationError};
use lazy_static::lazy_static;
use regex::Regex;

lazy_static! {
    /// Regex for UK phone numbers (landline and mobile)
    static ref UK_PHONE_REGEX: Regex = Regex::new(
        r"^(?:(?:\+44\s?|0)(?:\d{2}\s?\d{4}\s?\d{4}|\d{3}\s?\d{3}\s?\d{4}|\d{4}\s?\d{6}))$"
    ).unwrap();

    /// Regex for OU student ID format (e.g., A1234567, B9876543)
    static ref OU_STUDENT_ID_REGEX: Regex = Regex::new(
        r"^[A-Z]\d{7}$"
    ).unwrap();

    /// Regex for OU module code format (e.g., TM112, M250, TT284)
    static ref OU_MODULE_CODE_REGEX: Regex = Regex::new(
        r"^[A-Z]{1,3}\d{3}$"
    ).unwrap();

    /// Regex for UK postcode format
    static ref UK_POSTCODE_REGEX: Regex = Regex::new(
        r"^([A-Z]{1,2}\d{1,2}[A-Z]?)\s?(\d[A-Z]{2})$"
    ).unwrap();

    /// Regex for valid URLs
    static ref URL_REGEX: Regex = Regex::new(
        r"^https?://[^\s/$.?#].[^\s]*$"
    ).unwrap();
}

/// Validate an email address.
///
/// # Examples
///
/// ```
/// use academic_shared::validation::validate_email;
///
/// assert!(validate_email("user@example.com").is_ok());
/// assert!(validate_email("invalid").is_err());
/// ```
pub fn validate_email(email: &str) -> Result<()> {
    // Trim whitespace
    let email = email.trim();

    // Check length
    if email.is_empty() {
        return Err(SharedError::Validation(ValidationError::InvalidEmail {
            value: email.to_string(),
            reason: "Email cannot be empty".to_string(),
        }));
    }

    if email.len() > 254 {
        return Err(SharedError::Validation(ValidationError::InvalidEmail {
            value: email.to_string(),
            reason: "Email is too long (maximum 254 characters)".to_string(),
        }));
    }

    // Use email_address crate for robust validation
    if email_address::EmailAddress::is_valid(email) {
        Ok(())
    } else {
        Err(SharedError::Validation(ValidationError::InvalidEmail {
            value: email.to_string(),
            reason: "Invalid email format".to_string(),
        }))
    }
}

/// Validate a UK phone number.
///
/// Accepts various formats:
/// - +44 20 1234 5678
/// - 020 1234 5678
/// - 07123 456789
///
/// # Examples
///
/// ```
/// use academic_shared::validation::validate_uk_phone;
///
/// assert!(validate_uk_phone("+44 20 1234 5678").is_ok());
/// assert!(validate_uk_phone("07123456789").is_ok());
/// assert!(validate_uk_phone("invalid").is_err());
/// ```
pub fn validate_uk_phone(phone: &str) -> Result<()> {
    // Remove common separators for validation
    let normalized = phone
        .replace(' ', "")
        .replace('-', "")
        .replace('(', "")
        .replace(')', "");

    if normalized.is_empty() {
        return Err(SharedError::Validation(ValidationError::InvalidPhoneNumber {
            value: phone.to_string(),
            reason: "Phone number cannot be empty".to_string(),
        }));
    }

    // Check if it starts with +44 or 0
    if !normalized.starts_with("+44") && !normalized.starts_with('0') {
        return Err(SharedError::Validation(ValidationError::InvalidPhoneNumber {
            value: phone.to_string(),
            reason: "UK phone numbers must start with +44 or 0".to_string(),
        }));
    }

    // Validate length (UK numbers are typically 10-11 digits)
    let digit_count = normalized.chars().filter(|c| c.is_ascii_digit()).count();
    if digit_count < 10 || digit_count > 13 {
        return Err(SharedError::Validation(ValidationError::InvalidPhoneNumber {
            value: phone.to_string(),
            reason: format!("Invalid length (found {} digits)", digit_count),
        }));
    }

    // Additional validation for common UK formats
    if normalized.starts_with("+44") {
        // International format
        let without_prefix = &normalized[3..];
        if without_prefix.is_empty() || without_prefix.starts_with('0') {
            return Err(SharedError::Validation(ValidationError::InvalidPhoneNumber {
                value: phone.to_string(),
                reason: "Number after +44 should not start with 0".to_string(),
            }));
        }
    } else if normalized.starts_with('0') {
        // National format
        if normalized.len() != 10 && normalized.len() != 11 {
            return Err(SharedError::Validation(ValidationError::InvalidPhoneNumber {
                value: phone.to_string(),
                reason: "UK national format should be 10 or 11 digits".to_string(),
            }));
        }
    }

    Ok(())
}

/// Validate an Open University student ID.
///
/// Format: Single uppercase letter followed by 7 digits (e.g., A1234567)
///
/// # Examples
///
/// ```
/// use academic_shared::validation::validate_ou_student_id;
///
/// assert!(validate_ou_student_id("A1234567").is_ok());
/// assert!(validate_ou_student_id("B9876543").is_ok());
/// assert!(validate_ou_student_id("12345678").is_err());
/// assert!(validate_ou_student_id("AB123456").is_err());
/// ```
pub fn validate_ou_student_id(student_id: &str) -> Result<()> {
    let student_id = student_id.trim().to_uppercase();

    if student_id.is_empty() {
        return Err(SharedError::Validation(ValidationError::InvalidStudentId {
            value: student_id,
            reason: "Student ID cannot be empty".to_string(),
        }));
    }

    if !OU_STUDENT_ID_REGEX.is_match(&student_id) {
        return Err(SharedError::Validation(ValidationError::InvalidStudentId {
            value: student_id,
            reason: "Student ID must be one uppercase letter followed by 7 digits (e.g., A1234567)".to_string(),
        }));
    }

    Ok(())
}

/// Validate an Open University module code.
///
/// Format: 1-3 uppercase letters followed by 3 digits (e.g., TM112, M250, TT284)
///
/// # Examples
///
/// ```
/// use academic_shared::validation::validate_ou_module_code;
///
/// assert!(validate_ou_module_code("TM112").is_ok());
/// assert!(validate_ou_module_code("M250").is_ok());
/// assert!(validate_ou_module_code("TT284").is_ok());
/// assert!(validate_ou_module_code("ABCD123").is_err());
/// assert!(validate_ou_module_code("A12").is_err());
/// ```
pub fn validate_ou_module_code(module_code: &str) -> Result<()> {
    let module_code = module_code.trim().to_uppercase();

    if module_code.is_empty() {
        return Err(SharedError::Validation(ValidationError::InvalidModuleCode {
            value: module_code,
            reason: "Module code cannot be empty".to_string(),
        }));
    }

    if !OU_MODULE_CODE_REGEX.is_match(&module_code) {
        return Err(SharedError::Validation(ValidationError::InvalidModuleCode {
            value: module_code,
            reason: "Module code must be 1-3 uppercase letters followed by 3 digits (e.g., TM112, M250)".to_string(),
        }));
    }

    Ok(())
}

/// Validate a UK postcode.
///
/// # Examples
///
/// ```
/// use academic_shared::validation::validate_uk_postcode;
///
/// assert!(validate_uk_postcode("SW1A 1AA").is_ok());
/// assert!(validate_uk_postcode("M1 1AE").is_ok());
/// assert!(validate_uk_postcode("CR2 6XH").is_ok());
/// assert!(validate_uk_postcode("invalid").is_err());
/// ```
pub fn validate_uk_postcode(postcode: &str) -> Result<()> {
    let postcode = postcode.trim().to_uppercase();

    if postcode.is_empty() {
        return Err(SharedError::Validation(ValidationError::InvalidPostcode {
            value: postcode,
            reason: "Postcode cannot be empty".to_string(),
        }));
    }

    // Remove spaces for validation
    let normalized = postcode.replace(' ', "");

    // UK postcodes are typically 6-8 characters (excluding space)
    if normalized.len() < 5 || normalized.len() > 8 {
        return Err(SharedError::Validation(ValidationError::InvalidPostcode {
            value: postcode,
            reason: "Postcode length is invalid".to_string(),
        }));
    }

    if !UK_POSTCODE_REGEX.is_match(&postcode) {
        return Err(SharedError::Validation(ValidationError::InvalidPostcode {
            value: postcode,
            reason: "Invalid UK postcode format".to_string(),
        }));
    }

    Ok(())
}

/// Validate a URL.
///
/// # Examples
///
/// ```
/// use academic_shared::validation::validate_url;
///
/// assert!(validate_url("https://www.example.com").is_ok());
/// assert!(validate_url("http://localhost:8080/path").is_ok());
/// assert!(validate_url("not-a-url").is_err());
/// ```
pub fn validate_url(url: &str) -> Result<()> {
    let url = url.trim();

    if url.is_empty() {
        return Err(SharedError::Validation(ValidationError::InvalidUrl {
            value: url.to_string(),
            reason: "URL cannot be empty".to_string(),
        }));
    }

    // Use url crate for robust validation
    match url::Url::parse(url) {
        Ok(parsed) => {
            // Ensure it's HTTP or HTTPS
            let scheme = parsed.scheme();
            if scheme != "http" && scheme != "https" {
                return Err(SharedError::Validation(ValidationError::InvalidUrl {
                    value: url.to_string(),
                    reason: format!("URL must use http or https scheme, not '{}'", scheme),
                }));
            }
            Ok(())
        }
        Err(e) => Err(SharedError::Validation(ValidationError::InvalidUrl {
            value: url.to_string(),
            reason: format!("Invalid URL: {}", e),
        })),
    }
}

/// Validate string length.
///
/// # Examples
///
/// ```
/// use academic_shared::validation::validate_length;
///
/// assert!(validate_length("hello", "name", 1, 10).is_ok());
/// assert!(validate_length("", "name", 1, 10).is_err());
/// assert!(validate_length("too long string", "name", 1, 5).is_err());
/// ```
pub fn validate_length(value: &str, field: &str, min: usize, max: usize) -> Result<()> {
    let len = value.len();

    if len < min {
        return Err(SharedError::Validation(ValidationError::TooShort {
            field: field.to_string(),
            min_length: min,
            actual_length: len,
        }));
    }

    if len > max {
        return Err(SharedError::Validation(ValidationError::TooLong {
            field: field.to_string(),
            max_length: max,
            actual_length: len,
        }));
    }

    Ok(())
}

/// Validate that a value is not empty.
///
/// # Examples
///
/// ```
/// use academic_shared::validation::validate_not_empty;
///
/// assert!(validate_not_empty("hello", "name").is_ok());
/// assert!(validate_not_empty("", "name").is_err());
/// assert!(validate_not_empty("   ", "name").is_err());
/// ```
pub fn validate_not_empty(value: &str, field: &str) -> Result<()> {
    if value.trim().is_empty() {
        return Err(SharedError::Validation(ValidationError::Missing {
            field: field.to_string(),
        }));
    }
    Ok(())
}

/// Validate that a numeric value is within range.
///
/// # Examples
///
/// ```
/// use academic_shared::validation::validate_range;
///
/// assert!(validate_range(5, "score", 0, 100).is_ok());
/// assert!(validate_range(-1, "score", 0, 100).is_err());
/// assert!(validate_range(101, "score", 0, 100).is_err());
/// ```
pub fn validate_range(value: i64, field: &str, min: i64, max: i64) -> Result<()> {
    if value < min || value > max {
        return Err(SharedError::Validation(ValidationError::OutOfRange {
            field: field.to_string(),
            min,
            max,
            actual: value,
        }));
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validate_email() {
        // Valid emails
        assert!(validate_email("user@example.com").is_ok());
        assert!(validate_email("john.doe@university.ac.uk").is_ok());
        assert!(validate_email("student+tag@open.ac.uk").is_ok());

        // Invalid emails
        assert!(validate_email("").is_err());
        assert!(validate_email("invalid").is_err());
        assert!(validate_email("@example.com").is_err());
        assert!(validate_email("user@").is_err());
        assert!(validate_email("user @example.com").is_err());
    }

    #[test]
    fn test_validate_uk_phone() {
        // Valid UK phone numbers
        assert!(validate_uk_phone("02012345678").is_ok());
        assert!(validate_uk_phone("07123456789").is_ok());
        assert!(validate_uk_phone("+442012345678").is_ok());
        assert!(validate_uk_phone("020 1234 5678").is_ok());
        assert!(validate_uk_phone("+44 20 1234 5678").is_ok());

        // Invalid phone numbers
        assert!(validate_uk_phone("").is_err());
        assert!(validate_uk_phone("123").is_err());
        assert!(validate_uk_phone("invalid").is_err());
        assert!(validate_uk_phone("+1234567890").is_err());
    }

    #[test]
    fn test_validate_ou_student_id() {
        // Valid student IDs
        assert!(validate_ou_student_id("A1234567").is_ok());
        assert!(validate_ou_student_id("B9876543").is_ok());
        assert!(validate_ou_student_id("Z0000000").is_ok());
        assert!(validate_ou_student_id("a1234567").is_ok()); // lowercase converted

        // Invalid student IDs
        assert!(validate_ou_student_id("").is_err());
        assert!(validate_ou_student_id("12345678").is_err());
        assert!(validate_ou_student_id("AB123456").is_err());
        assert!(validate_ou_student_id("A123456").is_err()); // too short
        assert!(validate_ou_student_id("A12345678").is_err()); // too long
    }

    #[test]
    fn test_validate_ou_module_code() {
        // Valid module codes
        assert!(validate_ou_module_code("TM112").is_ok());
        assert!(validate_ou_module_code("M250").is_ok());
        assert!(validate_ou_module_code("TT284").is_ok());
        assert!(validate_ou_module_code("tm112").is_ok()); // lowercase converted

        // Invalid module codes
        assert!(validate_ou_module_code("").is_err());
        assert!(validate_ou_module_code("ABCD123").is_err()); // too many letters
        assert!(validate_ou_module_code("A12").is_err()); // too few digits
        assert!(validate_ou_module_code("A1234").is_err()); // too many digits
        assert!(validate_ou_module_code("123").is_err()); // no letters
    }

    #[test]
    fn test_validate_uk_postcode() {
        // Valid postcodes
        assert!(validate_uk_postcode("SW1A 1AA").is_ok());
        assert!(validate_uk_postcode("M1 1AE").is_ok());
        assert!(validate_uk_postcode("CR2 6XH").is_ok());
        assert!(validate_uk_postcode("DN55 1PT").is_ok());
        assert!(validate_uk_postcode("sw1a1aa").is_ok()); // lowercase converted

        // Invalid postcodes
        assert!(validate_uk_postcode("").is_err());
        assert!(validate_uk_postcode("invalid").is_err());
        assert!(validate_uk_postcode("A").is_err());
        assert!(validate_uk_postcode("12345").is_err());
    }

    #[test]
    fn test_validate_url() {
        // Valid URLs
        assert!(validate_url("https://www.example.com").is_ok());
        assert!(validate_url("http://localhost:8080").is_ok());
        assert!(validate_url("https://open.ac.uk/path?query=value").is_ok());

        // Invalid URLs
        assert!(validate_url("").is_err());
        assert!(validate_url("not-a-url").is_err());
        assert!(validate_url("ftp://example.com").is_err()); // wrong scheme
        assert!(validate_url("//example.com").is_err());
    }

    #[test]
    fn test_validate_length() {
        assert!(validate_length("hello", "name", 1, 10).is_ok());
        assert!(validate_length("a", "name", 1, 10).is_ok());
        assert!(validate_length("", "name", 1, 10).is_err());
        assert!(validate_length("this is too long", "name", 1, 5).is_err());
    }

    #[test]
    fn test_validate_not_empty() {
        assert!(validate_not_empty("hello", "name").is_ok());
        assert!(validate_not_empty("", "name").is_err());
        assert!(validate_not_empty("   ", "name").is_err());
        assert!(validate_not_empty("\t\n", "name").is_err());
    }

    #[test]
    fn test_validate_range() {
        assert!(validate_range(50, "score", 0, 100).is_ok());
        assert!(validate_range(0, "score", 0, 100).is_ok());
        assert!(validate_range(100, "score", 0, 100).is_ok());
        assert!(validate_range(-1, "score", 0, 100).is_err());
        assert!(validate_range(101, "score", 0, 100).is_err());
    }
}
