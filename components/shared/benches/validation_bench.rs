//! Benchmarks for validation operations.

use academic_shared::validation::*;
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn bench_validate_email(c: &mut Criterion) {
    let valid_email = "test.user@example.com";
    let invalid_email = "not-an-email";

    c.bench_function("validate_email_valid", |b| {
        b.iter(|| validate_email(black_box(valid_email)))
    });

    c.bench_function("validate_email_invalid", |b| {
        b.iter(|| validate_email(black_box(invalid_email)))
    });
}

fn bench_validate_uk_phone(c: &mut Criterion) {
    let valid_phone = "07123456789";
    let invalid_phone = "123";

    c.bench_function("validate_uk_phone_valid", |b| {
        b.iter(|| validate_uk_phone(black_box(valid_phone)))
    });

    c.bench_function("validate_uk_phone_invalid", |b| {
        b.iter(|| validate_uk_phone(black_box(invalid_phone)))
    });
}

fn bench_validate_student_id(c: &mut Criterion) {
    let valid_id = "A1234567";
    let invalid_id = "invalid";

    c.bench_function("validate_ou_student_id_valid", |b| {
        b.iter(|| validate_ou_student_id(black_box(valid_id)))
    });

    c.bench_function("validate_ou_student_id_invalid", |b| {
        b.iter(|| validate_ou_student_id(black_box(invalid_id)))
    });
}

fn bench_validate_module_code(c: &mut Criterion) {
    let valid_code = "TM112";
    let invalid_code = "INVALID";

    c.bench_function("validate_ou_module_code_valid", |b| {
        b.iter(|| validate_ou_module_code(black_box(valid_code)))
    });

    c.bench_function("validate_ou_module_code_invalid", |b| {
        b.iter(|| validate_ou_module_code(black_box(invalid_code)))
    });
}

fn bench_validate_postcode(c: &mut Criterion) {
    let valid_postcode = "SW1A 1AA";
    let invalid_postcode = "invalid";

    c.bench_function("validate_uk_postcode_valid", |b| {
        b.iter(|| validate_uk_postcode(black_box(valid_postcode)))
    });

    c.bench_function("validate_uk_postcode_invalid", |b| {
        b.iter(|| validate_uk_postcode(black_box(invalid_postcode)))
    });
}

fn bench_validate_url(c: &mut Criterion) {
    let valid_url = "https://www.example.com/path?query=value";
    let invalid_url = "not-a-url";

    c.bench_function("validate_url_valid", |b| {
        b.iter(|| validate_url(black_box(valid_url)))
    });

    c.bench_function("validate_url_invalid", |b| {
        b.iter(|| validate_url(black_box(invalid_url)))
    });
}

fn bench_validate_length(c: &mut Criterion) {
    let text = "This is a test string";

    c.bench_function("validate_length", |b| {
        b.iter(|| validate_length(black_box(text), "test", 1, 100))
    });
}

fn bench_validate_range(c: &mut Criterion) {
    c.bench_function("validate_range", |b| {
        b.iter(|| validate_range(black_box(50), "test", 0, 100))
    });
}

criterion_group!(
    benches,
    bench_validate_email,
    bench_validate_uk_phone,
    bench_validate_student_id,
    bench_validate_module_code,
    bench_validate_postcode,
    bench_validate_url,
    bench_validate_length,
    bench_validate_range
);
criterion_main!(benches);
