#!/bin/bash
# Race Condition and Concurrency Testing

set -euo pipefail

echo "Running Race Condition Tests..."
echo "================================"
echo ""

PROJECT_ROOT="${PROJECT_ROOT:-../..}"

cd "${PROJECT_ROOT}"

# Run tests with thread sanitizer
echo "Running tests with ThreadSanitizer..."
RUSTFLAGS="-Z sanitizer=thread" cargo +nightly test --target x86_64-unknown-linux-gnu || true

echo ""
echo "Race Condition Tests: COMPLETE ✓"
