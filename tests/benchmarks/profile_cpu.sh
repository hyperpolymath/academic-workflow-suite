#!/usr/bin/env bash
#
# CPU Profiling Script
# Profiles CPU usage using perf and generates flamegraphs
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
RESULTS_DIR="${SCRIPT_DIR}/reports/profiling/cpu"

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."

    if ! command -v perf >/dev/null 2>&1; then
        log_error "perf is not installed. Install with: sudo apt-get install linux-tools-common linux-tools-generic"
        exit 1
    fi

    if ! command -v flamegraph >/dev/null 2>&1 && [ ! -d "${HOME}/.cargo/bin" ]; then
        log_warning "flamegraph not found. Install with: cargo install flamegraph"
        log_info "Attempting to use bundled FlameGraph scripts instead..."

        if [ ! -d "${SCRIPT_DIR}/FlameGraph" ]; then
            log_info "Cloning FlameGraph repository..."
            git clone https://github.com/brendangregg/FlameGraph.git "${SCRIPT_DIR}/FlameGraph"
        fi

        export PATH="${SCRIPT_DIR}/FlameGraph:${PATH}"
    fi

    log_success "Dependencies check complete"
}

# Setup
setup() {
    log_info "Setting up CPU profiling..."
    mkdir -p "${RESULTS_DIR}"

    # Build in release mode with debug symbols
    log_info "Building project in release-with-debug mode..."
    cd "${PROJECT_ROOT}/components/core"
    cargo build --profile release-with-debug || cargo build --release

    cd "${PROJECT_ROOT}/components/ai-jail"
    cargo build --profile release-with-debug 2>/dev/null || cargo build --release

    log_success "Setup complete"
}

# Profile core component
profile_core() {
    log_info "Profiling core component..."

    local binary="${PROJECT_ROOT}/components/core/target/release-with-debug/aws-core"
    [ ! -f "${binary}" ] && binary="${PROJECT_ROOT}/components/core/target/release/aws-core"

    if [ ! -f "${binary}" ]; then
        log_error "Core binary not found"
        return 1
    fi

    local output_file="${RESULTS_DIR}/core_cpu"

    # Run perf record
    log_info "Recording CPU profile (30 seconds)..."
    sudo perf record -F 99 -g --call-graph dwarf -o "${output_file}.data" \
        timeout 30s "${binary}" benchmark-workload || true

    # Generate flamegraph
    log_info "Generating flamegraph..."
    sudo perf script -i "${output_file}.data" |
        stackcollapse-perf.pl |
        flamegraph.pl >"${output_file}.svg"

    # Generate perf report
    sudo perf report -i "${output_file}.data" --stdio >"${output_file}_report.txt"

    log_success "Core profiling complete: ${output_file}.svg"
}

# Profile AI jail component
profile_ai_jail() {
    log_info "Profiling AI jail component..."

    local binary="${PROJECT_ROOT}/components/ai-jail/target/release-with-debug/ai-jail"
    [ ! -f "${binary}" ] && binary="${PROJECT_ROOT}/components/ai-jail/target/release/ai-jail"

    if [ ! -f "${binary}" ]; then
        log_warning "AI jail binary not found, skipping"
        return 0
    fi

    local output_file="${RESULTS_DIR}/ai_jail_cpu"

    log_info "Recording CPU profile (30 seconds)..."
    sudo perf record -F 99 -g --call-graph dwarf -o "${output_file}.data" \
        timeout 30s "${binary}" --benchmark-mode || true

    log_info "Generating flamegraph..."
    sudo perf script -i "${output_file}.data" |
        stackcollapse-perf.pl |
        flamegraph.pl >"${output_file}.svg"

    sudo perf report -i "${output_file}.data" --stdio >"${output_file}_report.txt"

    log_success "AI jail profiling complete: ${output_file}.svg"
}

# Profile with cargo flamegraph
profile_with_cargo_flamegraph() {
    log_info "Profiling with cargo flamegraph..."

    cd "${PROJECT_ROOT}/components/core"

    if command -v cargo-flamegraph >/dev/null 2>&1; then
        log_info "Running cargo flamegraph..."
        cargo flamegraph --bench core_benchmarks --output "${RESULTS_DIR}/core_flamegraph.svg" || {
            log_warning "cargo flamegraph failed"
        }
    else
        log_warning "cargo-flamegraph not installed, skipping"
    fi
}

# Profile hotspots
profile_hotspots() {
    log_info "Identifying CPU hotspots..."

    local binary="${PROJECT_ROOT}/components/core/target/release/aws-core"

    if [ ! -f "${binary}" ]; then
        log_warning "Binary not found, skipping hotspot analysis"
        return 0
    fi

    local output_file="${RESULTS_DIR}/hotspots"

    # Use perf stat to get overall statistics
    log_info "Collecting performance statistics..."
    sudo perf stat -e cycles,instructions,cache-references,cache-misses,branches,branch-misses \
        timeout 10s "${binary}" benchmark-workload 2>"${output_file}_stats.txt" || true

    # Top functions by CPU usage
    log_info "Analyzing top functions..."
    sudo perf record -F 99 -g -o "${output_file}.data" \
        timeout 10s "${binary}" benchmark-workload || true

    sudo perf report -i "${output_file}.data" --sort comm,dso,symbol --stdio \
        --percent-limit 1 >"${output_file}_top_functions.txt"

    log_success "Hotspot analysis complete"
}

# Profile cache performance
profile_cache() {
    log_info "Profiling cache performance..."

    local binary="${PROJECT_ROOT}/components/core/target/release/aws-core"

    if [ ! -f "${binary}" ]; then
        log_warning "Binary not found, skipping cache profiling"
        return 0
    fi

    local output_file="${RESULTS_DIR}/cache_performance.txt"

    sudo perf stat -e cache-references,cache-misses,L1-dcache-loads,L1-dcache-load-misses \
        timeout 10s "${binary}" benchmark-workload 2>"${output_file}" || true

    log_success "Cache profiling complete: ${output_file}"
}

# Cleanup
cleanup() {
    log_info "Cleaning up..."
    sudo chown -R "${USER}:${USER}" "${RESULTS_DIR}" 2>/dev/null || true
}

trap cleanup EXIT

# Main
main() {
    log_info "Starting CPU profiling suite..."
    echo ""

    check_dependencies
    setup

    profile_core
    echo ""

    profile_ai_jail
    echo ""

    profile_with_cargo_flamegraph
    echo ""

    profile_hotspots
    echo ""

    profile_cache
    echo ""

    cleanup

    log_success "CPU profiling complete!"
    log_info "Results saved to: ${RESULTS_DIR}"
    log_info ""
    log_info "View flamegraphs with: firefox ${RESULTS_DIR}/*.svg"
}

if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
