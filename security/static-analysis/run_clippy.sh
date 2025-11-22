#!/bin/bash
# Run Clippy (Rust linter) with strict security rules

set -euo pipefail

echo "Running Clippy Security Analysis..."
echo "===================================="
echo ""

PROJECT_ROOT="${PROJECT_ROOT:-../..}"

if [ ! -f "${PROJECT_ROOT}/Cargo.toml" ]; then
    echo "No Cargo.toml found. Skipping Rust analysis."
    exit 0
fi

cd "${PROJECT_ROOT}"

# Run clippy with strict security lints
cargo clippy --all-targets --all-features -- \
    -D warnings \
    -D clippy::all \
    -D clippy::pedantic \
    -W clippy::nursery \
    -D clippy::cargo \
    -D clippy::unwrap_used \
    -D clippy::expect_used \
    -D clippy::panic \
    -D clippy::todo \
    -D clippy::unimplemented \
    -D clippy::unreachable \
    -D clippy::dbg_macro \
    -D clippy::print_stdout \
    -D clippy::print_stderr \
    -W clippy::missing_docs_in_private_items \
    -W clippy::missing_errors_doc \
    -W clippy::missing_panics_doc

echo ""
echo "Clippy Security Analysis: COMPLETE ✓"
