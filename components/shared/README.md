# Academic Shared Utilities Library

A comprehensive, production-ready shared utilities library for the Academic Workflow Suite.

## Features

- **Cryptography**: Secure hashing (SHA3-256/512), HMAC, key derivation (PBKDF2), random ID generation
- **Validation**: Input validation for emails, UK phone numbers, OU student IDs, module codes, postcodes, URLs
- **Sanitization**: HTML sanitization, SQL injection prevention, XSS protection, path traversal prevention
- **Time Utilities**: Academic year calculations, timezone handling (UTC/UK), deadline management
- **Error Handling**: Comprehensive error types with user-friendly messages
- **Logging**: Structured logging with PII redaction and audit trails
- **Testing**: Mock data generators and assertion utilities

## Security Features

- **Zero unsafe code** - All implementations use safe Rust
- **Constant-time comparison** - Prevents timing attacks
- **PII redaction** - Automatic redaction in logs and error messages
- **Input validation** - Comprehensive validation before processing
- **Well-audited dependencies** - Uses established cryptographic libraries

## Installation

Add this to your `Cargo.toml`:

```toml
[dependencies]
academic-shared = { path = "../shared" }
```

## Usage Examples

### Cryptography

```rust
use academic_shared::crypto::{sha3_256_hex, generate_uuid, derive_key};

// Hash data
let hash = sha3_256_hex(b"Hello, World!");

// Generate UUIDs
let id = generate_uuid();

// Derive keys from passwords
let password = b"user-password";
let salt = b"unique-salt";
let key = derive_key(password, salt, 100_000, 32);
```

### Validation

```rust
use academic_shared::validation::{
    validate_email,
    validate_ou_student_id,
    validate_uk_phone,
};

// Validate email
assert!(validate_email("student@open.ac.uk").is_ok());

// Validate OU student ID
assert!(validate_ou_student_id("A1234567").is_ok());

// Validate UK phone number
assert!(validate_uk_phone("07123456789").is_ok());
```

### Sanitization

```rust
use academic_shared::sanitization::{
    sanitize_html,
    sanitize_filename,
    normalize_unicode,
};

// Sanitize HTML to prevent XSS
let clean = sanitize_html("<script>alert('xss')</script>Hello");

// Sanitize filenames to prevent path traversal
let safe_name = sanitize_filename("../../../etc/passwd");

// Normalize Unicode to prevent normalization attacks
let normalized = normalize_unicode("Café");
```

### Time Utilities

```rust
use academic_shared::time::{
    get_academic_year,
    format_academic_year,
    is_deadline_soon,
};
use chrono::NaiveDate;

// Get academic year
let date = NaiveDate::from_ymd_opt(2024, 10, 1).unwrap();
let year = get_academic_year(&date);
println!("Academic year: {}", format_academic_year(year));

// Check deadlines
let deadline = chrono::Utc::now() + chrono::Duration::days(3);
if is_deadline_soon(&deadline, 7) {
    println!("Deadline is soon!");
}
```

### Logging with Audit Trails

```rust
use academic_shared::logging::{
    create_audit_log,
    AuditResult,
    format_audit_log,
};
use std::collections::HashMap;

let entry = create_audit_log(
    Some("A1234567"),
    "submit_assignment",
    Some("assignment_system"),
    AuditResult::Success,
    HashMap::new(),
    Some("192.168.1.100"),
);

let json = format_audit_log(&entry).unwrap();
```

### Testing Utilities

```rust
use academic_shared::testing::{
    MockUser,
    MockModule,
    mock_email,
    assert_contains,
};

// Generate mock data
let user = MockUser::new();
let module = MockModule::with_code("TM112");

// Use assertion helpers
assert_contains("Hello, World!", "World");
```

## Testing

Run the test suite:

```bash
# Unit tests
cargo test

# Integration tests
cargo test --test integration_test

# Property-based tests
cargo test --test property_tests

# All tests with output
cargo test -- --nocapture
```

## Benchmarks

Run performance benchmarks:

```bash
# All benchmarks
cargo bench

# Specific benchmark
cargo bench --bench crypto_bench
cargo bench --bench validation_bench
```

## Development

### Code Standards

- All code must be safe Rust (no `unsafe`)
- Comprehensive documentation for public APIs
- Unit tests for all functions
- Property-based tests for critical functionality
- Performance benchmarks for hot paths

### Adding New Features

1. Add implementation to appropriate module
2. Add comprehensive documentation
3. Add unit tests
4. Add property-based tests if applicable
5. Add benchmarks if performance-critical
6. Update this README

## Performance

The library is optimized for production use:

- Efficient algorithms and data structures
- Minimal allocations where possible
- Benchmarked and profiled critical paths
- Release builds with LTO and optimization

## Dependencies

Core dependencies:

- `sha3` - SHA-3 hashing
- `hmac` - HMAC generation
- `pbkdf2` - Key derivation
- `uuid` - UUID generation
- `nanoid` - Short ID generation
- `chrono` - Date/time handling
- `regex` - Pattern matching
- `ammonia` - HTML sanitization
- `tracing` - Structured logging

## License

GPL-3.0 - See LICENSE file for details

## Contributing

This library is part of the Academic Workflow Suite. See the main project README for contribution guidelines.

## Support

For issues or questions, please file an issue on the main project repository.
