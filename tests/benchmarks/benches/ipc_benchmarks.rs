use criterion::{black_box, criterion_group, criterion_main, Criterion, BenchmarkId, Throughput};
use aws_core::ipc::{IPCMessage, IPCRequest, IPCResponse, IPCTransport};
use serde_json::json;
use std::time::Duration;
use tokio::runtime::Runtime;

/// Benchmark message serialization
fn bench_message_serialization(c: &mut Criterion) {
    let mut group = c.benchmark_group("ipc_serialization");

    // Small message
    let small_msg = IPCRequest::SubmitTMA {
        tma_id: "tma_001".to_string(),
        content: "Short content".to_string(),
        metadata: json!({"type": "small"}),
    };

    // Medium message
    let medium_msg = IPCRequest::SubmitTMA {
        tma_id: "tma_002".to_string(),
        content: "Lorem ipsum ".repeat(100),
        metadata: json!({
            "type": "medium",
            "sections": ["intro", "body", "conclusion"],
            "word_count": 1000
        }),
    };

    // Large message
    let large_msg = IPCRequest::SubmitTMA {
        tma_id: "tma_003".to_string(),
        content: "Lorem ipsum dolor sit amet ".repeat(1000),
        metadata: json!({
            "type": "large",
            "attachments": vec!["file1.pdf", "file2.pdf"],
            "references": (0..50).map(|i| format!("ref_{}", i)).collect::<Vec<_>>()
        }),
    };

    group.bench_function("serialize_small", |b| {
        b.iter(|| {
            serde_json::to_string(black_box(&small_msg)).unwrap()
        });
    });

    group.bench_function("serialize_medium", |b| {
        b.iter(|| {
            serde_json::to_string(black_box(&medium_msg)).unwrap()
        });
    });

    group.bench_function("serialize_large", |b| {
        b.iter(|| {
            serde_json::to_string(black_box(&large_msg)).unwrap()
        });
    });

    group.finish();
}

/// Benchmark message deserialization
fn bench_message_deserialization(c: &mut Criterion) {
    let mut group = c.benchmark_group("ipc_deserialization");

    let small_json = r#"{"SubmitTMA":{"tma_id":"tma_001","content":"Short content","metadata":{"type":"small"}}}"#;

    let medium_json = serde_json::to_string(&IPCRequest::SubmitTMA {
        tma_id: "tma_002".to_string(),
        content: "Lorem ipsum ".repeat(100),
        metadata: json!({"type": "medium"}),
    }).unwrap();

    let large_json = serde_json::to_string(&IPCRequest::SubmitTMA {
        tma_id: "tma_003".to_string(),
        content: "Lorem ipsum dolor sit amet ".repeat(1000),
        metadata: json!({"type": "large"}),
    }).unwrap();

    group.bench_function("deserialize_small", |b| {
        b.iter(|| {
            serde_json::from_str::<IPCRequest>(black_box(small_json)).unwrap()
        });
    });

    group.bench_function("deserialize_medium", |b| {
        b.iter(|| {
            serde_json::from_str::<IPCRequest>(black_box(&medium_json)).unwrap()
        });
    });

    group.bench_function("deserialize_large", |b| {
        b.iter(|| {
            serde_json::from_str::<IPCRequest>(black_box(&large_json)).unwrap()
        });
    });

    group.finish();
}

/// Benchmark stdin/stdout throughput
fn bench_stdio_throughput(c: &mut Criterion) {
    let mut group = c.benchmark_group("stdio_throughput");

    for msg_count in [10, 100, 1000].iter() {
        group.throughput(Throughput::Elements(*msg_count as u64));
        group.bench_with_input(
            BenchmarkId::from_parameter(msg_count),
            msg_count,
            |b, &count| {
                b.iter(|| {
                    let messages: Vec<String> = (0..count)
                        .map(|i| {
                            let msg = IPCRequest::SubmitTMA {
                                tma_id: format!("tma_{:04}", i),
                                content: format!("Content for TMA {}", i),
                                metadata: json!({"index": i}),
                            };
                            serde_json::to_string(&msg).unwrap()
                        })
                        .collect();

                    // Simulate processing
                    for msg in messages {
                        black_box(msg.len());
                    }
                });
            },
        );
    }

    group.finish();
}

/// Benchmark request/response roundtrip latency
fn bench_request_response_latency(c: &mut Criterion) {
    let rt = Runtime::new().unwrap();
    let mut group = c.benchmark_group("request_response_latency");

    group.bench_function("simple_echo", |b| {
        b.to_async(&rt).iter(|| async {
            let request = IPCRequest::SubmitTMA {
                tma_id: "tma_test".to_string(),
                content: "Test content".to_string(),
                metadata: json!({}),
            };

            // Simulate serialization + deserialization + processing
            let serialized = serde_json::to_string(&request).unwrap();
            let deserialized = serde_json::from_str::<IPCRequest>(&serialized).unwrap();

            let response = IPCResponse::Success {
                result: json!({"status": "ok"}),
            };

            let response_serialized = serde_json::to_string(&response).unwrap();
            black_box(response_serialized)
        });
    });

    group.bench_function("with_processing", |b| {
        b.to_async(&rt).iter(|| async {
            let request = IPCRequest::SubmitTMA {
                tma_id: "tma_test".to_string(),
                content: "Lorem ipsum ".repeat(50),
                metadata: json!({"word_count": 100}),
            };

            let serialized = serde_json::to_string(&request).unwrap();
            let deserialized = serde_json::from_str::<IPCRequest>(&serialized).unwrap();

            // Simulate some processing
            if let IPCRequest::SubmitTMA { content, .. } = deserialized {
                let _word_count = content.split_whitespace().count();
            }

            let response = IPCResponse::Success {
                result: json!({"processed": true}),
            };

            let response_serialized = serde_json::to_string(&response).unwrap();
            black_box(response_serialized)
        });
    });

    group.finish();
}

/// Benchmark concurrent request handling
fn bench_concurrent_requests(c: &mut Criterion) {
    let rt = Runtime::new().unwrap();
    let mut group = c.benchmark_group("concurrent_requests");

    for concurrent in [1, 5, 10, 20].iter() {
        group.throughput(Throughput::Elements(*concurrent as u64));
        group.bench_with_input(
            BenchmarkId::from_parameter(concurrent),
            concurrent,
            |b, &concurrent| {
                b.to_async(&rt).iter(|| async move {
                    let handles: Vec<_> = (0..concurrent)
                        .map(|i| {
                            tokio::spawn(async move {
                                let request = IPCRequest::SubmitTMA {
                                    tma_id: format!("tma_{}", i),
                                    content: format!("Content {}", i),
                                    metadata: json!({"id": i}),
                                };

                                let serialized = serde_json::to_string(&request).unwrap();
                                let _deserialized = serde_json::from_str::<IPCRequest>(&serialized).unwrap();

                                serialized.len()
                            })
                        })
                        .collect();

                    for handle in handles {
                        black_box(handle.await.unwrap());
                    }
                });
            },
        );
    }

    group.finish();
}

/// Benchmark message framing overhead
fn bench_message_framing(c: &mut Criterion) {
    let mut group = c.benchmark_group("message_framing");

    let messages = vec![
        ("tiny", "x"),
        ("small", &"x".repeat(100)),
        ("medium", &"x".repeat(1000)),
        ("large", &"x".repeat(10000)),
    ];

    for (name, content) in messages {
        group.throughput(Throughput::Bytes(content.len() as u64));
        group.bench_with_input(BenchmarkId::new("frame", name), &content, |b, content| {
            b.iter(|| {
                // Simulate length-prefixed framing
                let len = content.len() as u32;
                let len_bytes = len.to_le_bytes();
                let mut framed = Vec::with_capacity(4 + content.len());
                framed.extend_from_slice(&len_bytes);
                framed.extend_from_slice(content.as_bytes());
                black_box(framed)
            });
        });
    }

    group.finish();
}

/// Benchmark error handling overhead
fn bench_error_handling(c: &mut Criterion) {
    let mut group = c.benchmark_group("error_handling");

    group.bench_function("success_path", |b| {
        b.iter(|| {
            let result: Result<IPCResponse, String> = Ok(IPCResponse::Success {
                result: json!({"status": "ok"}),
            });
            black_box(result).unwrap()
        });
    });

    group.bench_function("error_path", |b| {
        b.iter(|| {
            let result: Result<IPCResponse, String> = Err("Test error".to_string());
            black_box(result).unwrap_or_else(|e| IPCResponse::Error {
                message: e,
                code: 500,
            })
        });
    });

    group.finish();
}

criterion_group!(
    name = benches;
    config = Criterion::default()
        .measurement_time(Duration::from_secs(10))
        .sample_size(100);
    targets =
        bench_message_serialization,
        bench_message_deserialization,
        bench_stdio_throughput,
        bench_request_response_latency,
        bench_concurrent_requests,
        bench_message_framing,
        bench_error_handling
);

criterion_main!(benches);
