use criterion::{black_box, criterion_group, criterion_main, Criterion, BenchmarkId, Throughput};
use heed::{EnvOpenOptions, Database};
use heed::types::*;
use std::time::Duration;
use tempfile::TempDir;
use rand::{Rng, thread_rng};
use serde::{Serialize, Deserialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
struct TestEvent {
    id: String,
    timestamp: i64,
    user_id: String,
    event_type: String,
    data: Vec<u8>,
}

impl TestEvent {
    fn generate(id: usize, data_size: usize) -> Self {
        let mut rng = thread_rng();
        let data: Vec<u8> = (0..data_size).map(|_| rng.gen()).collect();

        Self {
            id: format!("evt_{:08}", id),
            timestamp: chrono::Utc::now().timestamp(),
            user_id: format!("user_{}", id % 100),
            event_type: format!("type_{}", id % 10),
            data,
        }
    }
}

/// Benchmark write performance (events/sec)
fn bench_lmdb_write(c: &mut Criterion) {
    let mut group = c.benchmark_group("lmdb_write");

    for count in [10, 100, 1000, 10000].iter() {
        group.throughput(Throughput::Elements(*count as u64));
        group.bench_with_input(BenchmarkId::from_parameter(count), count, |b, &count| {
            b.iter_batched(
                || {
                    let dir = TempDir::new().unwrap();
                    let env = EnvOpenOptions::new()
                        .map_size(10 * 1024 * 1024 * 1024) // 10GB
                        .max_dbs(10)
                        .open(dir.path())
                        .unwrap();

                    let db: Database<Str, SerdeBincode<TestEvent>> = env.create_database(Some("events")).unwrap();
                    let events: Vec<TestEvent> = (0..count).map(|i| TestEvent::generate(i, 256)).collect();

                    (env, db, events, dir)
                },
                |(env, db, events, _dir)| {
                    let mut wtxn = env.write_txn().unwrap();
                    for event in events {
                        db.put(&mut wtxn, &event.id, &event).unwrap();
                    }
                    wtxn.commit().unwrap();
                },
                criterion::BatchSize::SmallInput,
            );
        });
    }

    group.finish();
}

/// Benchmark read performance
fn bench_lmdb_read(c: &mut Criterion) {
    let mut group = c.benchmark_group("lmdb_read");

    for count in [10, 100, 1000, 10000].iter() {
        group.throughput(Throughput::Elements(*count as u64));
        group.bench_with_input(BenchmarkId::from_parameter(count), count, |b, &count| {
            // Setup
            let dir = TempDir::new().unwrap();
            let env = EnvOpenOptions::new()
                .map_size(10 * 1024 * 1024 * 1024)
                .max_dbs(10)
                .open(dir.path())
                .unwrap();

            let db: Database<Str, SerdeBincode<TestEvent>> = env.create_database(Some("events")).unwrap();

            // Populate
            let mut wtxn = env.write_txn().unwrap();
            for i in 0..count {
                let event = TestEvent::generate(i, 256);
                db.put(&mut wtxn, &event.id, &event).unwrap();
            }
            wtxn.commit().unwrap();

            b.iter(|| {
                let rtxn = env.read_txn().unwrap();
                for i in 0..count {
                    let key = format!("evt_{:08}", i);
                    let _event = db.get(&rtxn, &key).unwrap();
                    black_box(_event);
                }
            });
        });
    }

    group.finish();
}

/// Benchmark range query speed
fn bench_lmdb_range_query(c: &mut Criterion) {
    let mut group = c.benchmark_group("lmdb_range_query");

    let dir = TempDir::new().unwrap();
    let env = EnvOpenOptions::new()
        .map_size(10 * 1024 * 1024 * 1024)
        .max_dbs(10)
        .open(dir.path())
        .unwrap();

    let db: Database<Str, SerdeBincode<TestEvent>> = env.create_database(Some("events")).unwrap();

    // Populate with 10k records
    let mut wtxn = env.write_txn().unwrap();
    for i in 0..10000 {
        let event = TestEvent::generate(i, 256);
        db.put(&mut wtxn, &event.id, &event).unwrap();
    }
    wtxn.commit().unwrap();

    for range_size in [10, 100, 1000].iter() {
        group.throughput(Throughput::Elements(*range_size as u64));
        group.bench_with_input(
            BenchmarkId::from_parameter(range_size),
            range_size,
            |b, &range_size| {
                b.iter(|| {
                    let rtxn = env.read_txn().unwrap();
                    let start_key = "evt_00000000";
                    let end_key = format!("evt_{:08}", range_size);

                    let mut count = 0;
                    for result in db.range(&rtxn, &(start_key..end_key.as_str())).unwrap() {
                        black_box(result.unwrap());
                        count += 1;
                    }

                    assert!(count > 0);
                    count
                });
            },
        );
    }

    group.finish();
}

/// Benchmark transaction overhead
fn bench_lmdb_transaction(c: &mut Criterion) {
    let mut group = c.benchmark_group("lmdb_transaction");

    let dir = TempDir::new().unwrap();
    let env = EnvOpenOptions::new()
        .map_size(10 * 1024 * 1024 * 1024)
        .max_dbs(10)
        .open(dir.path())
        .unwrap();

    let db: Database<Str, SerdeBincode<TestEvent>> = env.create_database(Some("events")).unwrap();

    group.bench_function("write_txn_overhead", |b| {
        b.iter(|| {
            let mut wtxn = env.write_txn().unwrap();
            let event = TestEvent::generate(0, 256);
            db.put(&mut wtxn, &event.id, &event).unwrap();
            wtxn.commit().unwrap();
        });
    });

    group.bench_function("read_txn_overhead", |b| {
        // Populate one record
        let mut wtxn = env.write_txn().unwrap();
        let event = TestEvent::generate(0, 256);
        db.put(&mut wtxn, &event.id, &event).unwrap();
        wtxn.commit().unwrap();

        b.iter(|| {
            let rtxn = env.read_txn().unwrap();
            let _event = db.get(&rtxn, "evt_00000000").unwrap();
            black_box(_event);
        });
    });

    group.finish();
}

/// Benchmark database size vs performance
fn bench_lmdb_size_vs_perf(c: &mut Criterion) {
    let mut group = c.benchmark_group("lmdb_size_vs_perf");
    group.sample_size(20);
    group.measurement_time(Duration::from_secs(15));

    for db_size in [1000, 10000, 100000].iter() {
        group.bench_with_input(
            BenchmarkId::new("write_to_size", db_size),
            db_size,
            |b, &db_size| {
                b.iter_batched(
                    || {
                        let dir = TempDir::new().unwrap();
                        let env = EnvOpenOptions::new()
                            .map_size(10 * 1024 * 1024 * 1024)
                            .max_dbs(10)
                            .open(dir.path())
                            .unwrap();

                        let db: Database<Str, SerdeBincode<TestEvent>> =
                            env.create_database(Some("events")).unwrap();

                        // Pre-populate
                        let mut wtxn = env.write_txn().unwrap();
                        for i in 0..db_size {
                            let event = TestEvent::generate(i, 256);
                            db.put(&mut wtxn, &event.id, &event).unwrap();
                        }
                        wtxn.commit().unwrap();

                        (env, db, dir)
                    },
                    |(env, db, _dir)| {
                        // Write one more record
                        let mut wtxn = env.write_txn().unwrap();
                        let event = TestEvent::generate(99999999, 256);
                        db.put(&mut wtxn, &event.id, &event).unwrap();
                        wtxn.commit().unwrap();
                    },
                    criterion::BatchSize::SmallInput,
                );
            },
        );
    }

    group.finish();
}

/// Benchmark bulk insert performance
fn bench_lmdb_bulk_insert(c: &mut Criterion) {
    let mut group = c.benchmark_group("lmdb_bulk_insert");

    for batch_size in [100, 1000, 10000].iter() {
        group.throughput(Throughput::Elements(*batch_size as u64));
        group.bench_with_input(
            BenchmarkId::from_parameter(batch_size),
            batch_size,
            |b, &batch_size| {
                b.iter_batched(
                    || {
                        let dir = TempDir::new().unwrap();
                        let env = EnvOpenOptions::new()
                            .map_size(10 * 1024 * 1024 * 1024)
                            .max_dbs(10)
                            .open(dir.path())
                            .unwrap();

                        let db: Database<Str, SerdeBincode<TestEvent>> =
                            env.create_database(Some("events")).unwrap();

                        let events: Vec<TestEvent> = (0..batch_size)
                            .map(|i| TestEvent::generate(i, 256))
                            .collect();

                        (env, db, events, dir)
                    },
                    |(env, db, events, _dir)| {
                        let mut wtxn = env.write_txn().unwrap();
                        for event in events {
                            db.put(&mut wtxn, &event.id, &event).unwrap();
                        }
                        wtxn.commit().unwrap();
                    },
                    criterion::BatchSize::SmallInput,
                );
            },
        );
    }

    group.finish();
}

/// Benchmark different value sizes
fn bench_lmdb_value_size(c: &mut Criterion) {
    let mut group = c.benchmark_group("lmdb_value_size");

    for size in [64, 256, 1024, 4096, 16384].iter() {
        group.throughput(Throughput::Bytes(*size as u64));
        group.bench_with_input(BenchmarkId::from_parameter(size), size, |b, &size| {
            let dir = TempDir::new().unwrap();
            let env = EnvOpenOptions::new()
                .map_size(10 * 1024 * 1024 * 1024)
                .max_dbs(10)
                .open(dir.path())
                .unwrap();

            let db: Database<Str, SerdeBincode<TestEvent>> =
                env.create_database(Some("events")).unwrap();

            b.iter(|| {
                let mut wtxn = env.write_txn().unwrap();
                let event = TestEvent::generate(0, size);
                db.put(&mut wtxn, &event.id, &event).unwrap();
                wtxn.commit().unwrap();
            });
        });
    }

    group.finish();
}

criterion_group!(
    name = benches;
    config = Criterion::default()
        .measurement_time(Duration::from_secs(10))
        .sample_size(50);
    targets =
        bench_lmdb_write,
        bench_lmdb_read,
        bench_lmdb_range_query,
        bench_lmdb_transaction,
        bench_lmdb_size_vs_perf,
        bench_lmdb_bulk_insert,
        bench_lmdb_value_size
);

criterion_main!(benches);
