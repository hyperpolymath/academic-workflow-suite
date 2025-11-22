use criterion::{black_box, criterion_group, criterion_main, Criterion, BenchmarkId, Throughput};
use aws_core::{
    events::{Event, EventStore, EventType, EventMetadata},
    security::{Anonymizer, PIIDetector},
    tma::{TMA, TMAPart, TMAParser},
};
use std::time::Duration;
use tempfile::TempDir;
use serde_json::json;

/// Benchmark event store write performance
fn bench_event_store_write(c: &mut Criterion) {
    let mut group = c.benchmark_group("event_store_write");

    for size in [1, 10, 100, 1000].iter() {
        group.throughput(Throughput::Elements(*size as u64));
        group.bench_with_input(BenchmarkId::from_parameter(size), size, |b, &size| {
            b.iter_batched(
                || {
                    let temp_dir = TempDir::new().unwrap();
                    let store = EventStore::new(temp_dir.path()).unwrap();
                    (store, temp_dir)
                },
                |(mut store, _temp_dir)| {
                    for i in 0..size {
                        let event = Event {
                            id: format!("evt_{}", i),
                            event_type: EventType::TMASubmitted,
                            timestamp: chrono::Utc::now(),
                            user_id: format!("student_{}", i),
                            metadata: EventMetadata {
                                tma_id: Some(format!("tma_{}", i)),
                                file_hash: Some(format!("hash_{}", i)),
                                additional: json!({"index": i}),
                            },
                        };
                        store.append(black_box(event)).unwrap();
                    }
                },
                criterion::BatchSize::SmallInput,
            );
        });
    }
    group.finish();
}

/// Benchmark event store read performance
fn bench_event_store_read(c: &mut Criterion) {
    let mut group = c.benchmark_group("event_store_read");

    for size in [10, 100, 1000].iter() {
        group.throughput(Throughput::Elements(*size as u64));
        group.bench_with_input(BenchmarkId::from_parameter(size), size, |b, &size| {
            // Setup: create store with events
            let temp_dir = TempDir::new().unwrap();
            let mut store = EventStore::new(temp_dir.path()).unwrap();

            for i in 0..size {
                let event = Event {
                    id: format!("evt_{}", i),
                    event_type: EventType::TMASubmitted,
                    timestamp: chrono::Utc::now(),
                    user_id: format!("student_{}", i),
                    metadata: EventMetadata {
                        tma_id: Some(format!("tma_{}", i)),
                        file_hash: Some(format!("hash_{}", i)),
                        additional: json!({"index": i}),
                    },
                };
                store.append(event).unwrap();
            }

            b.iter(|| {
                let events = store.query_by_type(black_box(&EventType::TMASubmitted)).unwrap();
                assert_eq!(events.len(), size);
                events
            });
        });
    }
    group.finish();
}

/// Benchmark anonymization speed
fn bench_anonymization(c: &mut Criterion) {
    let mut group = c.benchmark_group("anonymization");

    let test_data = vec![
        ("simple_text", "This is a simple text without PII."),
        ("with_email", "Contact John at john.doe@example.com for more information."),
        ("with_phone", "Call me at 555-123-4567 or email support@company.org."),
        ("complex_pii", "Student ID: 12345678, Email: alice@university.edu, Phone: (555) 987-6543, Address: 123 Main St, Boston MA 02101"),
    ];

    for (name, text) in test_data.iter() {
        group.bench_with_input(BenchmarkId::new("anonymize", name), text, |b, text| {
            let anonymizer = Anonymizer::new();
            b.iter(|| {
                anonymizer.anonymize(black_box(text))
            });
        });
    }

    group.finish();
}

/// Benchmark PII detection performance
fn bench_pii_detection(c: &mut Criterion) {
    let mut group = c.benchmark_group("pii_detection");

    let test_cases = vec![
        ("clean_text", "This is a clean academic paper about quantum physics.", 0),
        ("email_only", "Please contact the author at researcher@university.edu", 1),
        ("multiple_pii", "Student: Jane Doe (ID: 98765), Email: jane@school.edu, Phone: 555-0123", 3),
        ("long_text_with_pii", &format!(
            "{} Contact: john@example.com, Phone: 555-1234, SSN: 123-45-6789",
            "Lorem ipsum ".repeat(100)
        ), 3),
    ];

    for (name, text, _expected) in test_cases.iter() {
        group.bench_with_input(BenchmarkId::new("detect", name), text, |b, text| {
            let detector = PIIDetector::new();
            b.iter(|| {
                detector.scan(black_box(text))
            });
        });
    }

    group.finish();
}

/// Benchmark TMA parsing speed
fn bench_tma_parsing(c: &mut Criterion) {
    let mut group = c.benchmark_group("tma_parsing");

    // Small TMA
    let small_tma = r#"
# Question 1
What is the capital of France?

## Answer
Paris is the capital and most populous city of France.

# Question 2
Explain quantum entanglement.

## Answer
Quantum entanglement is a physical phenomenon that occurs when pairs of particles
interact in ways such that the quantum state of each particle cannot be described
independently of the others.
"#;

    // Medium TMA (repeated content)
    let medium_tma = format!("{}\n{}\n{}", small_tma, small_tma, small_tma);

    // Large TMA
    let large_tma = format!("{}\n", medium_tma.repeat(10));

    group.throughput(Throughput::Bytes(small_tma.len() as u64));
    group.bench_function("small_tma", |b| {
        let parser = TMAParser::new();
        b.iter(|| {
            parser.parse(black_box(small_tma)).unwrap()
        });
    });

    group.throughput(Throughput::Bytes(medium_tma.len() as u64));
    group.bench_function("medium_tma", |b| {
        let parser = TMAParser::new();
        b.iter(|| {
            parser.parse(black_box(&medium_tma)).unwrap()
        });
    });

    group.throughput(Throughput::Bytes(large_tma.len() as u64));
    group.bench_function("large_tma", |b| {
        let parser = TMAParser::new();
        b.iter(|| {
            parser.parse(black_box(&large_tma)).unwrap()
        });
    });

    group.finish();
}

/// Benchmark TMA validation
fn bench_tma_validation(c: &mut Criterion) {
    let mut group = c.benchmark_group("tma_validation");

    let parser = TMAParser::new();
    let tma_text = r#"
# Question 1
What is recursion?

## Answer
Recursion is a method where the solution depends on solutions to smaller instances
of the same problem.
"#;

    let tma = parser.parse(tma_text).unwrap();

    group.bench_function("validate", |b| {
        b.iter(|| {
            black_box(&tma).validate()
        });
    });

    group.finish();
}

/// Benchmark hash computation for integrity checks
fn bench_hash_computation(c: &mut Criterion) {
    let mut group = c.benchmark_group("hash_computation");

    for size in [1024, 10240, 102400, 1024000].iter() {
        let data = vec![0u8; *size];
        group.throughput(Throughput::Bytes(*size as u64));
        group.bench_with_input(BenchmarkId::from_parameter(size), &data, |b, data| {
            use sha3::{Digest, Sha3_256};
            b.iter(|| {
                let mut hasher = Sha3_256::new();
                hasher.update(black_box(data));
                hasher.finalize()
            });
        });
    }

    group.finish();
}

criterion_group!(
    name = benches;
    config = Criterion::default()
        .measurement_time(Duration::from_secs(10))
        .sample_size(100);
    targets =
        bench_event_store_write,
        bench_event_store_read,
        bench_anonymization,
        bench_pii_detection,
        bench_tma_parsing,
        bench_tma_validation,
        bench_hash_computation
);

criterion_main!(benches);
