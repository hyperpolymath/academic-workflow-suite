//! Data sanitization utilities for the Academic Workflow Suite.
//!
//! This module provides functions to sanitize user input and prevent
//! common security vulnerabilities including:
//! - HTML injection (XSS)
//! - SQL injection
//! - Path traversal
//! - Unicode normalization attacks

use crate::errors::{Result, SharedError};
use ammonia::Builder;
use std::path::{Path, PathBuf};
use unicode_normalization::UnicodeNormalization;

// Note: Ammonia builders are not stored in lazy_static as they don't have a static lifetime
// Instead, we create them on demand in the functions below

/// Sanitize HTML content, removing all potentially dangerous elements and attributes.
///
/// This is the strictest sanitization mode, removing all HTML tags.
///
/// # Examples
///
/// ```
/// use academic_shared::sanitization::sanitize_html;
///
/// let clean = sanitize_html("<script>alert('xss')</script>Hello");
/// assert!(!clean.contains("<script>"));
/// assert!(clean.contains("Hello"));
/// ```
pub fn sanitize_html(input: &str) -> String {
    ammonia::clean(input)
}

/// Sanitize HTML while allowing basic formatting tags.
///
/// Allows: p, br, strong, em, u, ul, ol, li
///
/// # Examples
///
/// ```
/// use academic_shared::sanitization::sanitize_html_basic;
///
/// let clean = sanitize_html_basic("<p>Hello <strong>world</strong></p>");
/// assert!(clean.contains("<p>"));
/// assert!(clean.contains("<strong>"));
///
/// let clean = sanitize_html_basic("<script>alert('xss')</script>");
/// assert!(!clean.contains("<script>"));
/// ```
pub fn sanitize_html_basic(input: &str) -> String {
    Builder::default()
        .add_tags(&["p", "br", "strong", "em", "u", "ul", "ol", "li"])
        .add_generic_attributes(&["class"])
        .clean(input)
        .to_string()
}

/// Escape special characters for SQL LIKE clauses.
///
/// Note: This is NOT a replacement for parameterized queries.
/// Always use parameterized queries for SQL. This is only for
/// escaping user input in LIKE patterns.
///
/// # Examples
///
/// ```
/// use academic_shared::sanitization::escape_sql_like;
///
/// assert_eq!(escape_sql_like("test%"), "test\\%");
/// assert_eq!(escape_sql_like("test_"), "test\\_");
/// assert_eq!(escape_sql_like("normal"), "normal");
/// ```
pub fn escape_sql_like(input: &str) -> String {
    input
        .replace('\\', "\\\\")
        .replace('%', "\\%")
        .replace('_', "\\_")
}

/// Sanitize input for use in SQL contexts.
///
/// **WARNING**: This is NOT sufficient for SQL injection prevention.
/// Always use parameterized queries. This function is only for
/// additional sanitization of user input.
///
/// # Examples
///
/// ```
/// use academic_shared::sanitization::sanitize_sql_input;
///
/// let clean = sanitize_sql_input("user'; DROP TABLE users--");
/// assert!(!clean.contains("--"));
/// assert!(!clean.contains(';'));
/// ```
pub fn sanitize_sql_input(input: &str) -> String {
    // Remove SQL comment markers and dangerous characters
    input
        .replace("--", "")
        .replace("/*", "")
        .replace("*/", "")
        .replace(';', "")
        .replace('\'', "''") // SQL escape for single quote
}

/// Prevent path traversal attacks by validating and sanitizing file paths.
///
/// This function ensures that:
/// - Path doesn't contain ".." segments
/// - Path doesn't contain null bytes
/// - Path is relative (not absolute)
/// - Path doesn't escape the base directory
///
/// # Examples
///
/// ```
/// use academic_shared::sanitization::sanitize_path;
///
/// assert!(sanitize_path("uploads/file.txt", "/var/www/uploads").is_ok());
/// assert!(sanitize_path("../etc/passwd", "/var/www/uploads").is_err());
/// assert!(sanitize_path("/etc/passwd", "/var/www/uploads").is_err());
/// ```
pub fn sanitize_path(path: &str, base_dir: &str) -> Result<PathBuf> {
    // Check for null bytes
    if path.contains('\0') {
        return Err(SharedError::Sanitization(
            "Path contains null bytes".to_string(),
        ));
    }

    // Check for absolute paths
    if Path::new(path).is_absolute() {
        return Err(SharedError::Sanitization(
            "Absolute paths are not allowed".to_string(),
        ));
    }

    // Check for path traversal attempts
    if path.contains("..") {
        return Err(SharedError::Sanitization(
            "Path traversal detected".to_string(),
        ));
    }

    // Build the full path
    let base = PathBuf::from(base_dir);
    let full_path = base.join(path);

    // Canonicalize and verify it's still within base directory
    // Note: This would require the path to exist in production
    // For validation purposes, we'll check the components
    let normalized = normalize_path(&full_path);

    if !normalized.starts_with(&base) {
        return Err(SharedError::Sanitization(
            "Path escapes base directory".to_string(),
        ));
    }

    Ok(normalized)
}

/// Normalize a path by resolving ".." and "." components.
///
/// This is a simplified version that doesn't require the path to exist.
fn normalize_path(path: &Path) -> PathBuf {
    let mut components = Vec::new();

    for component in path.components() {
        match component {
            std::path::Component::ParentDir => {
                components.pop();
            }
            std::path::Component::CurDir => {
                // Skip current directory markers
            }
            _ => {
                components.push(component);
            }
        }
    }

    components.iter().collect()
}

/// Normalize Unicode to NFC (Canonical Decomposition, followed by Canonical Composition).
///
/// This prevents Unicode normalization attacks and ensures consistent string comparison.
///
/// # Examples
///
/// ```
/// use academic_shared::sanitization::normalize_unicode;
///
/// let input = "Café"; // Can be represented in multiple ways
/// let normalized = normalize_unicode(input);
/// assert_eq!(normalized.len(), 5); // Consistent length
/// ```
pub fn normalize_unicode(input: &str) -> String {
    input.nfc().collect()
}

/// Normalize Unicode to NFD (Canonical Decomposition).
///
/// # Examples
///
/// ```
/// use academic_shared::sanitization::normalize_unicode_nfd;
///
/// let normalized = normalize_unicode_nfd("é");
/// // é decomposed into e + combining acute accent
/// ```
pub fn normalize_unicode_nfd(input: &str) -> String {
    input.nfd().collect()
}

/// Remove all control characters except common whitespace.
///
/// Preserves: space, tab, newline, carriage return
/// Removes: other ASCII control characters and Unicode control characters
///
/// # Examples
///
/// ```
/// use academic_shared::sanitization::remove_control_characters;
///
/// let clean = remove_control_characters("Hello\x00World\nTest");
/// assert!(!clean.contains('\x00'));
/// assert!(clean.contains('\n')); // newline is preserved
/// ```
pub fn remove_control_characters(input: &str) -> String {
    input
        .chars()
        .filter(|&c| {
            // Keep common whitespace
            if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
                return true;
            }
            // Remove control characters
            !c.is_control()
        })
        .collect()
}

/// Sanitize filename for safe file system operations.
///
/// Removes or replaces characters that could cause issues:
/// - Path separators (/ \)
/// - Null bytes
/// - Control characters
/// - Leading/trailing dots and spaces
///
/// # Examples
///
/// ```
/// use academic_shared::sanitization::sanitize_filename;
///
/// assert_eq!(sanitize_filename("file.txt"), "file.txt");
/// assert_eq!(sanitize_filename("../etc/passwd"), "etcpasswd"); // Strips leading dots
/// assert_eq!(sanitize_filename("file:name?.txt"), "file_name_.txt");
/// ```
pub fn sanitize_filename(filename: &str) -> String {
    let mut sanitized: String = filename
        .chars()
        .filter(|&c| {
            // Remove dangerous characters
            c != '/' && c != '\\' && c != '\0' && !c.is_control()
        })
        .map(|c| {
            // Replace problematic characters with underscore
            match c {
                '<' | '>' | ':' | '"' | '|' | '?' | '*' => '_',
                _ => c,
            }
        })
        .collect();

    // Remove leading/trailing dots and spaces
    sanitized = sanitized.trim_matches(|c| c == '.' || c == ' ').to_string();

    // Ensure we don't return an empty string
    if sanitized.is_empty() {
        sanitized = "file".to_string();
    }

    // Limit length to reasonable value
    if sanitized.len() > 255 {
        sanitized.truncate(255);
    }

    sanitized
}

/// Truncate a string to a maximum length, adding an ellipsis if truncated.
///
/// Ensures truncation happens at a character boundary (UTF-8 safe).
///
/// # Examples
///
/// ```
/// use academic_shared::sanitization::truncate_string;
///
/// assert_eq!(truncate_string("Hello, World!", 10), "Hello, ...");
/// assert_eq!(truncate_string("Short", 10), "Short");
/// ```
pub fn truncate_string(input: &str, max_length: usize) -> String {
    if input.len() <= max_length {
        return input.to_string();
    }

    let ellipsis = "...";
    let truncate_at = max_length.saturating_sub(ellipsis.len());

    // Find a valid UTF-8 boundary
    let mut boundary = truncate_at;
    while boundary > 0 && !input.is_char_boundary(boundary) {
        boundary -= 1;
    }

    format!("{}{}", &input[..boundary], ellipsis)
}

/// Strip all HTML tags from input.
///
/// # Examples
///
/// ```
/// use academic_shared::sanitization::strip_html;
///
/// assert_eq!(strip_html("<p>Hello</p>"), "Hello");
/// assert_eq!(strip_html("<b>Bold</b> and <i>italic</i>"), "Bold and italic");
/// ```
pub fn strip_html(input: &str) -> String {
    // Use ammonia with no allowed tags to strip everything
    Builder::default()
        .tags(std::collections::HashSet::new()) // No tags allowed
        .clean(input)
        .to_string()
}

/// Escape special characters for use in JSON strings.
///
/// # Examples
///
/// ```
/// use academic_shared::sanitization::escape_json_string;
///
/// assert_eq!(escape_json_string("Hello \"World\""), "Hello \\\"World\\\"");
/// assert_eq!(escape_json_string("Line1\nLine2"), "Line1\\nLine2");
/// ```
pub fn escape_json_string(input: &str) -> String {
    input
        .replace('\\', "\\\\")
        .replace('"', "\\\"")
        .replace('\n', "\\n")
        .replace('\r', "\\r")
        .replace('\t', "\\t")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sanitize_html() {
        let input = "<script>alert('xss')</script>Hello";
        let clean = sanitize_html(input);
        assert!(!clean.contains("<script"));
        assert!(clean.contains("Hello"));
    }

    #[test]
    fn test_sanitize_html_basic() {
        let input = "<p>Hello <strong>world</strong></p>";
        let clean = sanitize_html_basic(input);
        assert!(clean.contains("<p>"));
        assert!(clean.contains("<strong>"));

        let dangerous = "<script>alert('xss')</script>";
        let clean = sanitize_html_basic(dangerous);
        assert!(!clean.contains("<script"));
    }

    #[test]
    fn test_escape_sql_like() {
        assert_eq!(escape_sql_like("test%"), "test\\%");
        assert_eq!(escape_sql_like("test_"), "test\\_");
        assert_eq!(escape_sql_like("normal"), "normal");
        assert_eq!(escape_sql_like("a%b_c"), "a\\%b\\_c");
    }

    #[test]
    fn test_sanitize_sql_input() {
        let input = "user'; DROP TABLE users--";
        let clean = sanitize_sql_input(input);
        assert!(!clean.contains("--"));
        assert!(!clean.contains(';'));
        assert!(clean.contains("''"));
    }

    #[test]
    fn test_sanitize_path() {
        // Valid paths
        assert!(sanitize_path("uploads/file.txt", "/var/www").is_ok());
        assert!(sanitize_path("file.txt", "/var/www").is_ok());

        // Invalid paths
        assert!(sanitize_path("../etc/passwd", "/var/www").is_err());
        assert!(sanitize_path("/etc/passwd", "/var/www").is_err());
        assert!(sanitize_path("file\0.txt", "/var/www").is_err());
    }

    #[test]
    fn test_normalize_unicode() {
        // Test NFC normalization
        let normalized = normalize_unicode("Café");
        assert!(normalized.len() <= 5);

        // Test consistency
        let input1 = "é"; // composed
        let input2 = "é"; // decomposed (e + combining acute)
        assert_eq!(normalize_unicode(input1), normalize_unicode(input2));
    }

    #[test]
    fn test_remove_control_characters() {
        let input = "Hello\x00World\nTest\r\nLine";
        let clean = remove_control_characters(input);
        assert!(!clean.contains('\x00'));
        assert!(clean.contains('\n'));
        assert!(clean.contains('\r'));
    }

    #[test]
    fn test_sanitize_filename() {
        assert_eq!(sanitize_filename("file.txt"), "file.txt");
        assert_eq!(sanitize_filename("my file.txt"), "my file.txt");

        // Dangerous characters
        let dangerous = "../../../etc/passwd";
        let clean = sanitize_filename(dangerous);
        assert!(!clean.contains('/'));
        assert!(!clean.contains(".."));

        // Windows reserved characters
        assert_eq!(sanitize_filename("file:name.txt"), "file_name.txt");
        assert_eq!(sanitize_filename("file?.txt"), "file_.txt");

        // Empty result
        assert_eq!(sanitize_filename("..."), "file");
        assert_eq!(sanitize_filename("   "), "file");
    }

    #[test]
    fn test_truncate_string() {
        assert_eq!(truncate_string("Hello, World!", 10), "Hello, ...");
        assert_eq!(truncate_string("Short", 10), "Short");
        assert_eq!(truncate_string("Exactly10!", 10), "Exactly10!");

        // Test UTF-8 safety
        let emoji = "Hello 😀 World";
        let truncated = truncate_string(emoji, 10);
        assert!(truncated.len() <= 10);
    }

    #[test]
    fn test_strip_html() {
        assert_eq!(strip_html("<p>Hello</p>"), "Hello");
        assert_eq!(strip_html("<b>Bold</b> text"), "Bold text");
        assert_eq!(
            strip_html("<script>alert('xss')</script>Hello"),
            "Hello"
        );
    }

    #[test]
    fn test_escape_json_string() {
        assert_eq!(escape_json_string("Hello"), "Hello");
        assert_eq!(escape_json_string("Say \"Hi\""), "Say \\\"Hi\\\"");
        assert_eq!(escape_json_string("Line1\nLine2"), "Line1\\nLine2");
        assert_eq!(escape_json_string("Tab\there"), "Tab\\there");
    }

    #[test]
    fn test_normalize_path() {
        let path = PathBuf::from("/var/www/../uploads/./file.txt");
        let normalized = normalize_path(&path);
        assert_eq!(normalized, PathBuf::from("/var/uploads/file.txt"));
    }
}
