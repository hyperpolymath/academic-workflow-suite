//! # Academic Shared Utilities
//!
//! A comprehensive shared utilities library for the Academic Workflow Suite.
//!
//! This library provides production-ready implementations of common functionality
//! needed across all components of the suite, including:
//!
//! - **Cryptography**: Secure hashing, HMAC, key derivation, and ID generation
//! - **Validation**: Input validation for academic and UK-specific data formats
//! - **Sanitization**: Protection against XSS, SQL injection, and path traversal
//! - **Time utilities**: Academic year calculations, timezone handling, deadline management
//! - **Error handling**: Comprehensive error types with user-friendly messages
//! - **Logging**: Structured logging with PII redaction and audit trails
//! - **Testing**: Mock data generators and assertion helpers
//!
//! ## Features
//!
//! - Pure Rust with minimal dependencies
//! - Zero unsafe code
//! - Extensive documentation
//! - Comprehensive test coverage
//! - Production-ready implementations
//!
//! ## Usage
//!
//! Add this to your `Cargo.toml`:
//!
//! ```toml
//! [dependencies]
//! academic-shared = { path = "../shared" }
//! ```
//!
//! ## Examples
//!
//! ### Cryptography
//!
//! ```
//! use academic_shared::crypto::{sha3_256_hex, generate_uuid};
//!
//! let hash = sha3_256_hex(b"Hello, World!");
//! let id = generate_uuid();
//! ```
//!
//! ### Validation
//!
//! ```
//! use academic_shared::validation::{validate_email, validate_ou_student_id};
//!
//! assert!(validate_email("user@example.com").is_ok());
//! assert!(validate_ou_student_id("A1234567").is_ok());
//! ```
//!
//! ### Time utilities
//!
//! ```
//! use academic_shared::time::{get_academic_year, format_academic_year};
//! use chrono::NaiveDate;
//!
//! let date = NaiveDate::from_ymd_opt(2024, 10, 1).unwrap();
//! let year = get_academic_year(&date);
//! println!("Academic year: {}", format_academic_year(year));
//! ```
//!
//! ## Security
//!
//! This library follows security best practices:
//!
//! - All cryptographic operations use well-audited libraries
//! - Constant-time comparison for security-sensitive operations
//! - PII redaction in logs and error messages
//! - Input validation and sanitization to prevent common attacks
//! - No unsafe code
//!
//! ## License
//!
//! GPL-3.0

#![forbid(unsafe_code)]
#![warn(
    missing_docs,
    missing_debug_implementations,
    rust_2018_idioms,
    unreachable_pub
)]

// Public modules
pub mod crypto;
pub mod errors;
pub mod logging;
pub mod sanitization;
pub mod testing;
pub mod time;
pub mod validation;

// Re-export commonly used types
pub use errors::{Result, SharedError, ValidationError};

/// Library version
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

/// Library name
pub const NAME: &str = env!("CARGO_PKG_NAME");

/// Get library information as a string.
///
/// # Examples
///
/// ```
/// use academic_shared::library_info;
///
/// let info = library_info();
/// assert!(info.contains("academic-shared"));
/// ```
pub fn library_info() -> String {
    format!("{} v{}", NAME, VERSION)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_library_info() {
        let info = library_info();
        assert!(info.contains("academic-shared"));
        assert!(info.contains(VERSION));
    }

    #[test]
    fn test_version_format() {
        // Version should be in semver format (X.Y.Z)
        let parts: Vec<&str> = VERSION.split('.').collect();
        assert!(parts.len() >= 2);
    }
}
