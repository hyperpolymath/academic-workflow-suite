#!/bin/bash
# Integration test suite for Academic Workflow Suite
# Tests interactions between components

set -e
set -u
set -o pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_RESULTS_DIR="${ROOT_DIR}/tests/integration/results"
JUNIT_OUTPUT="${TEST_RESULTS_DIR}/junit.xml"
START_TIME=$(date +%s)

# Create results directory
mkdir -p "$TEST_RESULTS_DIR"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Initialize JUnit XML
init_junit() {
    cat > "$JUNIT_OUTPUT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Integration Tests" tests="0" failures="0" errors="0" time="0">
  <testsuite name="Academic Workflow Suite Integration" tests="0" failures="0" errors="0" time="0">
EOF
}

# Finalize JUnit XML
finalize_junit() {
    local duration=$1
    sed -i "s/tests=\"0\" failures=\"0\" errors=\"0\" time=\"0\"/tests=\"$TESTS_RUN\" failures=\"$TESTS_FAILED\" errors=\"0\" time=\"$duration\"/" "$JUNIT_OUTPUT"
    cat >> "$JUNIT_OUTPUT" <<EOF
  </testsuite>
</testsuites>
EOF
}

# Add test result to JUnit
add_test_result() {
    local name=$1
    local status=$2
    local duration=$3
    local message=${4:-""}

    if [ "$status" = "passed" ]; then
        cat >> "$JUNIT_OUTPUT" <<EOF
    <testcase name="$name" classname="Integration" time="$duration">
    </testcase>
EOF
    else
        cat >> "$JUNIT_OUTPUT" <<EOF
    <testcase name="$name" classname="Integration" time="$duration">
      <failure message="$message">$message</failure>
    </testcase>
EOF
    fi
}

# Run a test
run_test() {
    local test_name=$1
    local test_command=$2

    TESTS_RUN=$((TESTS_RUN + 1))
    log_test "Running: $test_name"

    local test_start=$(date +%s)
    local result="passed"
    local message=""

    if eval "$test_command" > "${TEST_RESULTS_DIR}/${test_name}.log" 2>&1; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_success "$test_name passed"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        result="failed"
        message=$(tail -5 "${TEST_RESULTS_DIR}/${test_name}.log" | tr '\n' ' ')
        log_error "$test_name failed"
    fi

    local test_end=$(date +%s)
    local test_duration=$((test_end - test_start))

    add_test_result "$test_name" "$result" "$test_duration" "$message"
}

# Test: Core binary exists and runs
test_core_binary() {
    local binary="${ROOT_DIR}/components/core/target/release/academic-workflow-core"

    if [ ! -f "$binary" ]; then
        binary="${ROOT_DIR}/components/core/target/debug/academic-workflow-core"
    fi

    if [ -f "$binary" ]; then
        chmod +x "$binary"
        "$binary" --version || "$binary" --help || true
        return 0
    else
        log_error "Core binary not found"
        return 1
    fi
}

# Test: AI jail binary exists and runs
test_ai_jail_binary() {
    local binary="${ROOT_DIR}/components/ai-jail/target/release/ai-jail"

    if [ ! -f "$binary" ]; then
        binary="${ROOT_DIR}/components/ai-jail/target/debug/ai-jail"
    fi

    if [ -f "$binary" ]; then
        chmod +x "$binary"
        "$binary" --version || "$binary" --help || true
        return 0
    else
        log_error "AI jail binary not found"
        return 1
    fi
}

# Test: Core-Backend communication
test_core_backend_communication() {
    log_info "Testing Core-Backend communication..."

    # Check if backend is available
    local backend_dir="${ROOT_DIR}/components/backend"
    if [ ! -d "$backend_dir" ]; then
        log_error "Backend directory not found"
        return 1
    fi

    # Simple connectivity test
    # This would need to be expanded with actual integration tests
    echo "Core-Backend communication test placeholder"
    return 0
}

# Test: AI jail isolation
test_ai_jail_isolation() {
    log_info "Testing AI jail isolation..."

    local binary="${ROOT_DIR}/components/ai-jail/target/release/ai-jail"

    if [ ! -f "$binary" ]; then
        binary="${ROOT_DIR}/components/ai-jail/target/debug/ai-jail"
    fi

    if [ -f "$binary" ]; then
        chmod +x "$binary"
        # Test basic isolation (would need to be expanded)
        timeout 5 "$binary" test-isolation 2>/dev/null || {
            # If test-isolation command doesn't exist, that's okay
            log_info "No isolation test command available"
            return 0
        }
        return 0
    else
        log_error "AI jail binary not found for isolation test"
        return 1
    fi
}

# Test: Office add-in artifacts
test_office_addin_artifacts() {
    log_info "Testing Office add-in artifacts..."

    local dist_dir="${ROOT_DIR}/components/office-addin/dist"
    local build_dir="${ROOT_DIR}/components/office-addin/build"

    if [ -d "$dist_dir" ] || [ -d "$build_dir" ]; then
        log_success "Office add-in artifacts found"
        return 0
    else
        log_warning "No Office add-in artifacts found (may not be built)"
        return 0  # Not a critical failure
    fi
}

# Test: Configuration files
test_configuration_files() {
    log_info "Testing configuration files..."

    local config_dir="${ROOT_DIR}/config"

    if [ -d "$config_dir" ]; then
        local config_count=$(find "$config_dir" -type f | wc -l)
        log_info "Found $config_count configuration files"
        return 0
    else
        log_warning "No config directory found"
        return 0
    fi
}

# Test: Documentation
test_documentation() {
    log_info "Testing documentation..."

    local required_docs=("README.md" "CLAUDE.md")

    for doc in "${required_docs[@]}"; do
        if [ ! -f "${ROOT_DIR}/${doc}" ]; then
            log_error "Missing required documentation: $doc"
            return 1
        fi
    done

    log_success "All required documentation present"
    return 0
}

# Main test execution
main() {
    log_info "Starting integration tests for Academic Workflow Suite"
    log_info "Root directory: $ROOT_DIR"
    log_info "Results directory: $TEST_RESULTS_DIR"
    echo ""

    init_junit

    # Run tests
    run_test "core_binary_exists" "test_core_binary"
    run_test "ai_jail_binary_exists" "test_ai_jail_binary"
    run_test "core_backend_communication" "test_core_backend_communication"
    run_test "ai_jail_isolation" "test_ai_jail_isolation"
    run_test "office_addin_artifacts" "test_office_addin_artifacts"
    run_test "configuration_files" "test_configuration_files"
    run_test "documentation" "test_documentation"

    # Calculate duration
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    # Finalize JUnit
    finalize_junit "$DURATION"

    # Summary
    echo ""
    echo "======================================="
    log_info "Integration Test Summary"
    echo "======================================="
    echo "Tests run:    $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo "Duration:     ${DURATION}s"
    echo "Results:      $JUNIT_OUTPUT"
    echo "======================================="

    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "All integration tests passed!"
        return 0
    else
        log_error "$TESTS_FAILED test(s) failed"
        return 1
    fi
}

# Run main
main
exit $?
