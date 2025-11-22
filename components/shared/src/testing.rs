//! Testing utilities for the Academic Workflow Suite.
//!
//! This module provides helper functions and structures for testing:
//! - Mock data generators
//! - Temporary directory creation
//! - Test database helpers
//! - Assertion utilities

use crate::crypto::{generate_nanoid, generate_uuid};
use chrono::{DateTime, NaiveDate, Utc};

/// Generate a random test email address.
///
/// # Examples
///
/// ```
/// use academic_shared::testing::mock_email;
///
/// let email = mock_email();
/// assert!(email.contains("@test.example.com"));
/// ```
pub fn mock_email() -> String {
    format!("test-{}@test.example.com", generate_nanoid())
}

/// Generate a random OU student ID.
///
/// # Examples
///
/// ```
/// use academic_shared::testing::mock_student_id;
///
/// let id = mock_student_id();
/// assert_eq!(id.len(), 8); // One letter + 7 digits
/// ```
pub fn mock_student_id() -> String {
    use rand::Rng;
    let mut rng = rand::thread_rng();
    let letter = (b'A' + rng.gen_range(0..26)) as char;
    let number = rng.gen_range(1000000..9999999);
    format!("{}{}", letter, number)
}

/// Generate a random OU module code.
///
/// # Examples
///
/// ```
/// use academic_shared::testing::mock_module_code;
///
/// let code = mock_module_code();
/// assert!(code.len() == 4 || code.len() == 5 || code.len() == 6);
/// ```
pub fn mock_module_code() -> String {
    use rand::Rng;
    let mut rng = rand::thread_rng();

    // Generate 1-3 letters
    let letter_count = rng.gen_range(1..=3);
    let letters: String = (0..letter_count)
        .map(|_| (b'A' + rng.gen_range(0..26)) as char)
        .collect();

    // Generate 3 digits
    let number = rng.gen_range(100..999);

    format!("{}{}", letters, number)
}

/// Generate a random UK phone number.
///
/// # Examples
///
/// ```
/// use academic_shared::testing::mock_uk_phone;
///
/// let phone = mock_uk_phone();
/// assert!(phone.starts_with("07") || phone.starts_with("01") || phone.starts_with("02"));
/// ```
pub fn mock_uk_phone() -> String {
    use rand::Rng;
    let mut rng = rand::thread_rng();

    let prefix_choice = rng.gen_range(0..2);
    if prefix_choice == 0 {
        // Mobile: 07 + 9 digits
        let number: String = (0..9)
            .map(|_| rng.gen_range(0..10).to_string())
            .collect();
        format!("07{}", number)
    } else {
        // Landline: 0 + area code (2-4 digits) + local number
        // Example: 020 + 8 digits = 11 total
        let number: String = (0..9)
            .map(|_| rng.gen_range(0..10).to_string())
            .collect();
        format!("02{}", number)
    }
}

/// Generate a random UK postcode.
///
/// # Examples
///
/// ```
/// use academic_shared::testing::mock_uk_postcode;
///
/// let postcode = mock_uk_postcode();
/// assert!(postcode.contains(' '));
/// ```
pub fn mock_uk_postcode() -> String {
    use rand::Rng;
    let mut rng = rand::thread_rng();

    let area_letters: String = (0..rng.gen_range(1..=2))
        .map(|_| (b'A' + rng.gen_range(0..26)) as char)
        .collect();

    let area_digits: String = (0..rng.gen_range(1..=2))
        .map(|_| rng.gen_range(0..10).to_string())
        .collect();

    let sector = rng.gen_range(0..10);

    let unit: String = (0..2)
        .map(|_| (b'A' + rng.gen_range(0..26)) as char)
        .collect();

    format!("{}{} {}{}", area_letters, area_digits, sector, unit)
}

/// Generate a mock datetime in the past.
///
/// # Examples
///
/// ```
/// use academic_shared::testing::mock_datetime_past;
///
/// let dt = mock_datetime_past(30); // Within last 30 days
/// assert!(dt < chrono::Utc::now());
/// ```
pub fn mock_datetime_past(max_days_ago: u64) -> DateTime<Utc> {
    use chrono::Duration;
    use rand::Rng;

    let mut rng = rand::thread_rng();
    let days_ago = rng.gen_range(1..=max_days_ago) as i64;

    Utc::now() - Duration::days(days_ago)
}

/// Generate a mock datetime in the future.
///
/// # Examples
///
/// ```
/// use academic_shared::testing::mock_datetime_future;
///
/// let dt = mock_datetime_future(30); // Within next 30 days
/// assert!(dt > chrono::Utc::now());
/// ```
pub fn mock_datetime_future(max_days_ahead: u64) -> DateTime<Utc> {
    use chrono::Duration;
    use rand::Rng;

    let mut rng = rand::thread_rng();
    let days_ahead = rng.gen_range(1..=max_days_ahead) as i64;

    Utc::now() + Duration::days(days_ahead)
}

/// Generate a mock academic year date.
///
/// # Examples
///
/// ```
/// use academic_shared::testing::mock_academic_date;
/// use chrono::Datelike;
///
/// let date = mock_academic_date(2024);
/// assert!(date.year() == 2024 || date.year() == 2025);
/// ```
pub fn mock_academic_date(academic_year: i32) -> NaiveDate {
    use rand::Rng;
    let mut rng = rand::thread_rng();

    // Academic year runs Oct 1 to Sep 30
    let month = rng.gen_range(1..=12);
    let year = if month >= 10 {
        academic_year
    } else {
        academic_year + 1
    };

    let day = match month {
        2 => rng.gen_range(1..=28),  // Feb (ignore leap years for simplicity)
        4 | 6 | 9 | 11 => rng.gen_range(1..=30),
        _ => rng.gen_range(1..=31),
    };

    NaiveDate::from_ymd_opt(year, month, day).expect("Invalid date")
}

/// Create a mock user data structure.
///
/// # Examples
///
/// ```
/// use academic_shared::testing::MockUser;
///
/// let user = MockUser::new();
/// assert!(!user.student_id.is_empty());
/// assert!(!user.email.is_empty());
/// ```
#[derive(Debug, Clone)]
pub struct MockUser {
    /// Unique user identifier (UUID)
    pub id: String,
    /// OU student ID (e.g., A1234567)
    pub student_id: String,
    /// Email address
    pub email: String,
    /// UK phone number
    pub phone: String,
    /// UK postcode
    pub postcode: String,
}

impl MockUser {
    /// Create a new mock user with random data.
    pub fn new() -> Self {
        Self {
            id: generate_uuid(),
            student_id: mock_student_id(),
            email: mock_email(),
            phone: mock_uk_phone(),
            postcode: mock_uk_postcode(),
        }
    }

    /// Create a mock user with specific student ID.
    pub fn with_student_id(student_id: &str) -> Self {
        Self {
            student_id: student_id.to_string(),
            ..Self::new()
        }
    }

    /// Create a mock user with specific email.
    pub fn with_email(email: &str) -> Self {
        Self {
            email: email.to_string(),
            ..Self::new()
        }
    }
}

impl Default for MockUser {
    fn default() -> Self {
        Self::new()
    }
}

/// Create a mock module data structure.
///
/// # Examples
///
/// ```
/// use academic_shared::testing::MockModule;
///
/// let module = MockModule::new();
/// assert!(!module.code.is_empty());
/// ```
#[derive(Debug, Clone)]
pub struct MockModule {
    /// Unique module identifier (UUID)
    pub id: String,
    /// OU module code (e.g., TM112)
    pub code: String,
    /// Module title
    pub title: String,
    /// Academic year
    pub academic_year: i32,
    /// Module credits (typically 30 or 60)
    pub credits: u32,
}

impl MockModule {
    /// Create a new mock module with random data.
    pub fn new() -> Self {
        Self {
            id: generate_uuid(),
            code: mock_module_code(),
            title: "Introduction to Test Module".to_string(),
            academic_year: 2024,
            credits: 30,
        }
    }

    /// Create a mock module with specific code.
    pub fn with_code(code: &str) -> Self {
        Self {
            code: code.to_string(),
            ..Self::new()
        }
    }

    /// Create a mock module with specific academic year.
    pub fn with_year(year: i32) -> Self {
        Self {
            academic_year: year,
            ..Self::new()
        }
    }
}

impl Default for MockModule {
    fn default() -> Self {
        Self::new()
    }
}

/// Assertion helper: assert that a string contains a substring.
///
/// # Examples
///
/// ```
/// use academic_shared::testing::assert_contains;
///
/// assert_contains("Hello, World!", "World");
/// ```
///
/// # Panics
///
/// Panics if the haystack doesn't contain the needle.
#[track_caller]
pub fn assert_contains(haystack: &str, needle: &str) {
    assert!(
        haystack.contains(needle),
        "Expected '{}' to contain '{}'",
        haystack,
        needle
    );
}

/// Assertion helper: assert that a string does not contain a substring.
///
/// # Examples
///
/// ```
/// use academic_shared::testing::assert_not_contains;
///
/// assert_not_contains("Hello, World!", "Goodbye");
/// ```
///
/// # Panics
///
/// Panics if the haystack contains the needle.
#[track_caller]
pub fn assert_not_contains(haystack: &str, needle: &str) {
    assert!(
        !haystack.contains(needle),
        "Expected '{}' to not contain '{}'",
        haystack,
        needle
    );
}

/// Assertion helper: assert that a value is within a range.
///
/// # Examples
///
/// ```
/// use academic_shared::testing::assert_in_range;
///
/// assert_in_range(5, 0, 10);
/// ```
///
/// # Panics
///
/// Panics if the value is outside the range.
#[track_caller]
pub fn assert_in_range<T: PartialOrd + std::fmt::Debug>(value: T, min: T, max: T) {
    assert!(
        value >= min && value <= max,
        "Expected {:?} to be in range [{:?}, {:?}]",
        value,
        min,
        max
    );
}

/// Generate a random string of specified length.
///
/// # Examples
///
/// ```
/// use academic_shared::testing::random_string;
///
/// let s = random_string(10);
/// assert_eq!(s.len(), 10);
/// ```
pub fn random_string(length: usize) -> String {
    use rand::Rng;
    const CHARSET: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    let mut rng = rand::thread_rng();

    (0..length)
        .map(|_| {
            let idx = rng.gen_range(0..CHARSET.len());
            CHARSET[idx] as char
        })
        .collect()
}

/// Generate a random alphanumeric string.
///
/// # Examples
///
/// ```
/// use academic_shared::testing::random_alphanumeric;
///
/// let s = random_alphanumeric(8);
/// assert_eq!(s.len(), 8);
/// assert!(s.chars().all(|c| c.is_alphanumeric()));
/// ```
pub fn random_alphanumeric(length: usize) -> String {
    random_string(length)
}

/// Generate a random integer in range.
///
/// # Examples
///
/// ```
/// use academic_shared::testing::random_int;
///
/// let n = random_int(1, 100);
/// assert!(n >= 1 && n <= 100);
/// ```
pub fn random_int(min: i64, max: i64) -> i64 {
    use rand::Rng;
    rand::thread_rng().gen_range(min..=max)
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Datelike;

    #[test]
    fn test_mock_email() {
        let email = mock_email();
        assert!(email.contains("@test.example.com"));
        assert!(email.starts_with("test-"));
    }

    #[test]
    fn test_mock_student_id() {
        let id = mock_student_id();
        assert_eq!(id.len(), 8);
        assert!(id.chars().next().unwrap().is_ascii_uppercase());
        assert!(id[1..].chars().all(|c| c.is_ascii_digit()));
    }

    #[test]
    fn test_mock_module_code() {
        let code = mock_module_code();
        assert!(code.len() >= 4 && code.len() <= 6);

        // Should start with letters
        let first_char = code.chars().next().unwrap();
        assert!(first_char.is_ascii_uppercase());

        // Should end with digits
        let last_three: String = code.chars().rev().take(3).collect();
        assert!(last_three.chars().all(|c| c.is_ascii_digit()));
    }

    #[test]
    fn test_mock_uk_phone() {
        let phone = mock_uk_phone();
        assert!(phone.starts_with('0'));
        // Should be 11 digits total
        assert_eq!(phone.len(), 11);
    }

    #[test]
    fn test_mock_uk_postcode() {
        let postcode = mock_uk_postcode();
        assert!(postcode.contains(' '));
        assert!(postcode.len() >= 6 && postcode.len() <= 8);
    }

    #[test]
    fn test_mock_datetime_past() {
        let dt = mock_datetime_past(30);
        assert!(dt < Utc::now());
    }

    #[test]
    fn test_mock_datetime_future() {
        let dt = mock_datetime_future(30);
        assert!(dt > Utc::now());
    }

    #[test]
    fn test_mock_academic_date() {
        let date = mock_academic_date(2024);
        let year = date.year();
        assert!(year == 2024 || year == 2025);
    }

    #[test]
    fn test_mock_user() {
        let user = MockUser::new();
        assert!(!user.id.is_empty());
        assert!(!user.student_id.is_empty());
        assert!(!user.email.is_empty());
        assert!(!user.phone.is_empty());
        assert!(!user.postcode.is_empty());
    }

    #[test]
    fn test_mock_user_with_student_id() {
        let user = MockUser::with_student_id("A1234567");
        assert_eq!(user.student_id, "A1234567");
    }

    #[test]
    fn test_mock_module() {
        let module = MockModule::new();
        assert!(!module.id.is_empty());
        assert!(!module.code.is_empty());
        assert!(!module.title.is_empty());
    }

    #[test]
    fn test_mock_module_with_code() {
        let module = MockModule::with_code("TM112");
        assert_eq!(module.code, "TM112");
    }

    #[test]
    fn test_assert_contains() {
        assert_contains("Hello, World!", "World");
        assert_contains("test string", "test");
    }

    #[test]
    fn test_assert_not_contains() {
        assert_not_contains("Hello, World!", "Goodbye");
        assert_not_contains("test", "xyz");
    }

    #[test]
    fn test_assert_in_range() {
        assert_in_range(5, 0, 10);
        assert_in_range(0, 0, 10);
        assert_in_range(10, 0, 10);
    }

    #[test]
    fn test_random_string() {
        let s = random_string(10);
        assert_eq!(s.len(), 10);
        assert!(s.chars().all(|c| c.is_alphanumeric()));
    }

    #[test]
    fn test_random_alphanumeric() {
        let s = random_alphanumeric(8);
        assert_eq!(s.len(), 8);
        assert!(s.chars().all(|c| c.is_alphanumeric()));
    }

    #[test]
    fn test_random_int() {
        for _ in 0..100 {
            let n = random_int(1, 10);
            assert!(n >= 1 && n <= 10);
        }
    }
}
