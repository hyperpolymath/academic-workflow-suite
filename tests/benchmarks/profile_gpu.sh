#!/usr/bin/env bash
#
# GPU Profiling Script
# Profiles GPU usage using nvidia-smi, nvprof, and nsys
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
RESULTS_DIR="${SCRIPT_DIR}/reports/profiling/gpu"

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Check GPU availability
check_gpu() {
    log_info "Checking GPU availability..."

    if ! command -v nvidia-smi >/dev/null 2>&1; then
        log_error "nvidia-smi not found. No NVIDIA GPU detected or drivers not installed."
        exit 1
    fi

    # Get GPU info
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader >"${RESULTS_DIR}/gpu_info.txt"

    local gpu_name
    gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader)

    log_success "GPU detected: ${gpu_name}"
}

# Check dependencies
check_dependencies() {
    log_info "Checking profiling tools..."

    local has_profiler=false

    if command -v nvprof >/dev/null 2>&1; then
        log_info "nvprof available"
        has_profiler=true
    else
        log_warning "nvprof not found (deprecated, use nsys instead)"
    fi

    if command -v nsys >/dev/null 2>&1; then
        log_info "nsys (Nsight Systems) available"
        has_profiler=true
    else
        log_warning "nsys not found"
    fi

    if command -v ncu >/dev/null 2>&1; then
        log_info "ncu (Nsight Compute) available"
    else
        log_warning "ncu not found"
    fi

    if [ "${has_profiler}" = false ]; then
        log_warning "No NVIDIA profiling tools found. Install CUDA toolkit for full profiling."
    fi

    log_success "Dependency check complete"
}

# Setup
setup() {
    log_info "Setting up GPU profiling..."
    mkdir -p "${RESULTS_DIR}"

    # Build with CUDA support
    log_info "Building AI jail with CUDA support..."
    cd "${PROJECT_ROOT}/components/ai-jail"
    cargo build --release --features cuda || {
        log_warning "Failed to build with CUDA support"
    }

    log_success "Setup complete"
}

# Monitor GPU usage with nvidia-smi
monitor_gpu_usage() {
    log_info "Monitoring GPU usage with nvidia-smi..."

    local binary="${PROJECT_ROOT}/components/ai-jail/target/release/ai-jail"

    if [ ! -f "${binary}" ]; then
        log_warning "AI jail binary not found, skipping"
        return 0
    fi

    local output_file="${RESULTS_DIR}/gpu_usage.csv"

    # Start nvidia-smi monitoring in background
    nvidia-smi --query-gpu=timestamp,utilization.gpu,utilization.memory,memory.used,memory.free,temperature.gpu,power.draw \
        --format=csv -l 1 >"${output_file}" &
    local monitor_pid=$!

    # Run workload
    log_info "Running AI inference workload..."
    timeout 60s "${binary}" --benchmark-mode 2>"${RESULTS_DIR}/ai_jail.log" || true

    # Stop monitoring
    sleep 2
    kill "${monitor_pid}" 2>/dev/null || true

    log_success "GPU monitoring complete: ${output_file}"
}

# Profile with Nsight Systems
profile_nsight_systems() {
    log_info "Profiling with Nsight Systems (nsys)..."

    if ! command -v nsys >/dev/null 2>&1; then
        log_warning "nsys not found, skipping"
        return 0
    fi

    local binary="${PROJECT_ROOT}/components/ai-jail/target/release/ai-jail"

    if [ ! -f "${binary}" ]; then
        log_warning "Binary not found, skipping"
        return 0
    fi

    local output_file="${RESULTS_DIR}/nsys_profile"

    log_info "Running nsys profile..."
    nsys profile \
        --output="${output_file}" \
        --force-overwrite=true \
        --stats=true \
        --trace=cuda,nvtx,osrt \
        timeout 30s "${binary}" --benchmark-mode || {
        log_warning "nsys profiling encountered errors"
    }

    # Generate report
    if [ -f "${output_file}.nsys-rep" ]; then
        nsys stats "${output_file}.nsys-rep" >"${RESULTS_DIR}/nsys_stats.txt" || true
        log_success "Nsight Systems profiling complete"
    fi
}

# Profile with Nsight Compute
profile_nsight_compute() {
    log_info "Profiling with Nsight Compute (ncu)..."

    if ! command -v ncu >/dev/null 2>&1; then
        log_warning "ncu not found, skipping"
        return 0
    fi

    local binary="${PROJECT_ROOT}/components/ai-jail/target/release/ai-jail"

    if [ ! -f "${binary}" ]; then
        log_warning "Binary not found, skipping"
        return 0
    fi

    local output_file="${RESULTS_DIR}/ncu_profile"

    log_info "Running ncu profile..."
    ncu --set full \
        --export="${output_file}" \
        --force-overwrite \
        timeout 30s "${binary}" --benchmark-mode || {
        log_warning "ncu profiling encountered errors"
    }

    log_success "Nsight Compute profiling complete"
}

# Measure VRAM usage
measure_vram_usage() {
    log_info "Measuring VRAM usage..."

    local binary="${PROJECT_ROOT}/components/ai-jail/target/release/ai-jail"

    if [ ! -f "${binary}" ]; then
        log_warning "Binary not found, skipping"
        return 0
    fi

    local output_file="${RESULTS_DIR}/vram_usage.txt"

    echo "VRAM Usage Analysis" >"${output_file}"
    echo "===================" >>"${output_file}"
    echo "" >>"${output_file}"

    # Get baseline VRAM
    local baseline_vram
    baseline_vram=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
    echo "Baseline VRAM: ${baseline_vram} MB" >>"${output_file}"

    # Start workload
    "${binary}" --benchmark-mode &
    local pid=$!

    sleep 5  # Let it initialize

    # Measure peak VRAM
    local peak_vram=0
    while kill -0 "${pid}" 2>/dev/null; do
        local current_vram
        current_vram=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)

        if [ "${current_vram}" -gt "${peak_vram}" ]; then
            peak_vram="${current_vram}"
        fi

        sleep 0.5
    done

    wait "${pid}" 2>/dev/null || true

    local delta_vram=$((peak_vram - baseline_vram))

    echo "Peak VRAM: ${peak_vram} MB" >>"${output_file}"
    echo "Workload VRAM: ${delta_vram} MB" >>"${output_file}"

    log_success "Peak VRAM usage: ${peak_vram} MB (${delta_vram} MB for workload)"
}

# Benchmark different quantization levels
benchmark_quantization() {
    log_info "Benchmarking different quantization levels..."

    local binary="${PROJECT_ROOT}/components/ai-jail/target/release/ai-jail"

    if [ ! -f "${binary}" ]; then
        log_warning "Binary not found, skipping"
        return 0
    fi

    local output_file="${RESULTS_DIR}/quantization_comparison.txt"

    echo "Quantization Comparison" >"${output_file}"
    echo "======================" >>"${output_file}"
    echo "" >>"${output_file}"

    for quant in fp16 q8 q4; do
        log_info "Testing ${quant} quantization..."

        # Clear GPU memory
        nvidia-smi --gpu-reset || true
        sleep 2

        # Measure baseline
        local baseline_vram
        baseline_vram=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)

        # Run with specific quantization
        local start_time
        start_time=$(date +%s%N)

        timeout 30s "${binary}" --quantization="${quant}" --benchmark-mode 2>/dev/null || true

        local end_time
        end_time=$(date +%s%N)
        local duration_ms=$(((end_time - start_time) / 1000000))

        # Measure peak VRAM
        local peak_vram
        peak_vram=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
        local vram_used=$((peak_vram - baseline_vram))

        echo "${quant}: ${duration_ms}ms, VRAM: ${vram_used}MB" >>"${output_file}"
        log_info "${quant}: ${duration_ms}ms, VRAM: ${vram_used}MB"
    done

    log_success "Quantization benchmarking complete"
}

# GPU utilization analysis
analyze_gpu_utilization() {
    log_info "Analyzing GPU utilization..."

    local csv_file="${RESULTS_DIR}/gpu_usage.csv"

    if [ ! -f "${csv_file}" ]; then
        log_warning "GPU usage CSV not found, skipping analysis"
        return 0
    fi

    local output_file="${RESULTS_DIR}/gpu_utilization_analysis.txt"

    echo "GPU Utilization Analysis" >"${output_file}"
    echo "========================" >>"${output_file}"
    echo "" >>"${output_file}"

    # Calculate average GPU utilization (skip header)
    local avg_gpu_util
    avg_gpu_util=$(tail -n +2 "${csv_file}" | cut -d',' -f2 | grep -o '[0-9]*' | awk '{s+=$1; c++} END {if(c>0) print s/c; else print 0}')

    # Calculate average memory utilization
    local avg_mem_util
    avg_mem_util=$(tail -n +2 "${csv_file}" | cut -d',' -f3 | grep -o '[0-9]*' | awk '{s+=$1; c++} END {if(c>0) print s/c; else print 0}')

    # Calculate average power draw
    local avg_power
    avg_power=$(tail -n +2 "${csv_file}" | cut -d',' -f7 | grep -o '[0-9.]*' | awk '{s+=$1; c++} END {if(c>0) print s/c; else print 0}')

    echo "Average GPU Utilization: ${avg_gpu_util}%" >>"${output_file}"
    echo "Average Memory Utilization: ${avg_mem_util}%" >>"${output_file}"
    echo "Average Power Draw: ${avg_power}W" >>"${output_file}"

    log_success "GPU utilization: ${avg_gpu_util}%, Memory: ${avg_mem_util}%, Power: ${avg_power}W"
}

# Cleanup
cleanup() {
    log_info "Cleaning up..."

    # Kill any remaining processes
    pkill -f ai-jail || true

    # Reset GPU if needed
    # nvidia-smi --gpu-reset || true
}

trap cleanup EXIT

# Main
main() {
    log_info "Starting GPU profiling suite..."
    echo ""

    check_gpu
    check_dependencies
    setup

    monitor_gpu_usage
    echo ""

    profile_nsight_systems
    echo ""

    profile_nsight_compute
    echo ""

    measure_vram_usage
    echo ""

    benchmark_quantization
    echo ""

    analyze_gpu_utilization
    echo ""

    cleanup

    log_success "GPU profiling complete!"
    log_info "Results saved to: ${RESULTS_DIR}"
}

if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
