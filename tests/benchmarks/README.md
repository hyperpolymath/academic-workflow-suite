# Performance Benchmarking Suite

Comprehensive performance benchmarking infrastructure for the Academic Workflow Suite.

## Overview

This benchmarking suite provides:

- **Rust Benchmarks**: Criterion-based microbenchmarks for core components
- **AI Inference Benchmarks**: Model loading, inference latency, and throughput testing
- **Backend Load Tests**: Locust and k6 for API endpoint stress testing
- **Database Benchmarks**: LMDB and PostgreSQL performance analysis
- **Integration Benchmarks**: End-to-end workflow performance
- **Profiling Tools**: CPU, memory, and GPU profiling scripts
- **Automated Reporting**: Generate HTML, Markdown, and JSON reports
- **Regression Detection**: Compare against baselines and detect performance degradation

## Quick Start

### Run All Benchmarks

```bash
cd tests/benchmarks
./run_all_benchmarks.sh
```

This will:
1. Detect hardware configuration
2. Build all components in release mode
3. Run all benchmark suites
4. Compare against baselines
5. Generate comprehensive reports

### Run Specific Benchmark Categories

```bash
# Rust/Criterion benchmarks only
./run_all_benchmarks.sh --rust

# AI inference benchmarks only
./run_all_benchmarks.sh --ai

# Integration benchmarks only
./run_all_benchmarks.sh --integration

# With profiling enabled
./run_all_benchmarks.sh --profiling
```

## Benchmark Categories

### 1. Rust/Criterion Benchmarks

Located in `benches/`:

#### Core Benchmarks (`core_benchmarks.rs`)
- Event store write/read performance
- Anonymization speed
- PII detection performance
- TMA parsing speed
- Hash computation
- Validation performance

```bash
cargo bench --bench core_benchmarks
```

#### IPC Benchmarks (`ipc_benchmarks.rs`)
- Message serialization/deserialization
- Stdin/stdout throughput
- Request/response latency
- Concurrent request handling
- Message framing overhead

```bash
cargo bench --bench ipc_benchmarks
```

#### Database Benchmarks (`lmdb_bench.rs`)
- Write performance (events/sec)
- Read performance
- Range query speed
- Transaction overhead
- Database size vs performance
- Bulk insert performance

```bash
cargo bench --bench lmdb_bench
```

#### AI Benchmarks (`ai_benchmarks.rs`)
- Model loading time
- Inference latency by token count
- Throughput (tokens/second)
- Memory usage
- Batch inference
- Quantization comparison (FP16, Q8, Q4)

```bash
cargo bench --bench ai_benchmarks
```

### 2. Backend Load Tests

#### Locust Load Testing

Test API endpoints under various load conditions:

```bash
cd load_tests

# Light load (1-10 users)
locust -f locust_config.py --host=http://localhost:8000 --users 10 --spawn-rate 1 --run-time 5m --class LightLoad

# Medium load (10-50 users)
locust -f locust_config.py --host=http://localhost:8000 --users 50 --spawn-rate 2 --run-time 10m --class MediumLoad

# Heavy load (50-100+ users)
locust -f locust_config.py --host=http://localhost:8000 --users 100 --spawn-rate 5 --run-time 15m --class HeavyLoad

# Web UI mode
locust -f locust_config.py --host=http://localhost:8000
# Then open http://localhost:8089
```

**Test Scenarios:**
- TMA submission workflow
- Feedback generation
- Status checking
- Burst traffic patterns
- Sustained load testing

#### k6 Load Testing

Alternative load testing with k6:

```bash
cd load_tests

# Default scenario
k6 run k6_script.js

# Custom configuration
k6 run --vus 50 --duration 5m k6_script.js

# With environment variables
BASE_URL=http://production.example.com k6 run k6_script.js

# Generate summary
k6 run --out json=results.json k6_script.js
```

**Test Types:**
- Smoke tests
- Load tests
- Stress tests
- Spike tests
- Soak tests

### 3. Integration Benchmarks

End-to-end performance testing:

```bash
./integration_bench.sh
```

**Measures:**
- End-to-end TMA marking time
- Batch processing throughput
- Cold start vs warm start performance
- AI model loading time
- Database operations

**Configuration:**
```bash
# Custom number of iterations
NUM_ITERATIONS=20 ./integration_bench.sh

# Custom warmup iterations
WARMUP_ITERATIONS=5 ./integration_bench.sh
```

### 4. Profiling

#### CPU Profiling

Profile CPU usage and generate flamegraphs:

```bash
./profile_cpu.sh
```

**Generates:**
- Flamegraphs (SVG)
- perf reports
- Hotspot analysis
- Cache performance metrics

**Requirements:**
- `perf` (Linux performance tools)
- `flamegraph` (cargo install flamegraph)

**Outputs:**
- `reports/profiling/cpu/core_cpu.svg` - Flamegraph for core component
- `reports/profiling/cpu/core_cpu_report.txt` - Detailed perf report
- `reports/profiling/cpu/hotspots_*.txt` - CPU hotspot analysis

#### Memory Profiling

Profile memory usage and detect leaks:

```bash
./profile_memory.sh
```

**Tools Used:**
- Valgrind Massif (heap profiling)
- Valgrind Memcheck (leak detection)
- Heaptrack (heap profiling)
- Custom memory monitoring

**Generates:**
- Heap usage over time
- Memory leak reports
- Peak memory usage
- Memory usage by workload size

**Outputs:**
- `reports/profiling/memory/massif_report.txt`
- `reports/profiling/memory/memcheck.txt`
- `reports/profiling/memory/heaptrack_report.txt`
- `reports/profiling/memory/memory_over_time.csv`

#### GPU Profiling

Profile GPU usage (requires NVIDIA GPU):

```bash
./profile_gpu.sh
```

**Tools Used:**
- nvidia-smi (monitoring)
- Nsight Systems (profiling)
- Nsight Compute (kernel analysis)

**Metrics:**
- GPU utilization
- Memory utilization
- VRAM usage
- Power consumption
- Quantization comparison

**Outputs:**
- `reports/profiling/gpu/gpu_usage.csv`
- `reports/profiling/gpu/nsys_profile.nsys-rep`
- `reports/profiling/gpu/ncu_profile.ncu-rep`
- `reports/profiling/gpu/vram_usage.txt`

## Baseline Comparison

### Using Baselines

Baselines are stored in `baselines/`:

- `baseline_rtx3080.json` - RTX 3080 GPU targets
- `baseline_cpu_only.json` - CPU-only targets

The benchmark runner automatically selects the appropriate baseline based on detected hardware.

### Creating a New Baseline

```bash
python3 generate_report.py --save-baseline baselines/my_baseline.json
```

### Comparing Against Baseline

```bash
python3 generate_report.py --compare-baseline baselines/baseline_rtx3080.json
```

### Regression Detection

```bash
# Detect regressions with 10% threshold (default)
python3 generate_report.py --detect-regressions

# Custom threshold
python3 generate_report.py --detect-regressions --threshold 5
```

## Report Generation

### Generate Reports

```bash
python3 generate_report.py --output-dir reports --format html,markdown,json
```

**Formats:**
- **HTML**: Interactive report with charts and styling
- **Markdown**: Plain text report for documentation
- **JSON**: Machine-readable format for CI/CD

**Outputs:**
- `reports/benchmark_report.html`
- `reports/benchmark_report.md`
- `reports/benchmark_report.json`

### Report Contents

- Hardware configuration
- Benchmark results by category
- Performance comparisons
- Regression analysis
- Statistical summaries
- Visualization graphs

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Performance Benchmarks

on:
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 0 * * 0'  # Weekly

jobs:
  benchmark:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y build-essential

      - name: Run benchmarks
        run: |
          cd tests/benchmarks
          ./run_all_benchmarks.sh

      - name: Detect regressions
        run: |
          cd tests/benchmarks
          python3 generate_report.py --detect-regressions --threshold 10

      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: benchmark-results
          path: tests/benchmarks/reports/
```

### GitLab CI Example

```yaml
benchmark:
  stage: test
  script:
    - cd tests/benchmarks
    - ./run_all_benchmarks.sh
    - python3 generate_report.py --detect-regressions
  artifacts:
    paths:
      - tests/benchmarks/reports/
    expire_in: 30 days
  only:
    - merge_requests
    - schedules
```

## Performance Targets

### RTX 3080 Targets

| Benchmark | Target | Threshold |
|-----------|--------|-----------|
| Event Store Write (1000) | < 8ms | 10% |
| TMA Parsing (medium) | < 50µs | 10% |
| AI Inference (100 tokens) | < 150ms | 15% |
| E2E TMA Marking | < 3s | 10% |
| Batch Processing (100) | < 180s | 10% |

### CPU-Only Targets

| Benchmark | Target | Threshold |
|-----------|--------|-----------|
| Event Store Write (1000) | < 10ms | 10% |
| TMA Parsing (medium) | < 60µs | 10% |
| AI Inference (100 tokens) | < 2s | 15% |
| E2E TMA Marking | < 20s | 10% |
| Batch Processing (100) | < 1000s | 10% |

## Troubleshooting

### Benchmarks Fail to Compile

```bash
# Update dependencies
cargo update

# Clean build
cargo clean
cargo build --release
```

### Profiling Tools Not Found

```bash
# Install perf
sudo apt-get install linux-tools-common linux-tools-generic

# Install flamegraph
cargo install flamegraph

# Install valgrind
sudo apt-get install valgrind

# Install heaptrack
sudo apt-get install heaptrack
```

### GPU Profiling Fails

```bash
# Check NVIDIA driver
nvidia-smi

# Install CUDA toolkit for profiling tools
# Download from: https://developer.nvidia.com/cuda-downloads
```

### Load Tests Fail

```bash
# Install Locust
pip3 install locust

# Install k6
# https://k6.io/docs/getting-started/installation/

# Check backend is running
curl http://localhost:8000/health
```

## Best Practices

### Running Benchmarks

1. **Close Unnecessary Applications**: Minimize background processes
2. **Use Release Builds**: Always benchmark optimized code
3. **Run Multiple Iterations**: Use warmup and multiple samples
4. **Consistent Environment**: Use same hardware/OS for comparisons
5. **Monitor System Resources**: Ensure no resource constraints

### Interpreting Results

1. **Look for Trends**: Single runs can be noisy
2. **Consider Standard Deviation**: High variance indicates instability
3. **Compare Apples to Apples**: Same hardware, workload, conditions
4. **Focus on Significant Changes**: >10% change is typically meaningful
5. **Investigate Regressions**: Understand why performance degraded

### Maintaining Baselines

1. **Update Regularly**: Refresh baselines after major changes
2. **Document Changes**: Note what changed between baselines
3. **Version Baselines**: Keep historical baselines for comparison
4. **Hardware-Specific**: Maintain separate baselines per configuration

## Contributing

When adding new benchmarks:

1. Add to appropriate category (`core`, `ipc`, `ai`, `database`)
2. Follow Criterion best practices
3. Include statistical analysis
4. Document expected performance
5. Update baselines
6. Add to `run_all_benchmarks.sh`

## License

Same as the main project (see LICENSE file in project root).

## Support

For issues or questions:
- Open an issue on GitHub
- See project documentation
- Consult the team

---

**Last Updated**: 2025-11-22
