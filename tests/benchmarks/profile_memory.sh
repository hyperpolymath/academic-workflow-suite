#!/usr/bin/env bash
#
# Memory Profiling Script
# Profiles memory usage using valgrind, heaptrack, and massif
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
RESULTS_DIR="${SCRIPT_DIR}/reports/profiling/memory"

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."

    local missing_deps=()

    if ! command -v valgrind >/dev/null 2>&1; then
        log_warning "valgrind not installed"
        missing_deps+=("valgrind")
    fi

    if ! command -v heaptrack >/dev/null 2>&1; then
        log_warning "heaptrack not installed"
        missing_deps+=("heaptrack")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_warning "Missing dependencies: ${missing_deps[*]}"
        log_info "Install with: sudo apt-get install ${missing_deps[*]}"
    fi

    log_success "Dependency check complete"
}

# Setup
setup() {
    log_info "Setting up memory profiling..."
    mkdir -p "${RESULTS_DIR}"

    # Build in release mode
    log_info "Building project..."
    cd "${PROJECT_ROOT}/components/core"
    cargo build --release

    cd "${PROJECT_ROOT}/components/ai-jail"
    cargo build --release 2>/dev/null || true

    log_success "Setup complete"
}

# Profile with Valgrind Massif (heap profiling)
profile_massif() {
    log_info "Profiling with Valgrind Massif..."

    local binary="${PROJECT_ROOT}/components/core/target/release/aws-core"

    if [ ! -f "${binary}" ]; then
        log_error "Binary not found"
        return 1
    fi

    local output_file="${RESULTS_DIR}/massif.out"

    log_info "Running Massif (this may take a while)..."
    valgrind --tool=massif \
        --massif-out-file="${output_file}" \
        --time-unit=B \
        --detailed-freq=1 \
        --max-snapshots=100 \
        "${binary}" benchmark-workload 2>"${RESULTS_DIR}/massif.log" || {
        log_warning "Massif profiling encountered errors, check log"
    }

    # Generate report
    if [ -f "${output_file}" ]; then
        ms_print "${output_file}" >"${RESULTS_DIR}/massif_report.txt"
        log_success "Massif profiling complete: ${RESULTS_DIR}/massif_report.txt"
    else
        log_error "Massif output file not created"
    fi
}

# Profile with Valgrind Memcheck (memory errors)
profile_memcheck() {
    log_info "Profiling with Valgrind Memcheck..."

    local binary="${PROJECT_ROOT}/components/core/target/release/aws-core"

    if [ ! -f "${binary}" ]; then
        log_warning "Binary not found, skipping"
        return 0
    fi

    local output_file="${RESULTS_DIR}/memcheck.txt"

    log_info "Running Memcheck..."
    valgrind --tool=memcheck \
        --leak-check=full \
        --show-leak-kinds=all \
        --track-origins=yes \
        --verbose \
        --log-file="${output_file}" \
        "${binary}" benchmark-workload 2>&1 || {
        log_warning "Memcheck found issues, check report"
    }

    log_success "Memcheck complete: ${output_file}"
}

# Profile with Heaptrack
profile_heaptrack() {
    log_info "Profiling with Heaptrack..."

    if ! command -v heaptrack >/dev/null 2>&1; then
        log_warning "Heaptrack not installed, skipping"
        return 0
    fi

    local binary="${PROJECT_ROOT}/components/core/target/release/aws-core"

    if [ ! -f "${binary}" ]; then
        log_warning "Binary not found, skipping"
        return 0
    fi

    local output_file="${RESULTS_DIR}/heaptrack.aws-core"

    log_info "Running Heaptrack..."
    heaptrack --output "${output_file}" "${binary}" benchmark-workload || {
        log_warning "Heaptrack encountered errors"
    }

    # Generate report
    if compgen -G "${output_file}*" >/dev/null; then
        heaptrack --analyze "${output_file}".* >"${RESULTS_DIR}/heaptrack_report.txt" || {
            log_warning "Failed to generate heaptrack report"
        }
        log_success "Heaptrack profiling complete"
    fi
}

# Memory usage over time
profile_memory_over_time() {
    log_info "Monitoring memory usage over time..."

    local binary="${PROJECT_ROOT}/components/core/target/release/aws-core"

    if [ ! -f "${binary}" ]; then
        log_warning "Binary not found, skipping"
        return 0
    fi

    local output_file="${RESULTS_DIR}/memory_over_time.csv"

    log_info "Starting monitored process..."

    # Start process in background
    "${binary}" benchmark-workload &
    local pid=$!

    # Monitor memory
    echo "time_sec,rss_kb,vsz_kb" >"${output_file}"

    local start_time
    start_time=$(date +%s)

    while kill -0 "${pid}" 2>/dev/null; do
        local current_time
        current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        # Get memory stats
        if [ -f "/proc/${pid}/status" ]; then
            local rss
            local vsz
            rss=$(grep VmRSS /proc/${pid}/status | awk '{print $2}')
            vsz=$(grep VmSize /proc/${pid}/status | awk '{print $2}')

            echo "${elapsed},${rss:-0},${vsz:-0}" >>"${output_file}"
        fi

        sleep 0.1
    done

    wait "${pid}" 2>/dev/null || true

    log_success "Memory monitoring complete: ${output_file}"
}

# Peak memory usage
profile_peak_memory() {
    log_info "Measuring peak memory usage..."

    local binary="${PROJECT_ROOT}/components/core/target/release/aws-core"

    if [ ! -f "${binary}" ]; then
        log_warning "Binary not found, skipping"
        return 0
    fi

    local output_file="${RESULTS_DIR}/peak_memory.txt"

    # Use /usr/bin/time for detailed stats
    /usr/bin/time -v "${binary}" benchmark-workload 2>"${output_file}" || true

    # Extract key metrics
    local peak_rss
    peak_rss=$(grep "Maximum resident set size" "${output_file}" | awk '{print $6}')

    cat >>"${output_file}" <<EOF

=== Summary ===
Peak RSS: ${peak_rss} KB
EOF

    log_success "Peak memory: ${peak_rss} KB"
}

# Memory leak detection
detect_memory_leaks() {
    log_info "Detecting memory leaks..."

    local binary="${PROJECT_ROOT}/components/core/target/release/aws-core"

    if [ ! -f "${binary}" ]; then
        log_warning "Binary not found, skipping"
        return 0
    fi

    if ! command -v valgrind >/dev/null 2>&1; then
        log_warning "Valgrind not installed, skipping"
        return 0
    fi

    local output_file="${RESULTS_DIR}/leak_detection.txt"

    log_info "Running leak detection..."
    valgrind --leak-check=full \
        --show-leak-kinds=all \
        --track-origins=yes \
        --verbose \
        --log-file="${output_file}" \
        "${binary}" benchmark-workload 2>&1 || true

    # Check for leaks
    if grep -q "definitely lost: 0 bytes" "${output_file}"; then
        log_success "No memory leaks detected"
    else
        log_warning "Memory leaks detected, check: ${output_file}"
    fi
}

# Profile different workload sizes
profile_workload_sizes() {
    log_info "Profiling different workload sizes..."

    local binary="${PROJECT_ROOT}/components/core/target/release/aws-core"

    if [ ! -f "${binary}" ]; then
        log_warning "Binary not found, skipping"
        return 0
    fi

    local output_file="${RESULTS_DIR}/workload_sizes.txt"

    echo "Workload Size vs Memory Usage" >"${output_file}"
    echo "=============================" >>"${output_file}"
    echo "" >>"${output_file}"

    for size in 10 100 1000 10000; do
        log_info "Testing workload size: ${size}"

        # Run and measure
        /usr/bin/time -v "${binary}" benchmark-workload --size="${size}" 2>"${RESULTS_DIR}/tmp_${size}.txt" || true

        local peak_rss
        peak_rss=$(grep "Maximum resident set size" "${RESULTS_DIR}/tmp_${size}.txt" | awk '{print $6}')

        echo "Size ${size}: ${peak_rss} KB" >>"${output_file}"

        rm -f "${RESULTS_DIR}/tmp_${size}.txt"
    done

    log_success "Workload size profiling complete"
}

# Cleanup
cleanup() {
    log_info "Cleaning up temporary files..."
    rm -f "${RESULTS_DIR}"/tmp_*.txt
}

trap cleanup EXIT

# Main
main() {
    log_info "Starting memory profiling suite..."
    echo ""

    check_dependencies
    setup

    profile_massif
    echo ""

    profile_memcheck
    echo ""

    profile_heaptrack
    echo ""

    profile_memory_over_time
    echo ""

    profile_peak_memory
    echo ""

    detect_memory_leaks
    echo ""

    profile_workload_sizes
    echo ""

    cleanup

    log_success "Memory profiling complete!"
    log_info "Results saved to: ${RESULTS_DIR}"
}

if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
