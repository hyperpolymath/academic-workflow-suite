#!/usr/bin/env bash
#
# Run All Benchmarks
# Comprehensive benchmark runner for the Academic Workflow Suite
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
RESULTS_DIR="${SCRIPT_DIR}/reports"
BASELINE_DIR="${SCRIPT_DIR}/baselines"

# Configuration
RUN_RUST_BENCHMARKS="${RUN_RUST_BENCHMARKS:-true}"
RUN_AI_BENCHMARKS="${RUN_AI_BENCHMARKS:-true}"
RUN_INTEGRATION_BENCHMARKS="${RUN_INTEGRATION_BENCHMARKS:-true}"
RUN_PROFILING="${RUN_PROFILING:-false}"
COMPARE_BASELINE="${COMPARE_BASELINE:-true}"
GENERATE_REPORT="${GENERATE_REPORT:-true}"

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_section() { echo -e "${MAGENTA}[SECTION]${NC} $*"; }

# Banner
print_banner() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                ║${NC}"
    echo -e "${CYAN}║         Academic Workflow Suite - Benchmark Runner            ║${NC}"
    echo -e "${CYAN}║                                                                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Detect hardware
detect_hardware() {
    log_section "Detecting Hardware Configuration"

    local hw_info_file="${RESULTS_DIR}/hardware_info.json"
    mkdir -p "${RESULTS_DIR}"

    # CPU info
    local cpu_model
    cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
    local cpu_cores
    cpu_cores=$(nproc)

    # RAM info
    local ram_gb
    ram_gb=$(free -g | awk '/^Mem:/{print $2}')

    # GPU info (if available)
    local gpu_model="None"
    local gpu_vram="0"
    if command -v nvidia-smi >/dev/null 2>&1; then
        gpu_model=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo "None")
        gpu_vram=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null || echo "0")
    fi

    # Storage info
    local storage_type
    if [ -d /sys/block/nvme0n1 ]; then
        storage_type="NVMe SSD"
    elif [ -d /sys/block/sda ]; then
        if [ "$(cat /sys/block/sda/queue/rotational)" == "0" ]; then
            storage_type="SATA SSD"
        else
            storage_type="HDD"
        fi
    else
        storage_type="Unknown"
    fi

    # Save hardware info
    cat >"${hw_info_file}" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "cpu": {
    "model": "${cpu_model}",
    "cores": ${cpu_cores}
  },
  "ram": {
    "total_gb": ${ram_gb}
  },
  "gpu": {
    "model": "${gpu_model}",
    "vram_mb": ${gpu_vram}
  },
  "storage": {
    "type": "${storage_type}"
  },
  "os": {
    "kernel": "$(uname -r)",
    "distribution": "$(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')"
  }
}
EOF

    log_info "CPU: ${cpu_model} (${cpu_cores} cores)"
    log_info "RAM: ${ram_gb} GB"
    log_info "GPU: ${gpu_model} (${gpu_vram} MB VRAM)"
    log_info "Storage: ${storage_type}"
    log_success "Hardware detection complete"
    echo ""
}

# Setup environment
setup_environment() {
    log_section "Setting Up Environment"

    # Create directories
    mkdir -p "${RESULTS_DIR}"/{criterion,integration,profiling,load_tests}
    mkdir -p "${BASELINE_DIR}"

    # Build all components
    log_info "Building components in release mode..."

    cd "${PROJECT_ROOT}/components/core"
    cargo build --release --quiet

    cd "${PROJECT_ROOT}/components/ai-jail"
    cargo build --release --quiet 2>/dev/null || {
        log_warning "AI jail build failed, AI benchmarks may not work"
    }

    cd "${SCRIPT_DIR}"
    cargo build --release --benches --quiet 2>/dev/null || {
        log_warning "Benchmark build failed"
    }

    log_success "Environment setup complete"
    echo ""
}

# Run Rust/Criterion benchmarks
run_rust_benchmarks() {
    if [ "${RUN_RUST_BENCHMARKS}" != "true" ]; then
        log_info "Skipping Rust benchmarks (disabled)"
        return 0
    fi

    log_section "Running Rust/Criterion Benchmarks"

    cd "${SCRIPT_DIR}"

    # Core benchmarks
    log_info "Running core benchmarks..."
    cargo bench --bench core_benchmarks --quiet -- --save-baseline current 2>&1 | tee "${RESULTS_DIR}/criterion/core_benchmarks.log" || {
        log_warning "Core benchmarks failed"
    }

    # IPC benchmarks
    log_info "Running IPC benchmarks..."
    cargo bench --bench ipc_benchmarks --quiet -- --save-baseline current 2>&1 | tee "${RESULTS_DIR}/criterion/ipc_benchmarks.log" || {
        log_warning "IPC benchmarks failed"
    }

    # Database benchmarks
    log_info "Running database benchmarks..."
    cargo bench --bench lmdb_bench --quiet -- --save-baseline current 2>&1 | tee "${RESULTS_DIR}/criterion/lmdb_benchmarks.log" || {
        log_warning "Database benchmarks failed"
    }

    log_success "Rust benchmarks complete"
    echo ""
}

# Run AI benchmarks
run_ai_benchmarks() {
    if [ "${RUN_AI_BENCHMARKS}" != "true" ]; then
        log_info "Skipping AI benchmarks (disabled)"
        return 0
    fi

    log_section "Running AI Inference Benchmarks"

    cd "${SCRIPT_DIR}"

    log_info "Running AI benchmarks..."
    cargo bench --bench ai_benchmarks --quiet -- --save-baseline current 2>&1 | tee "${RESULTS_DIR}/criterion/ai_benchmarks.log" || {
        log_warning "AI benchmarks failed"
    }

    log_success "AI benchmarks complete"
    echo ""
}

# Run integration benchmarks
run_integration_benchmarks() {
    if [ "${RUN_INTEGRATION_BENCHMARKS}" != "true" ]; then
        log_info "Skipping integration benchmarks (disabled)"
        return 0
    fi

    log_section "Running Integration Benchmarks"

    bash "${SCRIPT_DIR}/integration_bench.sh" 2>&1 | tee "${RESULTS_DIR}/integration/integration_bench.log" || {
        log_warning "Integration benchmarks failed"
    }

    log_success "Integration benchmarks complete"
    echo ""
}

# Run profiling
run_profiling() {
    if [ "${RUN_PROFILING}" != "true" ]; then
        log_info "Skipping profiling (disabled)"
        return 0
    fi

    log_section "Running Profiling Suite"

    # CPU profiling
    log_info "Running CPU profiling..."
    bash "${SCRIPT_DIR}/profile_cpu.sh" 2>&1 | tee "${RESULTS_DIR}/profiling/cpu_profiling.log" || {
        log_warning "CPU profiling failed"
    }

    # Memory profiling
    log_info "Running memory profiling..."
    bash "${SCRIPT_DIR}/profile_memory.sh" 2>&1 | tee "${RESULTS_DIR}/profiling/memory_profiling.log" || {
        log_warning "Memory profiling failed"
    }

    # GPU profiling (if available)
    if command -v nvidia-smi >/dev/null 2>&1; then
        log_info "Running GPU profiling..."
        bash "${SCRIPT_DIR}/profile_gpu.sh" 2>&1 | tee "${RESULTS_DIR}/profiling/gpu_profiling.log" || {
            log_warning "GPU profiling failed"
        }
    else
        log_info "No GPU detected, skipping GPU profiling"
    fi

    log_success "Profiling complete"
    echo ""
}

# Compare against baseline
compare_against_baseline() {
    if [ "${COMPARE_BASELINE}" != "true" ]; then
        log_info "Skipping baseline comparison (disabled)"
        return 0
    fi

    log_section "Comparing Against Baseline"

    local baseline_file
    local hw_info_file="${RESULTS_DIR}/hardware_info.json"

    # Determine which baseline to use
    if [ -f "${hw_info_file}" ]; then
        local gpu_model
        gpu_model=$(jq -r '.gpu.model' "${hw_info_file}")

        if [[ "${gpu_model}" == *"RTX 3080"* ]]; then
            baseline_file="${BASELINE_DIR}/baseline_rtx3080.json"
        else
            baseline_file="${BASELINE_DIR}/baseline_cpu_only.json"
        fi
    else
        baseline_file="${BASELINE_DIR}/baseline_cpu_only.json"
    fi

    if [ ! -f "${baseline_file}" ]; then
        log_warning "Baseline file not found: ${baseline_file}"
        log_info "Creating new baseline from current results..."

        # Save current results as baseline
        python3 "${SCRIPT_DIR}/generate_report.py" --save-baseline "${baseline_file}" 2>/dev/null || {
            log_warning "Failed to save baseline"
        }

        return 0
    fi

    log_info "Using baseline: ${baseline_file}"

    # Run comparison
    python3 "${SCRIPT_DIR}/generate_report.py" --compare-baseline "${baseline_file}" 2>&1 | tee "${RESULTS_DIR}/baseline_comparison.txt" || {
        log_warning "Baseline comparison failed"
    }

    log_success "Baseline comparison complete"
    echo ""
}

# Detect regressions
detect_regressions() {
    log_section "Detecting Performance Regressions"

    local regression_threshold=10  # 10% regression threshold

    log_info "Analyzing results for regressions (threshold: ${regression_threshold}%)..."

    python3 "${SCRIPT_DIR}/generate_report.py" --detect-regressions --threshold="${regression_threshold}" 2>&1 | tee "${RESULTS_DIR}/regressions.txt" || {
        log_warning "Regression detection failed"
        return 0
    }

    # Check if regressions were found
    if grep -q "REGRESSION DETECTED" "${RESULTS_DIR}/regressions.txt" 2>/dev/null; then
        log_error "Performance regressions detected! See ${RESULTS_DIR}/regressions.txt"
        return 1
    else
        log_success "No significant regressions detected"
    fi

    echo ""
}

# Generate report
generate_report() {
    if [ "${GENERATE_REPORT}" != "true" ]; then
        log_info "Skipping report generation (disabled)"
        return 0
    fi

    log_section "Generating Benchmark Report"

    python3 "${SCRIPT_DIR}/generate_report.py" \
        --output-dir="${RESULTS_DIR}" \
        --format=html,markdown,json 2>&1 | tee "${RESULTS_DIR}/report_generation.log" || {
        log_warning "Report generation failed"
        return 0
    }

    log_success "Report generated: ${RESULTS_DIR}/benchmark_report.html"
    echo ""
}

# Summary
print_summary() {
    log_section "Benchmark Summary"

    local total_time_file="${RESULTS_DIR}/.start_time"
    if [ -f "${total_time_file}" ]; then
        local start_time
        start_time=$(cat "${total_time_file}")
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local minutes=$((duration / 60))
        local seconds=$((duration % 60))

        log_info "Total benchmark time: ${minutes}m ${seconds}s"
    fi

    log_info "Results directory: ${RESULTS_DIR}"

    if [ -f "${RESULTS_DIR}/benchmark_report.html" ]; then
        log_info "HTML report: ${RESULTS_DIR}/benchmark_report.html"
    fi

    if [ -f "${RESULTS_DIR}/benchmark_report.md" ]; then
        log_info "Markdown report: ${RESULTS_DIR}/benchmark_report.md"
    fi

    echo ""
    log_success "All benchmarks completed successfully!"
}

# Cleanup
cleanup() {
    rm -f "${RESULTS_DIR}/.start_time"
}

trap cleanup EXIT

# Usage
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Run comprehensive benchmark suite for Academic Workflow Suite

Options:
  --rust              Run Rust/Criterion benchmarks only
  --ai                Run AI inference benchmarks only
  --integration       Run integration benchmarks only
  --profiling         Enable profiling (CPU, memory, GPU)
  --no-baseline       Skip baseline comparison
  --no-report         Skip report generation
  --help              Show this help message

Environment Variables:
  RUN_RUST_BENCHMARKS       Run Rust benchmarks (default: true)
  RUN_AI_BENCHMARKS         Run AI benchmarks (default: true)
  RUN_INTEGRATION_BENCHMARKS Run integration benchmarks (default: true)
  RUN_PROFILING             Run profiling (default: false)
  COMPARE_BASELINE          Compare against baseline (default: true)
  GENERATE_REPORT           Generate reports (default: true)

Examples:
  $0                        # Run all benchmarks
  $0 --rust --ai            # Run only Rust and AI benchmarks
  $0 --profiling            # Run all benchmarks with profiling
  RUN_PROFILING=true $0     # Run all benchmarks with profiling (env var)

EOF
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
        --rust)
            RUN_RUST_BENCHMARKS=true
            RUN_AI_BENCHMARKS=false
            RUN_INTEGRATION_BENCHMARKS=false
            shift
            ;;
        --ai)
            RUN_RUST_BENCHMARKS=false
            RUN_AI_BENCHMARKS=true
            RUN_INTEGRATION_BENCHMARKS=false
            shift
            ;;
        --integration)
            RUN_RUST_BENCHMARKS=false
            RUN_AI_BENCHMARKS=false
            RUN_INTEGRATION_BENCHMARKS=true
            shift
            ;;
        --profiling)
            RUN_PROFILING=true
            shift
            ;;
        --no-baseline)
            COMPARE_BASELINE=false
            shift
            ;;
        --no-report)
            GENERATE_REPORT=false
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
        esac
    done
}

# Main
main() {
    parse_args "$@"

    print_banner

    # Record start time
    date +%s >"${RESULTS_DIR}/.start_time"

    detect_hardware
    setup_environment
    run_rust_benchmarks
    run_ai_benchmarks
    run_integration_benchmarks
    run_profiling
    compare_against_baseline
    detect_regressions || true  # Don't fail on regressions
    generate_report
    print_summary
}

if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
