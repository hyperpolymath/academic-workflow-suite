//! Integration tests for the academic-shared library.
//!
//! These tests verify that all modules work correctly together.

use academic_shared::{
    crypto::*, errors::*, logging::*, sanitization::*, testing::*, time::*, validation::*,
};
use chrono::{NaiveDate, Utc};
use std::collections::HashMap;

#[test]
fn test_crypto_module_integration() {
    // Test hashing
    let data = b"integration test data";
    let hash256 = sha3_256_hex(data);
    let hash512 = sha3_512_hex(data);

    assert_eq!(hash256.len(), 64);
    assert_eq!(hash512.len(), 128);

    // Test HMAC
    let key = b"secret-key";
    let mac = hmac_sha3_256(key, data).unwrap();
    assert!(verify_hmac_sha3_256(key, data, &mac).unwrap());

    // Test ID generation
    let uuid = generate_uuid();
    let nanoid = generate_nanoid();
    assert_eq!(uuid.len(), 36);
    assert_eq!(nanoid.len(), 21);

    // Test key derivation
    let password = b"test-password";
    let salt = generate_salt(16);
    let key = derive_key(password, &salt, 10000, 32);
    assert_eq!(key.len(), 32);
}

#[test]
fn test_validation_module_integration() {
    // Test valid inputs
    assert!(validate_email("student@open.ac.uk").is_ok());
    assert!(validate_uk_phone("07123456789").is_ok());
    assert!(validate_ou_student_id("A1234567").is_ok());
    assert!(validate_ou_module_code("TM112").is_ok());
    assert!(validate_uk_postcode("MK7 6AA").is_ok());
    assert!(validate_url("https://www.open.ac.uk").is_ok());

    // Test invalid inputs return proper errors
    assert!(validate_email("invalid").is_err());
    assert!(validate_uk_phone("123").is_err());
    assert!(validate_ou_student_id("123").is_err());
    assert!(validate_ou_module_code("INVALID").is_err());
    assert!(validate_uk_postcode("invalid").is_err());
    assert!(validate_url("not-a-url").is_err());
}

#[test]
fn test_sanitization_module_integration() {
    // Test HTML sanitization
    let dangerous = "<script>alert('xss')</script><p>Safe content</p>";
    let clean = sanitize_html(dangerous);
    assert!(!clean.contains("<script>"));

    // Test SQL sanitization
    let sql_input = "user'; DROP TABLE users--";
    let clean = sanitize_sql_input(sql_input);
    assert!(!clean.contains("--"));

    // Test filename sanitization
    let filename = "../../../etc/passwd";
    let clean = sanitize_filename(filename);
    assert!(!clean.contains('/'));
    assert!(!clean.contains(".."));

    // Test Unicode normalization
    let unicode = "Café";
    let normalized = normalize_unicode(unicode);
    assert_eq!(normalized.len(), unicode.len());
}

#[test]
fn test_time_module_integration() {
    // Test timezone conversion
    let utc_time = now_utc();
    let uk_time = utc_to_uk(&utc_time);
    let back_to_utc = uk_to_utc(&uk_time);
    assert_eq!(utc_time.timestamp(), back_to_utc.timestamp());

    // Test academic year calculations
    let date = NaiveDate::from_ymd_opt(2024, 10, 1).unwrap();
    let year = get_academic_year(&date);
    assert_eq!(year, 2024);
    assert_eq!(format_academic_year(year), "2024/2025");

    // Test deadline calculations
    let future = Utc::now() + chrono::Duration::days(5);
    assert!(!is_overdue(&future));
    assert!(is_deadline_soon(&future, 7));

    // Test semester detection
    let autumn = NaiveDate::from_ymd_opt(2024, 10, 15).unwrap();
    assert_eq!(get_current_semester(&autumn), "Autumn");
}

#[test]
fn test_logging_module_integration() {
    // Test audit log creation
    let mut metadata = HashMap::new();
    metadata.insert("action_type".to_string(), "test".to_string());

    let entry = create_audit_log(
        Some("user123"),
        "test_action",
        Some("test_resource"),
        AuditResult::Success,
        metadata,
        Some("192.168.1.100"),
    );

    assert_eq!(entry.action, "test_action");
    assert_eq!(entry.result, AuditResult::Success);

    // Test audit log formatting
    let json = format_audit_log(&entry).unwrap();
    assert!(json.contains("\"action\":\"test_action\""));

    // Test PII redaction
    let redacted = redact_user_id("user12345");
    assert_eq!(redacted, "u*******5");

    let redacted_ip = redact_ip_address("192.168.1.100");
    assert!(redacted_ip.contains("***"));

    // Test log message sanitization
    let msg = "User user@example.com logged in";
    let sanitized = sanitize_log_message(msg);
    assert!(sanitized.contains("[EMAIL_REDACTED]"));
}

#[test]
fn test_testing_module_integration() {
    // Test mock data generation
    let email = mock_email();
    assert!(validate_email(&email).is_ok());

    let student_id = mock_student_id();
    assert!(validate_ou_student_id(&student_id).is_ok());

    let module_code = mock_module_code();
    assert!(validate_ou_module_code(&module_code).is_ok());

    let phone = mock_uk_phone();
    assert!(validate_uk_phone(&phone).is_ok());

    let postcode = mock_uk_postcode();
    assert!(validate_uk_postcode(&postcode).is_ok());

    // Test mock structures
    let user = MockUser::new();
    assert!(validate_ou_student_id(&user.student_id).is_ok());
    assert!(validate_email(&user.email).is_ok());

    let module = MockModule::new();
    assert!(!module.code.is_empty());
    assert!(!module.title.is_empty());
}

#[test]
fn test_error_handling_integration() {
    // Test validation error creation and formatting
    let error = SharedError::Validation(ValidationError::InvalidEmail {
        value: "invalid".to_string(),
        reason: "missing @ symbol".to_string(),
    });

    let user_msg = user_friendly_message(&error);
    assert_eq!(user_msg, "Please enter a valid email address.");

    // Test error display with PII redaction
    let error_str = error.to_string();
    assert!(error_str.contains("Validation error"));

    // Test error cloning
    let cloned = error.clone();
    assert_eq!(error, cloned);
}

#[test]
fn test_cross_module_workflow() {
    // Simulate a complete workflow using multiple modules

    // 1. Generate mock data
    let user = MockUser::new();

    // 2. Validate the data
    assert!(validate_ou_student_id(&user.student_id).is_ok());
    assert!(validate_email(&user.email).is_ok());
    assert!(validate_uk_phone(&user.phone).is_ok());

    // 3. Sanitize user input (simulate HTML input)
    let user_input = "<p>My assignment is complete!</p><script>alert('xss')</script>";
    let clean_input = sanitize_html(user_input);
    assert!(!clean_input.contains("<script>"));

    // 4. Generate a secure ID for the session
    let session_id = generate_uuid();
    assert_eq!(session_id.len(), 36);

    // 5. Create an audit log entry
    let mut metadata = HashMap::new();
    metadata.insert("user_agent".to_string(), "test-agent".to_string());

    let audit_entry = create_audit_log(
        Some(&user.student_id),
        "submit_assignment",
        Some("assignment_system"),
        AuditResult::Success,
        metadata,
        Some("192.168.1.100"),
    );

    // 6. Format audit log as JSON
    let audit_json = format_audit_log(&audit_entry).unwrap();
    assert!(audit_json.contains("submit_assignment"));

    // 7. Work with dates
    let submission_date = mock_academic_date(2024);
    let academic_year = get_academic_year(&submission_date);
    let semester = get_current_semester(&submission_date);

    assert!(academic_year == 2024 || academic_year == 2023);
    assert!(["Autumn", "Spring", "Summer"].contains(&semester));
}

#[test]
fn test_security_features() {
    // Test constant-time comparison
    let secret1 = b"secret-token-12345";
    let secret2 = b"secret-token-12345";
    let secret3 = b"different-token-12";

    assert!(constant_time_compare(secret1, secret2));
    assert!(!constant_time_compare(secret1, secret3));

    // Test HMAC verification (prevents timing attacks)
    let key = b"hmac-secret-key";
    let data = b"important-data";
    let mac = hmac_sha3_256(key, data).unwrap();

    assert!(verify_hmac_sha3_256(key, data, &mac).unwrap());
    assert!(!verify_hmac_sha3_256(b"wrong-key", data, &mac).unwrap());

    // Test path traversal prevention
    let result = sanitize_path("../../../etc/passwd", "/var/www/uploads");
    assert!(result.is_err());

    let result = sanitize_path("uploads/file.txt", "/var/www");
    assert!(result.is_ok());

    // Test PII redaction
    let sensitive_email = "student@university.ac.uk";
    let redacted = redact_pii(sensitive_email);
    assert!(redacted.contains("***"));
    assert!(!redacted.contains("student"));
}

#[test]
fn test_validation_with_sanitization() {
    // Test that validation and sanitization work together

    // Email: validate then use
    let email_input = "  test@example.com  ";
    assert!(validate_email(email_input).is_ok());

    // SQL: sanitize before use
    let user_input = "test'; DROP TABLE--";
    let sanitized = sanitize_sql_input(user_input);
    assert!(!sanitized.contains("--"));
    assert!(!sanitized.contains(';'));

    // Filename: sanitize then validate length
    let filename = "<>:invalid?.txt";
    let clean = sanitize_filename(filename);
    assert!(validate_length(&clean, "filename", 1, 255).is_ok());
}

#[test]
fn test_datetime_and_logging() {
    // Test that time utilities work with logging

    let now = now_utc();
    let formatted = format_iso8601(&now);

    // Use in audit log
    let entry = create_audit_log(
        Some("user123"),
        "test_action",
        None,
        AuditResult::Success,
        HashMap::new(),
        None,
    );

    // Verify timestamp format (RFC3339)
    assert!(entry.timestamp.contains('T'));
    // May end with Z or +00:00 depending on chrono version
    assert!(entry.timestamp.contains('Z') || entry.timestamp.contains("+00:00"));

    // Parse it back
    let parsed = parse_iso8601(&entry.timestamp).unwrap();
    assert!(parsed.timestamp() > 0);
}

#[test]
fn test_comprehensive_validation_suite() {
    // Test all validation functions with various inputs

    // Email validation
    let valid_emails = vec![
        "user@example.com",
        "student@open.ac.uk",
        "test.user+tag@university.edu",
    ];
    for email in valid_emails {
        assert!(validate_email(email).is_ok(), "Failed to validate: {}", email);
    }

    // Student ID validation
    let valid_ids = vec!["A1234567", "B9876543", "Z0000000"];
    for id in valid_ids {
        assert!(
            validate_ou_student_id(id).is_ok(),
            "Failed to validate: {}",
            id
        );
    }

    // Module code validation
    let valid_codes = vec!["TM112", "M250", "TT284", "A123"];
    for code in valid_codes {
        assert!(
            validate_ou_module_code(code).is_ok(),
            "Failed to validate: {}",
            code
        );
    }

    // URL validation
    let valid_urls = vec![
        "https://www.open.ac.uk",
        "http://localhost:8080",
        "https://api.example.com/v1/users",
    ];
    for url in valid_urls {
        assert!(validate_url(url).is_ok(), "Failed to validate: {}", url);
    }
}

#[test]
fn test_error_messages_are_helpful() {
    // Ensure error messages provide useful information

    let errors = vec![
        SharedError::Validation(ValidationError::InvalidEmail {
            value: "bad".to_string(),
            reason: "missing @".to_string(),
        }),
        SharedError::Validation(ValidationError::TooShort {
            field: "password".to_string(),
            min_length: 8,
            actual_length: 4,
        }),
        SharedError::Validation(ValidationError::Missing {
            field: "username".to_string(),
        }),
    ];

    for error in errors {
        let msg = user_friendly_message(&error);
        assert!(!msg.is_empty());
        assert!(!msg.contains("Error")); // Should be user-friendly, not technical
    }
}
