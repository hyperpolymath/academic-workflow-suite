#!/usr/bin/env bash
#
# Integration Benchmark Suite
# Tests end-to-end performance of the Academic Workflow Suite
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
RESULTS_DIR="${SCRIPT_DIR}/reports/integration"
TEMP_DIR="${SCRIPT_DIR}/tmp"

# Configuration
NUM_ITERATIONS="${NUM_ITERATIONS:-10}"
WARMUP_ITERATIONS="${WARMUP_ITERATIONS:-3}"

# Logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Setup
setup() {
    log_info "Setting up integration benchmarks..."

    mkdir -p "${RESULTS_DIR}"
    mkdir -p "${TEMP_DIR}"

    # Check dependencies
    command -v jq >/dev/null 2>&1 || {
        log_error "jq is not installed. Please install it."
        exit 1
    }

    log_success "Setup complete"
}

# Cleanup
cleanup() {
    log_info "Cleaning up..."
    rm -rf "${TEMP_DIR}"
}

trap cleanup EXIT

# Benchmark end-to-end TMA marking time
bench_e2e_tma_marking() {
    log_info "Benchmarking end-to-end TMA marking..."

    local results_file="${RESULTS_DIR}/e2e_tma_marking.json"
    local total_time=0
    local iterations=0

    # Sample TMA content
    local tma_content="
# Question 1
What is the capital of France?

## Answer
Paris is the capital of France.

# Question 2
Explain quantum mechanics.

## Answer
Quantum mechanics is a fundamental theory in physics that describes nature at
the scale of atoms and subatomic particles.
"

    # Warmup
    log_info "Warmup phase (${WARMUP_ITERATIONS} iterations)..."
    for ((i = 1; i <= WARMUP_ITERATIONS; i++)); do
        echo "${tma_content}" | timeout 30s "${PROJECT_ROOT}/components/core/target/release/aws-core" process-tma >/dev/null 2>&1 || true
    done

    # Actual benchmark
    log_info "Running benchmark (${NUM_ITERATIONS} iterations)..."
    local times=()

    for ((i = 1; i <= NUM_ITERATIONS; i++)); do
        local start_time
        start_time=$(date +%s%N)

        echo "${tma_content}" | "${PROJECT_ROOT}/components/core/target/release/aws-core" process-tma >/dev/null 2>&1 || {
            log_warning "Iteration $i failed"
            continue
        }

        local end_time
        end_time=$(date +%s%N)
        local duration_ns=$((end_time - start_time))
        local duration_ms=$((duration_ns / 1000000))

        times+=("${duration_ms}")
        total_time=$((total_time + duration_ms))
        iterations=$((iterations + 1))

        log_info "Iteration $i: ${duration_ms}ms"
    done

    # Calculate statistics
    local avg_time=$((total_time / iterations))
    local min_time=$(printf '%s\n' "${times[@]}" | sort -n | head -1)
    local max_time=$(printf '%s\n' "${times[@]}" | sort -n | tail -1)

    # Calculate median
    local sorted_times=($(printf '%s\n' "${times[@]}" | sort -n))
    local median_time=${sorted_times[$((iterations / 2))]}

    # Save results
    cat >"${results_file}" <<EOF
{
  "benchmark": "e2e_tma_marking",
  "timestamp": "$(date -Iseconds)",
  "iterations": ${iterations},
  "times_ms": [$(
        IFS=,
        echo "${times[*]}"
    )],
  "statistics": {
    "avg_ms": ${avg_time},
    "min_ms": ${min_time},
    "max_ms": ${max_time},
    "median_ms": ${median_time}
  }
}
EOF

    log_success "E2E TMA marking: avg=${avg_time}ms, min=${min_time}ms, max=${max_time}ms, median=${median_time}ms"
}

# Benchmark batch processing throughput
bench_batch_processing() {
    log_info "Benchmarking batch processing throughput..."

    local results_file="${RESULTS_DIR}/batch_processing.json"
    local batch_sizes=(10 50 100)

    local results="{"
    results+="\"benchmark\": \"batch_processing\","
    results+="\"timestamp\": \"$(date -Iseconds)\","
    results+="\"batch_sizes\": {"

    for batch_size in "${batch_sizes[@]}"; do
        log_info "Testing batch size: ${batch_size}"

        # Create batch file
        local batch_file="${TEMP_DIR}/batch_${batch_size}.json"
        echo "[" >"${batch_file}"

        for ((i = 1; i <= batch_size; i++)); do
            cat >>"${batch_file}" <<EOF
{
  "tma_id": "TMA_${i}",
  "content": "# Question\nWhat is AI?\n\n## Answer\nArtificial Intelligence."
}$([ $i -lt ${batch_size} ] && echo "," || echo "")
EOF
        done

        echo "]" >>"${batch_file}"

        # Benchmark
        local start_time
        start_time=$(date +%s%N)

        cat "${batch_file}" | "${PROJECT_ROOT}/components/core/target/release/aws-core" process-batch >/dev/null 2>&1 || {
            log_warning "Batch size ${batch_size} failed"
            continue
        }

        local end_time
        end_time=$(date +%s%N)
        local duration_ns=$((end_time - start_time))
        local duration_ms=$((duration_ns / 1000000))
        local throughput=$((batch_size * 1000 / duration_ms))

        results+="\"${batch_size}\": {"
        results+="\"duration_ms\": ${duration_ms},"
        results+="\"throughput_per_sec\": ${throughput}"
        results+="},"

        log_success "Batch ${batch_size}: ${duration_ms}ms (${throughput} TMAs/sec)"
    done

    # Remove trailing comma and close JSON
    results="${results%,}"
    results+="}}}"

    echo "${results}" | jq '.' >"${results_file}"
}

# Benchmark cold start vs warm start
bench_cold_vs_warm_start() {
    log_info "Benchmarking cold start vs warm start..."

    local results_file="${RESULTS_DIR}/cold_vs_warm_start.json"

    # Cold start
    log_info "Measuring cold start time..."
    pkill -f aws-core || true
    sleep 2

    local cold_start_time
    cold_start_time=$(date +%s%N)
    echo "test" | "${PROJECT_ROOT}/components/core/target/release/aws-core" process-tma >/dev/null 2>&1
    local cold_end_time
    cold_end_time=$(date +%s%N)
    local cold_duration_ms=$(((cold_end_time - cold_start_time) / 1000000))

    # Warm start
    log_info "Measuring warm start time..."
    sleep 1

    local warm_times=()
    for ((i = 1; i <= 5; i++)); do
        local warm_start_time
        warm_start_time=$(date +%s%N)
        echo "test" | "${PROJECT_ROOT}/components/core/target/release/aws-core" process-tma >/dev/null 2>&1
        local warm_end_time
        warm_end_time=$(date +%s%N)
        local warm_duration_ms=$(((warm_end_time - warm_start_time) / 1000000))
        warm_times+=("${warm_duration_ms}")
    done

    # Calculate average warm start
    local total_warm=0
    for time in "${warm_times[@]}"; do
        total_warm=$((total_warm + time))
    done
    local avg_warm=$((total_warm / ${#warm_times[@]}))

    # Save results
    cat >"${results_file}" <<EOF
{
  "benchmark": "cold_vs_warm_start",
  "timestamp": "$(date -Iseconds)",
  "cold_start_ms": ${cold_duration_ms},
  "warm_start_avg_ms": ${avg_warm},
  "improvement_factor": $(echo "scale=2; ${cold_duration_ms} / ${avg_warm}" | bc)
}
EOF

    log_success "Cold start: ${cold_duration_ms}ms, Warm start: ${avg_warm}ms"
}

# Benchmark AI model loading
bench_ai_model_loading() {
    log_info "Benchmarking AI model loading..."

    local results_file="${RESULTS_DIR}/ai_model_loading.json"

    if [ ! -f "${PROJECT_ROOT}/components/ai-jail/target/release/ai-jail" ]; then
        log_warning "ai-jail binary not found, skipping AI model loading benchmark"
        return
    fi

    # Test model loading time
    local start_time
    start_time=$(date +%s%N)

    timeout 60s "${PROJECT_ROOT}/components/ai-jail/target/release/ai-jail" --load-model >/dev/null 2>&1 || {
        log_warning "AI model loading timed out or failed"
        return
    }

    local end_time
    end_time=$(date +%s%N)
    local duration_ms=$(((end_time - start_time) / 1000000))

    cat >"${results_file}" <<EOF
{
  "benchmark": "ai_model_loading",
  "timestamp": "$(date -Iseconds)",
  "loading_time_ms": ${duration_ms}
}
EOF

    log_success "AI model loading: ${duration_ms}ms"
}

# Benchmark database operations
bench_database_operations() {
    log_info "Benchmarking database operations..."

    local results_file="${RESULTS_DIR}/database_operations.json"
    local db_path="${TEMP_DIR}/test_db"

    mkdir -p "${db_path}"

    # Benchmark inserts
    local insert_count=1000
    local insert_start
    insert_start=$(date +%s%N)

    for ((i = 1; i <= insert_count; i++)); do
        echo "{\"id\": \"evt_${i}\", \"data\": \"test data ${i}\"}" |
            "${PROJECT_ROOT}/components/core/target/release/aws-core" db-insert --db="${db_path}" >/dev/null 2>&1 || true
    done

    local insert_end
    insert_end=$(date +%s%N)
    local insert_duration_ms=$(((insert_end - insert_start) / 1000000))
    local insert_throughput=$((insert_count * 1000 / insert_duration_ms))

    # Benchmark queries
    local query_count=1000
    local query_start
    query_start=$(date +%s%N)

    for ((i = 1; i <= query_count; i++)); do
        "${PROJECT_ROOT}/components/core/target/release/aws-core" db-query --db="${db_path}" --id="evt_${i}" >/dev/null 2>&1 || true
    done

    local query_end
    query_end=$(date +%s%N)
    local query_duration_ms=$(((query_end - query_start) / 1000000))
    local query_throughput=$((query_count * 1000 / query_duration_ms))

    cat >"${results_file}" <<EOF
{
  "benchmark": "database_operations",
  "timestamp": "$(date -Iseconds)",
  "insert": {
    "count": ${insert_count},
    "duration_ms": ${insert_duration_ms},
    "throughput_per_sec": ${insert_throughput}
  },
  "query": {
    "count": ${query_count},
    "duration_ms": ${query_duration_ms},
    "throughput_per_sec": ${query_throughput}
  }
}
EOF

    log_success "DB inserts: ${insert_throughput}/sec, queries: ${query_throughput}/sec"
}

# Main benchmark suite
main() {
    log_info "Starting integration benchmark suite..."
    echo ""

    setup

    bench_e2e_tma_marking
    echo ""

    bench_batch_processing
    echo ""

    bench_cold_vs_warm_start
    echo ""

    bench_ai_model_loading
    echo ""

    bench_database_operations
    echo ""

    log_success "All integration benchmarks completed!"
    log_info "Results saved to: ${RESULTS_DIR}"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
