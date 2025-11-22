//! Logging utilities for the Academic Workflow Suite.
//!
//! This module provides:
//! - Structured logging setup
//! - Audit log formatting
//! - PII redaction for logs
//! - Log level management

use crate::errors::redact_pii;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use tracing::Level;
use tracing_subscriber::{
    fmt::{format::FmtSpan, Layer},
    layer::SubscriberExt,
    EnvFilter,
};

/// Log level configuration
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum LogLevel {
    /// Trace level (most verbose)
    Trace,
    /// Debug level
    Debug,
    /// Info level (default)
    Info,
    /// Warning level
    Warn,
    /// Error level (least verbose)
    Error,
}

impl From<LogLevel> for Level {
    fn from(level: LogLevel) -> Self {
        match level {
            LogLevel::Trace => Level::TRACE,
            LogLevel::Debug => Level::DEBUG,
            LogLevel::Info => Level::INFO,
            LogLevel::Warn => Level::WARN,
            LogLevel::Error => Level::ERROR,
        }
    }
}

impl std::fmt::Display for LogLevel {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            LogLevel::Trace => write!(f, "trace"),
            LogLevel::Debug => write!(f, "debug"),
            LogLevel::Info => write!(f, "info"),
            LogLevel::Warn => write!(f, "warn"),
            LogLevel::Error => write!(f, "error"),
        }
    }
}

/// Audit log entry structure
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuditLogEntry {
    /// Timestamp in ISO 8601 format
    pub timestamp: String,
    /// User ID (redacted if necessary)
    pub user_id: Option<String>,
    /// Action performed
    pub action: String,
    /// Resource affected
    pub resource: Option<String>,
    /// Result of the action
    pub result: AuditResult,
    /// Additional metadata
    pub metadata: HashMap<String, String>,
    /// IP address (partially redacted)
    pub ip_address: Option<String>,
}

/// Result of an audited action
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum AuditResult {
    /// Action succeeded
    Success,
    /// Action failed
    Failure,
    /// Action was denied
    Denied,
}

impl std::fmt::Display for AuditResult {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            AuditResult::Success => write!(f, "SUCCESS"),
            AuditResult::Failure => write!(f, "FAILURE"),
            AuditResult::Denied => write!(f, "DENIED"),
        }
    }
}

/// Initialize the logging system with default settings.
///
/// # Examples
///
/// ```no_run
/// use academic_shared::logging::{init_logging, LogLevel};
///
/// init_logging(LogLevel::Info);
/// ```
pub fn init_logging(level: LogLevel) {
    let filter = EnvFilter::new(level.to_string());

    let subscriber = tracing_subscriber::registry()
        .with(filter)
        .with(
            Layer::new()
                .with_target(true)
                .with_thread_ids(true)
                .with_thread_names(true)
                .with_span_events(FmtSpan::CLOSE),
        );

    tracing::subscriber::set_global_default(subscriber)
        .expect("Failed to set tracing subscriber");
}

/// Initialize JSON-formatted logging for production environments.
///
/// # Examples
///
/// ```no_run
/// use academic_shared::logging::{init_json_logging, LogLevel};
///
/// init_json_logging(LogLevel::Info);
/// ```
pub fn init_json_logging(level: LogLevel) {
    let filter = EnvFilter::new(level.to_string());

    let subscriber = tracing_subscriber::registry()
        .with(filter)
        .with(
            tracing_subscriber::fmt::layer()
                .json()
                .with_target(true)
                .with_thread_ids(true)
                .with_span_events(FmtSpan::CLOSE),
        );

    tracing::subscriber::set_global_default(subscriber)
        .expect("Failed to set tracing subscriber");
}

/// Create an audit log entry.
///
/// # Examples
///
/// ```
/// use academic_shared::logging::{create_audit_log, AuditResult};
/// use std::collections::HashMap;
///
/// let entry = create_audit_log(
///     Some("user123"),
///     "login",
///     Some("authentication_system"),
///     AuditResult::Success,
///     HashMap::new(),
///     Some("192.168.1.100"),
/// );
///
/// assert_eq!(entry.action, "login");
/// ```
pub fn create_audit_log(
    user_id: Option<&str>,
    action: &str,
    resource: Option<&str>,
    result: AuditResult,
    metadata: HashMap<String, String>,
    ip_address: Option<&str>,
) -> AuditLogEntry {
    AuditLogEntry {
        timestamp: chrono::Utc::now().to_rfc3339(),
        user_id: user_id.map(|id| redact_user_id(id)),
        action: action.to_string(),
        resource: resource.map(String::from),
        result,
        metadata,
        ip_address: ip_address.map(redact_ip_address),
    }
}

/// Format an audit log entry as JSON.
///
/// # Examples
///
/// ```
/// use academic_shared::logging::{create_audit_log, format_audit_log, AuditResult};
/// use std::collections::HashMap;
///
/// let entry = create_audit_log(
///     Some("user123"),
///     "login",
///     None,
///     AuditResult::Success,
///     HashMap::new(),
///     None,
/// );
///
/// let json = format_audit_log(&entry).unwrap();
/// assert!(json.contains("\"action\":\"login\""));
/// ```
pub fn format_audit_log(entry: &AuditLogEntry) -> Result<String, serde_json::Error> {
    serde_json::to_string(entry)
}

/// Format an audit log entry as pretty-printed JSON.
///
/// # Examples
///
/// ```
/// use academic_shared::logging::{create_audit_log, format_audit_log_pretty, AuditResult};
/// use std::collections::HashMap;
///
/// let entry = create_audit_log(
///     Some("user123"),
///     "login",
///     None,
///     AuditResult::Success,
///     HashMap::new(),
///     None,
/// );
///
/// let json = format_audit_log_pretty(&entry).unwrap();
/// assert!(json.contains("\"action\""));
/// ```
pub fn format_audit_log_pretty(entry: &AuditLogEntry) -> Result<String, serde_json::Error> {
    serde_json::to_string_pretty(entry)
}

/// Redact a user ID for logging.
///
/// Shows first and last character, masks the middle.
///
/// # Examples
///
/// ```
/// use academic_shared::logging::redact_user_id;
///
/// assert_eq!(redact_user_id("user12345"), "u*******5");
/// assert_eq!(redact_user_id("ab"), "a*");
/// ```
pub fn redact_user_id(user_id: &str) -> String {
    if user_id.len() <= 2 {
        return format!("{}*", user_id.chars().next().unwrap_or('*'));
    }

    let first = user_id.chars().next().unwrap();
    let last = user_id.chars().last().unwrap();
    let mask_len = user_id.len() - 2;

    format!("{}{}{}", first, "*".repeat(mask_len), last)
}

/// Redact an IP address for logging.
///
/// For IPv4: Shows first two octets, masks last two (e.g., 192.168.***.***).
/// For IPv6: Shows first two groups, masks the rest.
///
/// # Examples
///
/// ```
/// use academic_shared::logging::redact_ip_address;
///
/// assert_eq!(redact_ip_address("192.168.1.100"), "192.168.***. ***");
/// assert_eq!(redact_ip_address("10.0.0.1"), "10.0.***. ***");
/// ```
pub fn redact_ip_address(ip: &str) -> String {
    // IPv4
    if let Some(parts) = ip.split('.').collect::<Vec<_>>().get(0..4) {
        if parts.len() == 4 {
            return format!("{}.{}.***. ***", parts[0], parts[1]);
        }
    }

    // IPv6
    if ip.contains(':') {
        let parts: Vec<&str> = ip.split(':').collect();
        if parts.len() >= 2 {
            return format!("{}:{}:****:****:****:****:****:****", parts[0], parts[1]);
        }
    }

    // Fallback: completely mask unknown format
    "***.***.***. ***".to_string()
}

/// Redact email address for logging.
///
/// Shows first character and domain, masks the local part.
///
/// # Examples
///
/// ```
/// use academic_shared::logging::redact_email;
///
/// assert_eq!(redact_email("user@example.com"), "u***@example.com");
/// ```
pub fn redact_email(email: &str) -> String {
    redact_pii(email)
}

/// Sanitize log message to remove potential PII.
///
/// This function attempts to identify and redact common PII patterns:
/// - Email addresses
/// - Phone numbers
/// - Credit card numbers (if accidentally logged)
///
/// # Examples
///
/// ```
/// use academic_shared::logging::sanitize_log_message;
///
/// let msg = "User logged in: user@example.com";
/// let sanitized = sanitize_log_message(msg);
/// assert!(sanitized.contains("[EMAIL_REDACTED]"));
/// ```
pub fn sanitize_log_message(message: &str) -> String {
    use regex::Regex;
    use lazy_static::lazy_static;

    lazy_static! {
        // Email pattern
        static ref EMAIL_PATTERN: Regex = Regex::new(
            r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"
        ).unwrap();

        // Phone number pattern (various formats)
        static ref PHONE_PATTERN: Regex = Regex::new(
            r"\b(\+?44\s?|0)\d{2,4}\s?\d{3,4}\s?\d{4}\b"
        ).unwrap();

        // Credit card pattern (basic detection)
        static ref CC_PATTERN: Regex = Regex::new(
            r"\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b"
        ).unwrap();
    }

    let mut sanitized = message.to_string();

    // Redact emails
    sanitized = EMAIL_PATTERN
        .replace_all(&sanitized, "[EMAIL_REDACTED]")
        .to_string();

    // Redact phone numbers
    sanitized = PHONE_PATTERN
        .replace_all(&sanitized, "[PHONE_REDACTED]")
        .to_string();

    // Redact potential credit cards
    sanitized = CC_PATTERN
        .replace_all(&sanitized, "[CC_REDACTED]")
        .to_string();

    sanitized
}

/// Log level from string.
///
/// # Examples
///
/// ```
/// use academic_shared::logging::{LogLevel, parse_log_level};
///
/// assert_eq!(parse_log_level("info"), Some(LogLevel::Info));
/// assert_eq!(parse_log_level("debug"), Some(LogLevel::Debug));
/// assert_eq!(parse_log_level("invalid"), None);
/// ```
pub fn parse_log_level(level: &str) -> Option<LogLevel> {
    match level.to_lowercase().as_str() {
        "trace" => Some(LogLevel::Trace),
        "debug" => Some(LogLevel::Debug),
        "info" => Some(LogLevel::Info),
        "warn" | "warning" => Some(LogLevel::Warn),
        "error" => Some(LogLevel::Error),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_log_level_conversion() {
        assert_eq!(Level::from(LogLevel::Trace), Level::TRACE);
        assert_eq!(Level::from(LogLevel::Debug), Level::DEBUG);
        assert_eq!(Level::from(LogLevel::Info), Level::INFO);
        assert_eq!(Level::from(LogLevel::Warn), Level::WARN);
        assert_eq!(Level::from(LogLevel::Error), Level::ERROR);
    }

    #[test]
    fn test_log_level_display() {
        assert_eq!(LogLevel::Info.to_string(), "info");
        assert_eq!(LogLevel::Debug.to_string(), "debug");
        assert_eq!(LogLevel::Error.to_string(), "error");
    }

    #[test]
    fn test_create_audit_log() {
        let entry = create_audit_log(
            Some("user123"),
            "login",
            Some("auth"),
            AuditResult::Success,
            HashMap::new(),
            Some("192.168.1.100"),
        );

        assert_eq!(entry.action, "login");
        assert_eq!(entry.result, AuditResult::Success);
        assert!(entry.user_id.is_some());
        assert!(entry.ip_address.is_some());
    }

    #[test]
    fn test_format_audit_log() {
        let entry = create_audit_log(
            Some("user123"),
            "login",
            None,
            AuditResult::Success,
            HashMap::new(),
            None,
        );

        let json = format_audit_log(&entry).unwrap();
        assert!(json.contains("\"action\":\"login\""));
        // Result is serialized as "Success" (variant name)
        assert!(json.contains("\"result\":\"Success\""));
    }

    #[test]
    fn test_redact_user_id() {
        assert_eq!(redact_user_id("user12345"), "u*******5");
        assert_eq!(redact_user_id("ab"), "a*");
        assert_eq!(redact_user_id("a"), "a*");
        assert_eq!(redact_user_id("ABC"), "A*C");
    }

    #[test]
    fn test_redact_ip_address() {
        assert_eq!(redact_ip_address("192.168.1.100"), "192.168.***. ***");
        assert_eq!(redact_ip_address("10.0.0.1"), "10.0.***. ***");

        // IPv6
        let ipv6 = redact_ip_address("2001:0db8:85a3:0000:0000:8a2e:0370:7334");
        assert!(ipv6.starts_with("2001:0db8:"));
    }

    #[test]
    fn test_redact_email() {
        assert_eq!(redact_email("user@example.com"), "u***@example.com");
        assert_eq!(redact_email("test@domain.org"), "t***@domain.org");
    }

    #[test]
    fn test_sanitize_log_message() {
        let msg = "User user@example.com logged in from 07123456789";
        let sanitized = sanitize_log_message(msg);
        assert!(sanitized.contains("[EMAIL_REDACTED]"));
        assert!(sanitized.contains("[PHONE_REDACTED]"));
        assert!(!sanitized.contains("user@example.com"));
    }

    #[test]
    fn test_sanitize_credit_card() {
        let msg = "Payment with card 1234 5678 9012 3456";
        let sanitized = sanitize_log_message(msg);
        assert!(sanitized.contains("[CC_REDACTED]"));
        assert!(!sanitized.contains("1234 5678"));
    }

    #[test]
    fn test_parse_log_level() {
        assert_eq!(parse_log_level("info"), Some(LogLevel::Info));
        assert_eq!(parse_log_level("INFO"), Some(LogLevel::Info));
        assert_eq!(parse_log_level("debug"), Some(LogLevel::Debug));
        assert_eq!(parse_log_level("warn"), Some(LogLevel::Warn));
        assert_eq!(parse_log_level("warning"), Some(LogLevel::Warn));
        assert_eq!(parse_log_level("invalid"), None);
    }

    #[test]
    fn test_audit_result_display() {
        assert_eq!(AuditResult::Success.to_string(), "SUCCESS");
        assert_eq!(AuditResult::Failure.to_string(), "FAILURE");
        assert_eq!(AuditResult::Denied.to_string(), "DENIED");
    }
}
