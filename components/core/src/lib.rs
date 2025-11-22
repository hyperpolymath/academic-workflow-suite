//! Academic Workflow Suite - Core Engine
//!
//! This library provides the core functionality for the TMA marking automation system,
//! including event sourcing, TMA processing, privacy-first anonymization, and AI integration.
//!
//! # Architecture
//!
//! The system is built on several key principles:
//! - **Event Sourcing**: All state changes are recorded as events for full audit trail
//! - **Privacy First**: Student data is anonymized before AI processing
//! - **IPC Communication**: AI processing happens in isolated jail via stdin/stdout
//! - **WASM Compatible**: Core logic designed to run in LibreOffice extension
//!
//! # Example
//!
//! ```no_run
//! use aws_core::{TMA, SecurityService};
//!
//! # async fn example() -> anyhow::Result<()> {
//! let tma = TMA::new(
//!     "student123".to_string(),
//!     "TM112".to_string(),
//!     1,
//!     "My answer...".to_string(),
//!     "Rubric criteria...".to_string(),
//! );
//!
//! let security = SecurityService::new();
//! let anonymized = security.anonymize_student_id(&tma.student_id)?;
//! # Ok(())
//! # }
//! ```

pub mod events;
pub mod tma;
pub mod security;
pub mod feedback;
pub mod ipc;

// Re-export main types for convenience
pub use events::{Event, EventStore, EventType, LmdbEventStore};
pub use tma::{TMA, TMAStatus, ValidationError};
pub use security::{SecurityService, AnonymizationResult, PIIDetectionResult};
pub use feedback::{FeedbackRequest, FeedbackResponse, FeedbackService};
pub use ipc::{IPCClient, AsyncIPCClient, IPCMessage, IPCError};

/// Result type used throughout the library
pub type Result<T> = std::result::Result<T, anyhow::Error>;

/// Library version
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_version() {
        assert!(!VERSION.is_empty());
    }
}
