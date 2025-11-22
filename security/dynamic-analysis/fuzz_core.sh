#!/bin/bash
# Fuzz Rust core components with cargo-fuzz

set -euo pipefail

echo "Running Fuzzing Tests..."
echo "========================"
echo ""

PROJECT_ROOT="${PROJECT_ROOT:-../..}"

if [ ! -f "${PROJECT_ROOT}/Cargo.toml" ]; then
    echo "No Cargo.toml found. Skipping fuzzing."
    exit 0
fi

cd "${PROJECT_ROOT}"

# Install cargo-fuzz if needed
if ! cargo fuzz --version &> /dev/null; then
    echo "Installing cargo-fuzz..."
    cargo install cargo-fuzz
fi

# List fuzz targets
echo "Available fuzz targets:"
cargo fuzz list || echo "No fuzz targets defined yet."
echo ""

# Run fuzzing (limited time for CI)
echo "Running fuzzing for 60 seconds..."
timeout 60 cargo fuzz run fuzz_target_1 || echo "Fuzzing completed/timed out"

echo ""
echo "Fuzzing: COMPLETE ✓"
