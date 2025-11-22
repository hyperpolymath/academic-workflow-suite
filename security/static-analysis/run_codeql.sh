#!/bin/bash
# Run GitHub CodeQL analysis

set -euo pipefail

echo "Running CodeQL Security Analysis..."
echo "===================================="
echo ""

PROJECT_ROOT="${PROJECT_ROOT:-../..}"

if ! command -v codeql &> /dev/null; then
    echo "CodeQL not installed. Install from: https://github.com/github/codeql-cli-binaries"
    echo "This is typically run in GitHub Actions."
    exit 0
fi

cd "${PROJECT_ROOT}"

# Create CodeQL database
echo "Creating CodeQL database..."
codeql database create ./codeql-db --language=javascript,python,rust

# Run analysis
echo "Running security queries..."
codeql database analyze ./codeql-db \
    --format=sarif-latest \
    --output=/tmp/codeql_results.sarif \
    security-and-quality

# Print results
echo ""
echo "CodeQL results saved to: /tmp/codeql_results.sarif"
echo "CodeQL Security Analysis: COMPLETE ✓"
