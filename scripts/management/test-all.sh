#!/usr/bin/env bash
#
# test-all.sh - Comprehensive test runner for Academic Workflow Suite
#
# Usage: ./test-all.sh [OPTIONS]
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="/var/log/aws"
LOG_FILE="$LOG_DIR/test-all.log"

# Test configuration
RUN_RUST_TESTS=true
RUN_ELIXIR_TESTS=true
RUN_RESCRIPT_TESTS=true
RUN_INTEGRATION_TESTS=true
RUN_AI_ISOLATION_TESTS=true
GENERATE_COVERAGE=false
PARALLEL_TESTS=false
FAIL_FAST=false

# ============================================================================
# Color Output
# ============================================================================

if [[ -t 1 ]]; then
    RED=$(tput setaf 1 2>/dev/null || echo '')
    GREEN=$(tput setaf 2 2>/dev/null || echo '')
    YELLOW=$(tput setaf 3 2>/dev/null || echo '')
    BLUE=$(tput setaf 4 2>/dev/null || echo '')
    MAGENTA=$(tput setaf 5 2>/dev/null || echo '')
    CYAN=$(tput setaf 6 2>/dev/null || echo '')
    BOLD=$(tput bold 2>/dev/null || echo '')
    RESET=$(tput sgr0 2>/dev/null || echo '')
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    BOLD=''
    RESET=''
fi

# ============================================================================
# Global Variables
# ============================================================================

VERBOSE=false
DRY_RUN=false
TEST_RESULTS=()
FAILED_TESTS=()
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS_COUNT=0
START_TIME=0

# ============================================================================
# Functions
# ============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ -d "$LOG_DIR" ]] && [[ -w "$LOG_DIR" ]]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi

    if [[ "$VERBOSE" == true ]] || [[ "$level" != "DEBUG" ]]; then
        case "$level" in
            ERROR)   echo "${RED}[ERROR]${RESET} $message" >&2 ;;
            WARN)    echo "${YELLOW}[WARN]${RESET} $message" ;;
            SUCCESS) echo "${GREEN}[OK]${RESET} $message" ;;
            INFO)    echo "${BLUE}[INFO]${RESET} $message" ;;
            DEBUG)   echo "${CYAN}[DEBUG]${RESET} $message" ;;
            *)       echo "$message" ;;
        esac
    fi
}

usage() {
    cat << EOF
${BOLD}Academic Workflow Suite - Comprehensive Test Runner${RESET}

Usage: $0 [OPTIONS]

OPTIONS:
    --verbose           Enable verbose output
    --dry-run           Simulate test execution
    --coverage          Generate code coverage reports
    --parallel          Run tests in parallel where possible
    --fail-fast         Stop on first test failure
    --rust-only         Run only Rust tests
    --elixir-only       Run only Elixir tests
    --rescript-only     Run only ReScript tests
    --integration-only  Run only integration tests
    --ai-only           Run only AI isolation tests
    --skip-rust         Skip Rust tests
    --skip-elixir       Skip Elixir tests
    --skip-rescript     Skip ReScript tests
    --skip-integration  Skip integration tests
    --skip-ai           Skip AI isolation tests
    -h, --help          Show this help message

TEST SUITES:
    - Rust tests (cargo test)
    - Elixir tests (mix test)
    - ReScript tests (npm test)
    - Integration tests
    - AI isolation tests

EXIT CODES:
    0    All tests passed
    1    One or more tests failed
    2    Test execution error

EXAMPLES:
    $0                      # Run all tests
    $0 --coverage           # Run all tests with coverage
    $0 --rust-only          # Run only Rust tests
    $0 --skip-integration   # Skip integration tests
    $0 --fail-fast          # Stop on first failure

EOF
    exit 0
}

print_header() {
    local title="$1"
    local width=60

    echo ""
    echo "${BOLD}${CYAN}$(printf '=%.0s' $(seq 1 $width))${RESET}"
    printf "${BOLD}${CYAN}%-${width}s${RESET}\n" "  $title"
    echo "${BOLD}${CYAN}$(printf '=%.0s' $(seq 1 $width))${RESET}"
    echo ""
}

print_separator() {
    echo "${CYAN}$(printf -- '-%.0s' $(seq 1 60))${RESET}"
}

add_test_result() {
    local suite="$1"
    local status="$2"
    local duration="$3"
    local details="${4:-}"

    TEST_RESULTS+=("$suite|$status|$duration|$details")
    ((TOTAL_TESTS++))

    if [[ "$status" == "PASS" ]]; then
        ((PASSED_TESTS++))
    else
        ((FAILED_TESTS_COUNT++))
        FAILED_TESTS+=("$suite")
    fi
}

run_rust_tests() {
    print_header "Running Rust Tests"

    local backend_dir="$PROJECT_ROOT/components/backend"
    local ai_jail_dir="$PROJECT_ROOT/components/ai-jail"

    if [[ ! -d "$backend_dir" ]] && [[ ! -d "$ai_jail_dir" ]]; then
        log WARN "No Rust components found, skipping Rust tests"
        return 0
    fi

    if ! command -v cargo &> /dev/null; then
        log ERROR "cargo not found, cannot run Rust tests"
        add_test_result "rust" "FAIL" "0s" "cargo not installed"
        return 1
    fi

    local start
    start=$(date +%s)

    # Test backend
    if [[ -d "$backend_dir" ]]; then
        log INFO "Testing backend component..."

        if [[ "$DRY_RUN" == true ]]; then
            log DEBUG "DRY-RUN: Would run cargo test in $backend_dir"
        else
            local output
            local exit_code=0

            if [[ "$VERBOSE" == true ]]; then
                (cd "$backend_dir" && cargo test --color always) || exit_code=$?
            else
                output=$(cd "$backend_dir" && cargo test --color always 2>&1) || exit_code=$?
                echo "$output" | tail -20
            fi

            if [[ $exit_code -eq 0 ]]; then
                log SUCCESS "Backend tests passed"
            else
                log ERROR "Backend tests failed"
                [[ "$VERBOSE" == false ]] && echo "$output"
                [[ "$FAIL_FAST" == true ]] && exit 1
            fi
        fi
    fi

    # Test AI jail
    if [[ -d "$ai_jail_dir" ]]; then
        log INFO "Testing AI jail component..."

        if [[ "$DRY_RUN" == true ]]; then
            log DEBUG "DRY-RUN: Would run cargo test in $ai_jail_dir"
        else
            local output
            local exit_code=0

            if [[ "$VERBOSE" == true ]]; then
                (cd "$ai_jail_dir" && cargo test --color always) || exit_code=$?
            else
                output=$(cd "$ai_jail_dir" && cargo test --color always 2>&1) || exit_code=$?
                echo "$output" | tail -20
            fi

            if [[ $exit_code -eq 0 ]]; then
                log SUCCESS "AI jail tests passed"
            else
                log ERROR "AI jail tests failed"
                [[ "$VERBOSE" == false ]] && echo "$output"
                [[ "$FAIL_FAST" == true ]] && exit 1
            fi
        fi
    fi

    # Generate coverage if requested
    if [[ "$GENERATE_COVERAGE" == true ]] && [[ "$DRY_RUN" == false ]]; then
        log INFO "Generating Rust coverage report..."

        if command -v cargo-tarpaulin &> /dev/null; then
            (cd "$backend_dir" && cargo tarpaulin --out Html --output-dir "$PROJECT_ROOT/coverage/rust") || true
            log SUCCESS "Coverage report generated at coverage/rust/index.html"
        else
            log WARN "cargo-tarpaulin not installed, skipping Rust coverage"
        fi
    fi

    local end
    end=$(date +%s)
    local duration=$((end - start))

    if [[ $exit_code -eq 0 ]]; then
        add_test_result "rust" "PASS" "${duration}s" ""
    else
        add_test_result "rust" "FAIL" "${duration}s" ""
        return 1
    fi
}

run_elixir_tests() {
    print_header "Running Elixir Tests"

    local backend_dir="$PROJECT_ROOT/components/backend"

    if [[ ! -d "$backend_dir/mix.exs" ]] && [[ ! -f "$backend_dir/mix.exs" ]]; then
        log WARN "No Elixir project found, skipping Elixir tests"
        return 0
    fi

    if ! command -v mix &> /dev/null; then
        log ERROR "mix not found, cannot run Elixir tests"
        add_test_result "elixir" "FAIL" "0s" "mix not installed"
        return 1
    fi

    local start
    start=$(date +%s)

    log INFO "Testing Elixir components..."

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would run mix test"
    else
        local output
        local exit_code=0

        if [[ "$VERBOSE" == true ]]; then
            (cd "$backend_dir" && mix test --color) || exit_code=$?
        else
            output=$(cd "$backend_dir" && mix test --color 2>&1) || exit_code=$?
            echo "$output" | tail -20
        fi

        if [[ $exit_code -eq 0 ]]; then
            log SUCCESS "Elixir tests passed"
        else
            log ERROR "Elixir tests failed"
            [[ "$VERBOSE" == false ]] && echo "$output"
            [[ "$FAIL_FAST" == true ]] && exit 1
        fi
    fi

    # Generate coverage if requested
    if [[ "$GENERATE_COVERAGE" == true ]] && [[ "$DRY_RUN" == false ]]; then
        log INFO "Generating Elixir coverage report..."
        (cd "$backend_dir" && mix coveralls.html) || true
        log SUCCESS "Coverage report generated at coverage/elixir/excoveralls.html"
    fi

    local end
    end=$(date +%s)
    local duration=$((end - start))

    if [[ $exit_code -eq 0 ]]; then
        add_test_result "elixir" "PASS" "${duration}s" ""
    else
        add_test_result "elixir" "FAIL" "${duration}s" ""
        return 1
    fi
}

run_rescript_tests() {
    print_header "Running ReScript Tests"

    local office_addin_dir="$PROJECT_ROOT/components/office-addin"

    if [[ ! -d "$office_addin_dir" ]]; then
        log WARN "No ReScript components found, skipping ReScript tests"
        return 0
    fi

    if ! command -v npm &> /dev/null; then
        log ERROR "npm not found, cannot run ReScript tests"
        add_test_result "rescript" "FAIL" "0s" "npm not installed"
        return 1
    fi

    local start
    start=$(date +%s)

    log INFO "Testing ReScript components..."

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would run npm test in $office_addin_dir"
    else
        local output
        local exit_code=0

        if [[ "$VERBOSE" == true ]]; then
            (cd "$office_addin_dir" && npm test) || exit_code=$?
        else
            output=$(cd "$office_addin_dir" && npm test 2>&1) || exit_code=$?
            echo "$output" | tail -20
        fi

        if [[ $exit_code -eq 0 ]]; then
            log SUCCESS "ReScript tests passed"
        else
            log ERROR "ReScript tests failed"
            [[ "$VERBOSE" == false ]] && echo "$output"
            [[ "$FAIL_FAST" == true ]] && exit 1
        fi
    fi

    # Generate coverage if requested
    if [[ "$GENERATE_COVERAGE" == true ]] && [[ "$DRY_RUN" == false ]]; then
        log INFO "Generating ReScript coverage report..."
        (cd "$office_addin_dir" && npm run test:coverage) || true
        log SUCCESS "Coverage report generated at coverage/rescript/index.html"
    fi

    local end
    end=$(date +%s)
    local duration=$((end - start))

    if [[ $exit_code -eq 0 ]]; then
        add_test_result "rescript" "PASS" "${duration}s" ""
    else
        add_test_result "rescript" "FAIL" "${duration}s" ""
        return 1
    fi
}

run_integration_tests() {
    print_header "Running Integration Tests"

    local tests_dir="$PROJECT_ROOT/tests/integration"

    if [[ ! -d "$tests_dir" ]]; then
        log WARN "No integration tests found at $tests_dir"
        return 0
    fi

    local start
    start=$(date +%s)

    log INFO "Running integration test suite..."

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would run integration tests"
    else
        local exit_code=0

        # Look for test runner script
        if [[ -f "$tests_dir/run-tests.sh" ]]; then
            if [[ "$VERBOSE" == true ]]; then
                (cd "$tests_dir" && bash run-tests.sh) || exit_code=$?
            else
                local output
                output=$(cd "$tests_dir" && bash run-tests.sh 2>&1) || exit_code=$?
                echo "$output" | tail -20
            fi
        else
            log WARN "No integration test runner found"
            return 0
        fi

        if [[ $exit_code -eq 0 ]]; then
            log SUCCESS "Integration tests passed"
        else
            log ERROR "Integration tests failed"
            [[ "$FAIL_FAST" == true ]] && exit 1
        fi
    fi

    local end
    end=$(date +%s)
    local duration=$((end - start))

    if [[ $exit_code -eq 0 ]]; then
        add_test_result "integration" "PASS" "${duration}s" ""
    else
        add_test_result "integration" "FAIL" "${duration}s" ""
        return 1
    fi
}

run_ai_isolation_tests() {
    print_header "Running AI Isolation Tests"

    local tests_dir="$PROJECT_ROOT/tests/ai-isolation"

    if [[ ! -d "$tests_dir" ]]; then
        log WARN "No AI isolation tests found at $tests_dir"
        return 0
    fi

    local start
    start=$(date +%s)

    log INFO "Running AI isolation test suite..."

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would run AI isolation tests"
    else
        local exit_code=0

        # Look for test runner script
        if [[ -f "$tests_dir/run-tests.sh" ]]; then
            if [[ "$VERBOSE" == true ]]; then
                (cd "$tests_dir" && bash run-tests.sh) || exit_code=$?
            else
                local output
                output=$(cd "$tests_dir" && bash run-tests.sh 2>&1) || exit_code=$?
                echo "$output" | tail -20
            fi
        else
            log WARN "No AI isolation test runner found"
            return 0
        fi

        if [[ $exit_code -eq 0 ]]; then
            log SUCCESS "AI isolation tests passed"
        else
            log ERROR "AI isolation tests failed"
            [[ "$FAIL_FAST" == true ]] && exit 1
        fi
    fi

    local end
    end=$(date +%s)
    local duration=$((end - start))

    if [[ $exit_code -eq 0 ]]; then
        add_test_result "ai_isolation" "PASS" "${duration}s" ""
    else
        add_test_result "ai_isolation" "FAIL" "${duration}s" ""
        return 1
    fi
}

print_summary() {
    print_header "Test Summary"

    echo ""
    printf "  ${BOLD}%-20s %-10s %-10s${RESET}\n" "Test Suite" "Status" "Duration"
    print_separator

    for result in "${TEST_RESULTS[@]}"; do
        IFS='|' read -r suite status duration details <<< "$result"

        local status_color=""
        local status_text=""

        case "$status" in
            PASS)
                status_color="$GREEN"
                status_text="PASSED"
                ;;
            FAIL)
                status_color="$RED"
                status_text="FAILED"
                ;;
        esac

        printf "  %-20s ${status_color}%-10s${RESET} %-10s\n" "$suite" "$status_text" "$duration"
    done

    print_separator
    echo ""

    local total_duration=$(($(date +%s) - START_TIME))

    printf "  ${BOLD}Total:${RESET} %d tests, ${GREEN}%d passed${RESET}, ${RED}%d failed${RESET}\n" \
        "$TOTAL_TESTS" "$PASSED_TESTS" "$FAILED_TESTS_COUNT"
    printf "  ${BOLD}Duration:${RESET} %ds\n" "$total_duration"

    echo ""

    if [[ $FAILED_TESTS_COUNT -eq 0 ]]; then
        echo "${GREEN}${BOLD}All tests passed!${RESET}"
        return 0
    else
        echo "${RED}${BOLD}Some tests failed:${RESET}"
        for suite in "${FAILED_TESTS[@]}"; do
            echo "  ${RED}- $suite${RESET}"
        done
        return 1
    fi
}

main() {
    START_TIME=$(date +%s)

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose)
                VERBOSE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --coverage)
                GENERATE_COVERAGE=true
                shift
                ;;
            --parallel)
                PARALLEL_TESTS=true
                shift
                ;;
            --fail-fast)
                FAIL_FAST=true
                shift
                ;;
            --rust-only)
                RUN_ELIXIR_TESTS=false
                RUN_RESCRIPT_TESTS=false
                RUN_INTEGRATION_TESTS=false
                RUN_AI_ISOLATION_TESTS=false
                shift
                ;;
            --elixir-only)
                RUN_RUST_TESTS=false
                RUN_RESCRIPT_TESTS=false
                RUN_INTEGRATION_TESTS=false
                RUN_AI_ISOLATION_TESTS=false
                shift
                ;;
            --rescript-only)
                RUN_RUST_TESTS=false
                RUN_ELIXIR_TESTS=false
                RUN_INTEGRATION_TESTS=false
                RUN_AI_ISOLATION_TESTS=false
                shift
                ;;
            --integration-only)
                RUN_RUST_TESTS=false
                RUN_ELIXIR_TESTS=false
                RUN_RESCRIPT_TESTS=false
                RUN_AI_ISOLATION_TESTS=false
                shift
                ;;
            --ai-only)
                RUN_RUST_TESTS=false
                RUN_ELIXIR_TESTS=false
                RUN_RESCRIPT_TESTS=false
                RUN_INTEGRATION_TESTS=false
                shift
                ;;
            --skip-rust)
                RUN_RUST_TESTS=false
                shift
                ;;
            --skip-elixir)
                RUN_ELIXIR_TESTS=false
                shift
                ;;
            --skip-rescript)
                RUN_RESCRIPT_TESTS=false
                shift
                ;;
            --skip-integration)
                RUN_INTEGRATION_TESTS=false
                shift
                ;;
            --skip-ai)
                RUN_AI_ISOLATION_TESTS=false
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage
                ;;
        esac
    done

    # Create log directory if it doesn't exist
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || true
    fi

    print_header "Academic Workflow Suite - Test Runner"

    log INFO "Starting comprehensive test suite..."
    [[ "$DRY_RUN" == true ]] && log INFO "Running in DRY-RUN mode"
    [[ "$GENERATE_COVERAGE" == true ]] && log INFO "Code coverage enabled"

    # Run test suites
    [[ "$RUN_RUST_TESTS" == true ]] && run_rust_tests || true
    [[ "$RUN_ELIXIR_TESTS" == true ]] && run_elixir_tests || true
    [[ "$RUN_RESCRIPT_TESTS" == true ]] && run_rescript_tests || true
    [[ "$RUN_INTEGRATION_TESTS" == true ]] && run_integration_tests || true
    [[ "$RUN_AI_ISOLATION_TESTS" == true ]] && run_ai_isolation_tests || true

    # Print summary
    print_summary

    # Exit with appropriate code
    if [[ $FAILED_TESTS_COUNT -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# ============================================================================
# Entry Point
# ============================================================================

main "$@"
