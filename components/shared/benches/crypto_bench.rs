//! Benchmarks for cryptographic operations.

use academic_shared::crypto::*;
use criterion::{black_box, criterion_group, criterion_main, Criterion, BenchmarkId};

fn bench_sha3_256(c: &mut Criterion) {
    let data_sizes = vec![16, 64, 256, 1024, 4096];

    for size in data_sizes {
        let data = vec![0u8; size];
        c.bench_with_input(BenchmarkId::new("sha3_256", size), &data, |b, d| {
            b.iter(|| sha3_256(black_box(d)))
        });
    }
}

fn bench_sha3_512(c: &mut Criterion) {
    let data_sizes = vec![16, 64, 256, 1024, 4096];

    for size in data_sizes {
        let data = vec![0u8; size];
        c.bench_with_input(BenchmarkId::new("sha3_512", size), &data, |b, d| {
            b.iter(|| sha3_512(black_box(d)))
        });
    }
}

fn bench_hmac(c: &mut Criterion) {
    let key = b"secret-key-for-benchmarking";
    let data = b"data to authenticate with HMAC";

    c.bench_function("hmac_sha3_256", |b| {
        b.iter(|| hmac_sha3_256(black_box(key), black_box(data)))
    });
}

fn bench_hmac_verify(c: &mut Criterion) {
    let key = b"secret-key-for-benchmarking";
    let data = b"data to authenticate with HMAC";
    let mac = hmac_sha3_256(key, data).unwrap();

    c.bench_function("verify_hmac_sha3_256", |b| {
        b.iter(|| verify_hmac_sha3_256(black_box(key), black_box(data), black_box(&mac)))
    });
}

fn bench_constant_time_compare(c: &mut Criterion) {
    let a = vec![0u8; 32];
    let b = vec![0u8; 32];

    c.bench_function("constant_time_compare", |b| {
        b.iter(|| constant_time_compare(black_box(&a), black_box(&b)))
    });
}

fn bench_uuid_generation(c: &mut Criterion) {
    c.bench_function("generate_uuid", |b| {
        b.iter(|| generate_uuid())
    });
}

fn bench_nanoid_generation(c: &mut Criterion) {
    c.bench_function("generate_nanoid", |b| {
        b.iter(|| generate_nanoid())
    });

    c.bench_function("generate_nanoid_16", |b| {
        b.iter(|| generate_nanoid_with_length(16))
    });
}

fn bench_key_derivation(c: &mut Criterion) {
    let password = b"user-password";
    let salt = b"unique-salt-per-user";

    let mut group = c.benchmark_group("key_derivation");

    for iterations in [1_000, 10_000, 100_000] {
        group.bench_with_input(
            BenchmarkId::new("pbkdf2", iterations),
            &iterations,
            |b, &iters| {
                b.iter(|| derive_key(black_box(password), black_box(salt), iters, 32))
            },
        );
    }

    group.finish();
}

criterion_group!(
    benches,
    bench_sha3_256,
    bench_sha3_512,
    bench_hmac,
    bench_hmac_verify,
    bench_constant_time_compare,
    bench_uuid_generation,
    bench_nanoid_generation,
    bench_key_derivation
);
criterion_main!(benches);
