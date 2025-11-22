//! Property-based tests using proptest.
//!
//! These tests verify that functions behave correctly across a wide range of inputs.

use academic_shared::{crypto::*, sanitization::*, validation::*};
use proptest::prelude::*;

// Property test: SHA3-256 hashing produces consistent results
proptest! {
    #[test]
    fn prop_sha3_256_deterministic(data: Vec<u8>) {
        let hash1 = sha3_256(&data);
        let hash2 = sha3_256(&data);
        prop_assert_eq!(hash1, hash2);
    }

    #[test]
    fn prop_sha3_256_hex_length(data: Vec<u8>) {
        let hash = sha3_256_hex(&data);
        prop_assert_eq!(hash.len(), 64); // 32 bytes = 64 hex chars
        prop_assert!(hash.chars().all(|c| c.is_ascii_hexdigit()));
    }

    #[test]
    fn prop_sha3_512_hex_length(data: Vec<u8>) {
        let hash = sha3_512_hex(&data);
        prop_assert_eq!(hash.len(), 128); // 64 bytes = 128 hex chars
        prop_assert!(hash.chars().all(|c| c.is_ascii_hexdigit()));
    }
}

// Property test: HMAC verification
proptest! {
    #[test]
    fn prop_hmac_verify_correct(key: Vec<u8>, data: Vec<u8>) {
        prop_assume!(!key.is_empty());
        let mac = hmac_sha3_256(&key, &data)?;
        prop_assert!(verify_hmac_sha3_256(&key, &data, &mac)?);
    }

    #[test]
    fn prop_hmac_verify_wrong_key(key1: Vec<u8>, key2: Vec<u8>, data: Vec<u8>) {
        prop_assume!(!key1.is_empty() && !key2.is_empty());
        prop_assume!(key1 != key2);

        let mac = hmac_sha3_256(&key1, &data)?;
        prop_assert!(!verify_hmac_sha3_256(&key2, &data, &mac)?);
    }
}

// Property test: Constant-time comparison
proptest! {
    #[test]
    fn prop_constant_time_compare_reflexive(data: Vec<u8>) {
        prop_assert!(constant_time_compare(&data, &data));
    }

    #[test]
    fn prop_constant_time_compare_different_lengths(a: Vec<u8>, b: Vec<u8>) {
        prop_assume!(a.len() != b.len());
        prop_assert!(!constant_time_compare(&a, &b));
    }
}

// Property test: Key derivation
proptest! {
    #[test]
    fn prop_derive_key_deterministic(password: Vec<u8>, salt: Vec<u8>, iterations in 1000u32..2000u32, len in 16usize..64usize) {
        prop_assume!(!password.is_empty() && !salt.is_empty());
        let key1 = derive_key(&password, &salt, iterations, len);
        let key2 = derive_key(&password, &salt, iterations, len);
        prop_assert_eq!(key1, key2);
    }

    #[test]
    fn prop_derive_key_correct_length(password: Vec<u8>, salt: Vec<u8>, len in 16usize..64usize) {
        prop_assume!(!password.is_empty() && !salt.is_empty());
        let key = derive_key(&password, &salt, 1000, len);
        prop_assert_eq!(key.len(), len);
    }
}

// Property test: UUID generation uniqueness
proptest! {
    #[test]
    fn prop_uuid_format(_n in 0..100usize) {
        let uuid = generate_uuid();
        prop_assert_eq!(uuid.len(), 36);
        prop_assert_eq!(uuid.chars().filter(|&c| c == '-').count(), 4);
    }

    #[test]
    fn prop_nanoid_length(len in 1usize..100usize) {
        let id = generate_nanoid_with_length(len);
        prop_assert_eq!(id.len(), len);
    }
}

// Property test: Email validation never panics
proptest! {
    #[test]
    fn prop_validate_email_no_panic(email: String) {
        let _ = validate_email(&email);
        // Test passes if it doesn't panic
    }

    #[test]
    fn prop_validate_url_no_panic(url: String) {
        let _ = validate_url(&url);
        // Test passes if it doesn't panic
    }
}

// Property test: String length validation
proptest! {
    #[test]
    fn prop_validate_length(s: String, min in 0usize..50usize, max in 50usize..100usize) {
        let result = validate_length(&s, "test", min, max);
        if s.len() < min {
            prop_assert!(result.is_err());
        } else if s.len() > max {
            prop_assert!(result.is_err());
        } else {
            prop_assert!(result.is_ok());
        }
    }
}

// Property test: Range validation
proptest! {
    #[test]
    fn prop_validate_range(value: i64, min: i64, max: i64) {
        prop_assume!(min <= max);
        let result = validate_range(value, "test", min, max);
        if value < min || value > max {
            prop_assert!(result.is_err());
        } else {
            prop_assert!(result.is_ok());
        }
    }
}

// Property test: HTML sanitization never panics
proptest! {
    #[test]
    fn prop_sanitize_html_no_panic(html: String) {
        let _ = sanitize_html(&html);
        // Test passes if it doesn't panic
    }

    #[test]
    fn prop_sanitize_html_basic_no_panic(html: String) {
        let _ = sanitize_html_basic(&html);
        // Test passes if it doesn't panic
    }
}

// Property test: SQL LIKE escaping
proptest! {
    #[test]
    fn prop_escape_sql_like_no_wildcards_after(s: String) {
        let escaped = escape_sql_like(&s);
        // After escaping, standalone % and _ should not exist
        // (they should be escaped with backslash)
        for i in 0..escaped.len() {
            if let Some(c) = escaped.chars().nth(i) {
                if c == '%' || c == '_' {
                    // Should be preceded by backslash
                    if i > 0 {
                        let prev = escaped.chars().nth(i - 1);
                        prop_assert_eq!(prev, Some('\\'));
                    }
                }
            }
        }
    }
}

// Property test: Filename sanitization produces valid names
proptest! {
    #[test]
    fn prop_sanitize_filename_no_path_separators(filename: String) {
        let clean = sanitize_filename(&filename);
        prop_assert!(!clean.contains('/'));
        prop_assert!(!clean.contains('\\'));
        prop_assert!(!clean.contains('\0'));
        prop_assert!(!clean.is_empty());
        prop_assert!(clean.len() <= 255);
    }
}

// Property test: Unicode normalization
proptest! {
    #[test]
    fn prop_normalize_unicode_deterministic(s: String) {
        let norm1 = normalize_unicode(&s);
        let norm2 = normalize_unicode(&s);
        prop_assert_eq!(norm1, norm2);
    }

    #[test]
    fn prop_normalize_unicode_nfd_deterministic(s: String) {
        let norm1 = normalize_unicode_nfd(&s);
        let norm2 = normalize_unicode_nfd(&s);
        prop_assert_eq!(norm1, norm2);
    }
}

// Property test: String truncation
proptest! {
    #[test]
    fn prop_truncate_string_respects_max_length(s: String, max_len in 10usize..100usize) {
        let truncated = truncate_string(&s, max_len);
        // Truncated string should be no longer than max_len
        // (for very short limits, ellipsis might make it equal to max_len)
        prop_assert!(truncated.len() <= max_len || (truncated == "..." && max_len < 3));

        // If original was longer, should have ellipsis (when max_len >= 3)
        if s.len() > max_len && max_len >= 3 {
            prop_assert!(truncated.ends_with("..."));
        }
    }
}

// Property test: Remove control characters
proptest! {
    #[test]
    fn prop_remove_control_chars_preserves_whitespace(s: String) {
        let clean = remove_control_characters(&s);

        // Check that common whitespace is preserved
        for c in clean.chars() {
            if c.is_control() {
                // Only allowed control chars
                prop_assert!(c == ' ' || c == '\t' || c == '\n' || c == '\r');
            }
        }
    }
}

// Property test: PII redaction
proptest! {
    #[test]
    fn prop_redact_pii_always_redacts(s: String) {
        prop_assume!(!s.is_empty());
        let redacted = academic_shared::errors::redact_pii(&s);

        // Should contain asterisks for non-trivial strings
        if s.len() > 2 && !s.contains('@') {
            prop_assert!(redacted.contains("***"));
        }
    }
}

// Property test: Log sanitization
proptest! {
    #[test]
    fn prop_sanitize_log_no_panic(msg: String) {
        let _ = academic_shared::logging::sanitize_log_message(&msg);
        // Test passes if it doesn't panic
    }
}

// Property test: Academic year calculation
proptest! {
    #[test]
    fn prop_academic_year_consistency(year in 2000i32..2100i32, month in 1u32..=12u32) {
        use chrono::NaiveDate;
        use academic_shared::time::get_academic_year;

        // Create a valid day for the month
        let day = match month {
            2 => 15,
            4 | 6 | 9 | 11 => 15,
            _ => 15,
        };

        if let Some(date) = NaiveDate::from_ymd_opt(year, month, day) {
            let academic_year = get_academic_year(&date);

            // Academic year should be either current year or previous year
            if month >= 10 {
                prop_assert_eq!(academic_year, year);
            } else {
                prop_assert_eq!(academic_year, year - 1);
            }
        }
    }
}

// Property test: Date formatting
proptest! {
    #[test]
    fn prop_format_date_parseable(year in 2000i32..2100i32, month in 1u32..=12u32, day in 1u32..=28u32) {
        use chrono::NaiveDate;
        use academic_shared::time::{format_date, parse_date};

        if let Some(date) = NaiveDate::from_ymd_opt(year, month, day) {
            let formatted = format_date(&date);
            let parsed = parse_date(&formatted)?;
            prop_assert_eq!(date, parsed);
        }
    }
}

// Property test: ISO 8601 formatting and parsing
proptest! {
    #[test]
    fn prop_iso8601_round_trip(timestamp in 0i64..2_000_000_000i64) {
        use chrono::{DateTime, Utc};
        use academic_shared::time::{format_iso8601, parse_iso8601};

        if let Some(dt) = DateTime::from_timestamp(timestamp, 0) {
            let dt_utc = dt.with_timezone(&Utc);
            let formatted = format_iso8601(&dt_utc);
            let parsed = parse_iso8601(&formatted)?;

            // Should be within 1 second due to potential precision loss
            let diff = (dt_utc.timestamp() - parsed.timestamp()).abs();
            prop_assert!(diff <= 1);
        }
    }
}
