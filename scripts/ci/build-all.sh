#!/bin/bash
# Build all components for Academic Workflow Suite
# Usage: ./build-all.sh [--release|--debug]

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BUILD_MODE="${1:-release}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_LOG="${ROOT_DIR}/build.log"
START_TIME=$(date +%s)

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Initialize build log
echo "Build started at $(date)" > "$BUILD_LOG"
echo "Build mode: $BUILD_MODE" >> "$BUILD_LOG"
echo "======================================" >> "$BUILD_LOG"

# Build Rust Core Component
build_rust_core() {
    log_info "Building Rust core component..."
    cd "$ROOT_DIR/components/core"

    if [ "$BUILD_MODE" = "release" ]; then
        cargo build --release --verbose 2>&1 | tee -a "$BUILD_LOG"
    else
        cargo build --verbose 2>&1 | tee -a "$BUILD_LOG"
    fi

    if [ $? -eq 0 ]; then
        log_success "Rust core built successfully"
    else
        log_error "Failed to build Rust core"
        return 1
    fi
}

# Build Rust AI Jail Component
build_rust_ai_jail() {
    log_info "Building Rust AI jail component..."
    cd "$ROOT_DIR/components/ai-jail"

    if [ "$BUILD_MODE" = "release" ]; then
        cargo build --release --verbose 2>&1 | tee -a "$BUILD_LOG"
    else
        cargo build --verbose 2>&1 | tee -a "$BUILD_LOG"
    fi

    if [ $? -eq 0 ]; then
        log_success "Rust AI jail built successfully"
    else
        log_error "Failed to build Rust AI jail"
        return 1
    fi
}

# Build Elixir Backend
build_elixir_backend() {
    log_info "Building Elixir backend..."
    cd "$ROOT_DIR/components/backend"

    # Set environment
    if [ "$BUILD_MODE" = "release" ]; then
        export MIX_ENV=prod
    else
        export MIX_ENV=dev
    fi

    # Get dependencies
    mix local.hex --force 2>&1 | tee -a "$BUILD_LOG"
    mix local.rebar --force 2>&1 | tee -a "$BUILD_LOG"
    mix deps.get 2>&1 | tee -a "$BUILD_LOG"

    # Compile
    mix compile --warnings-as-errors 2>&1 | tee -a "$BUILD_LOG"

    if [ $? -eq 0 ]; then
        log_success "Elixir backend built successfully"
    else
        log_error "Failed to build Elixir backend"
        return 1
    fi
}

# Build Office Add-in
build_office_addin() {
    log_info "Building Office add-in..."
    cd "$ROOT_DIR/components/office-addin"

    # Install dependencies
    if [ -f "package.json" ]; then
        npm ci 2>&1 | tee -a "$BUILD_LOG"

        # Build
        if [ "$BUILD_MODE" = "release" ]; then
            npm run build:prod 2>&1 | tee -a "$BUILD_LOG" || npm run build 2>&1 | tee -a "$BUILD_LOG" || {
                log_warning "No build script found for Office add-in"
                return 0
            }
        else
            npm run build 2>&1 | tee -a "$BUILD_LOG" || {
                log_warning "No build script found for Office add-in"
                return 0
            }
        fi

        log_success "Office add-in built successfully"
    else
        log_warning "No package.json found for Office add-in"
    fi
}

# Main build process
main() {
    log_info "Starting build process for Academic Workflow Suite"
    log_info "Root directory: $ROOT_DIR"
    log_info "Build mode: $BUILD_MODE"
    echo ""

    # Build components in parallel if possible
    local failed=0

    # Rust components
    if ! build_rust_core; then
        failed=$((failed + 1))
    fi
    echo ""

    if ! build_rust_ai_jail; then
        failed=$((failed + 1))
    fi
    echo ""

    # Elixir backend
    if ! build_elixir_backend; then
        failed=$((failed + 1))
    fi
    echo ""

    # Office add-in
    if ! build_office_addin; then
        failed=$((failed + 1))
    fi
    echo ""

    # Summary
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo "======================================" | tee -a "$BUILD_LOG"
    echo "Build Summary" | tee -a "$BUILD_LOG"
    echo "======================================" | tee -a "$BUILD_LOG"
    echo "Duration: ${DURATION}s" | tee -a "$BUILD_LOG"
    echo "Build log: $BUILD_LOG" | tee -a "$BUILD_LOG"

    if [ $failed -eq 0 ]; then
        log_success "All components built successfully!"
        echo ""
        log_info "Built artifacts:"

        if [ "$BUILD_MODE" = "release" ]; then
            find "$ROOT_DIR" -type f \( -path "*/target/release/*" -o -path "*/_build/prod/*" -o -path "*/dist/*" \) -executable 2>/dev/null | head -20
        else
            find "$ROOT_DIR" -type f \( -path "*/target/debug/*" -o -path "*/_build/dev/*" -o -path "*/dist/*" \) -executable 2>/dev/null | head -20
        fi

        return 0
    else
        log_error "$failed component(s) failed to build"
        return 1
    fi
}

# Run main
main
exit $?
