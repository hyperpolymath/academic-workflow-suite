# AWS Core Engine

Production-ready Rust core engine for the Academic Workflow Suite (AWS) TMA marking automation system.

## Overview

The core engine provides privacy-first TMA processing with event sourcing, security, and AI integration capabilities for Open University lecturers.

## Features

### Event Sourcing (`src/events.rs`)
- **Complete audit trail** - All state changes recorded as immutable events
- **LMDB persistence** - High-performance embedded database with ACID guarantees
- **Event types**: TMASubmitted, FeedbackGenerated, GradeAssigned, StudentAnonymized
- **Event replay** - Rebuild state from event log
- **Projections** - Query and aggregate events

### TMA Processing (`src/tma.rs`)
- **TMA data structures** - Student submissions with validation
- **Module code validation** - Open University format (e.g., TM112, M250)
- **Rubric parsing** - Extract structured marking criteria
- **Status tracking** - Submitted → Anonymizing → Processing → FeedbackGenerated → Graded
- **Content validation** - Length limits, required fields

### Security & Privacy (`src/security.rs`)
- **One-way hashing** - SHA3-256 student ID anonymization
- **PII detection** - Regex-based detection of:
  - Email addresses
  - Phone numbers
  - UK postal codes
  - URLs
  - Student IDs
- **Content sanitization** - Remove PII before AI processing
- **Output validation** - Ensure AI responses contain no PII
- **Redaction reporting** - Audit trail of sanitization operations

### Feedback Generation (`src/feedback.rs`)
- **Rubric-aligned feedback** - Structured responses per criterion
- **Mock mode** - Testing without AI jail
- **Quality validation** - Minimum length, score ranges
- **Suggestion extraction** - Parse actionable improvements
- **Strengths identification** - Highlight positive aspects

### IPC Communication (`src/ipc.rs`)
- **Stdin/stdout protocol** - JSON message-based communication
- **AI jail integration** - Firejail/bubblewrap support
- **Async and sync clients** - Tokio-based and blocking variants
- **Message types**:
  - FeedbackRequest/Response
  - Ping/Pong (health checks)
  - Error handling
  - Shutdown coordination
- **Timeout handling** - Configurable request timeouts
- **Builder pattern** - Easy configuration

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    TMA Submission                        │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│              Security Layer (Anonymization)              │
│  • Hash student ID (SHA3-256)                           │
│  • Detect & remove PII                                  │
│  • Create audit events                                  │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│              Event Store (LMDB)                         │
│  • Persist TMASubmitted event                           │
│  • Persist StudentAnonymized event                      │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│         Feedback Service (IPC Coordinator)              │
│  • Send sanitized content to AI jail                    │
│  • Receive generated feedback                           │
│  • Validate output for PII                              │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                Event Store (LMDB)                       │
│  • Persist FeedbackGenerated event                      │
│  • Persist GradeAssigned event                          │
└─────────────────────────────────────────────────────────┘
```

## Usage

```rust
use aws_core::{TMA, SecurityService, FeedbackService, LmdbEventStore};

// Create TMA submission
let tma = TMA::new(
    "student123".to_string(),
    "TM112".to_string(),
    1,
    "My answer to question 1...".to_string(),
    "Rubric: Award marks for...".to_string(),
);

// Validate
tma.validate()?;

// Anonymize
let security = SecurityService::new();
let anon_result = security.anonymize_student_id(&tma.student_id)?;

// Store events
let event_store = LmdbEventStore::new("./data/events", None)?;

// Generate feedback
let mut feedback_service = FeedbackService::new(security);
let feedback = feedback_service.generate_feedback(&tma).await?;
```

## Testing

```bash
# Run all tests
cargo test

# Run with verbose output
cargo test -- --nocapture

# Run specific test
cargo test test_anonymize_student_id

# Check compilation
cargo check
```

## Test Coverage

- **49 unit tests** covering all modules
- **Event sourcing**: Event creation, storage, retrieval, projections
- **TMA processing**: Validation, module codes, rubric parsing
- **Security**: Anonymization, PII detection, sanitization, validation
- **Feedback**: Request/response, extraction, validation
- **IPC**: Message serialization, builder pattern

## Dependencies

- **tokio**: Async runtime
- **serde/serde_json**: Serialization
- **uuid**: Unique identifiers
- **sha3**: Cryptographic hashing
- **heed**: LMDB wrapper (using JSON codec for tagged enums)
- **tracing**: Structured logging
- **anyhow/thiserror**: Error handling
- **regex**: PII pattern matching
- **chrono**: Timestamps

## WASM Compatibility

The core is designed with WASM compatibility in mind for future LibreOffice extension support:
- No_std compatible where possible
- getrandom with js feature for WASM
- Minimal system dependencies

## Privacy-First Design

1. **Anonymize Before AI**: Student IDs are one-way hashed before any AI processing
2. **PII Detection**: Multiple layers scan for personally identifiable information
3. **Sanitization**: Content is cleaned before leaving the system boundary
4. **Output Validation**: AI responses are validated to ensure no PII leakage
5. **Event Sourcing**: Complete audit trail of all operations
6. **Redaction Reports**: Track what was sanitized and when

## Performance

- **LMDB**: Zero-copy reads, ACID transactions
- **JSON codec**: Human-readable events (trade-off for tagged enum support)
- **Async I/O**: Non-blocking AI jail communication
- **Efficient hashing**: SHA3-256 for secure anonymization

## Future Enhancements

- [ ] Batch TMA processing
- [ ] Advanced rubric parsing (ML-based)
- [ ] Multi-language support
- [ ] Compression for large TMAs
- [ ] Distributed event store
- [ ] Real-time feedback streaming
- [ ] Enhanced PII detection (ML models)
- [ ] LibreOffice extension integration

## License

MIT (matching parent project)

## Version

0.1.0 - Initial release
