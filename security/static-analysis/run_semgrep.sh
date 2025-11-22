#!/bin/bash
# Run Semgrep SAST (Static Application Security Testing)

set -euo pipefail

echo "Running Semgrep Security Analysis..."
echo "====================================="
echo ""

PROJECT_ROOT="${PROJECT_ROOT:-../..}"

if ! command -v semgrep &> /dev/null; then
    echo "Semgrep not installed. Install with: pip install semgrep"
    exit 1
fi

cd "${PROJECT_ROOT}"

# Run semgrep with security rules
semgrep scan \
    --config=auto \
    --config=p/security-audit \
    --config=p/secrets \
    --config=p/owasp-top-ten \
    --severity=ERROR \
    --severity=WARNING \
    --json \
    --output=/tmp/semgrep_results.json \
    .

# Print summary
echo ""
echo "Semgrep results saved to: /tmp/semgrep_results.json"

# Check for findings
findings=$(jq '.results | length' /tmp/semgrep_results.json 2>/dev/null || echo "0")

if [ "$findings" -gt 0 ]; then
    echo "Findings: ${findings}"
    echo "Review the report for details."
    exit 1
else
    echo "Semgrep Security Analysis: PASS ✓"
    exit 0
fi
