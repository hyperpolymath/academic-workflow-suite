#!/bin/bash
# Dependency Audit Script
# Checks for known vulnerabilities across all dependency ecosystems

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPORT_DIR="${PROJECT_ROOT}/security/reports/dependency-audit"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/audit_${TIMESTAMP}.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create report directory
mkdir -p "${REPORT_DIR}"

echo "========================================="
echo "Dependency Security Audit"
echo "========================================="
echo "Project: Academic Workflow Suite"
echo "Timestamp: ${TIMESTAMP}"
echo "========================================="
echo ""

# Initialize report
cat > "${REPORT_FILE}" <<EOF
{
  "timestamp": "${TIMESTAMP}",
  "project": "academic-workflow-suite",
  "audits": {
EOF

FIRST_AUDIT=true
CRITICAL_VULNS=0
HIGH_VULNS=0
MEDIUM_VULNS=0
LOW_VULNS=0

# Function to add audit result to report
add_audit_result() {
    local ecosystem=$1
    local status=$2
    local details=$3

    if [ "$FIRST_AUDIT" = false ]; then
        echo "," >> "${REPORT_FILE}"
    fi
    FIRST_AUDIT=false

    cat >> "${REPORT_FILE}" <<EOF
    "${ecosystem}": {
      "status": "${status}",
      "details": ${details}
    }
EOF
}

# =====================================
# Rust Dependency Audit
# =====================================
echo -e "${YELLOW}[1/3] Auditing Rust dependencies...${NC}"

if [ -f "${PROJECT_ROOT}/Cargo.toml" ]; then
    # Install cargo-audit if not present
    if ! command -v cargo-audit &> /dev/null; then
        echo "Installing cargo-audit..."
        cargo install cargo-audit
    fi

    # Run cargo audit
    cd "${PROJECT_ROOT}"
    if RUST_AUDIT=$(cargo audit --json 2>&1); then
        RUST_VULNS=$(echo "$RUST_AUDIT" | jq '.vulnerabilities.count // 0')

        if [ "$RUST_VULNS" -eq 0 ]; then
            echo -e "${GREEN}✓ No vulnerabilities found in Rust dependencies${NC}"
            add_audit_result "rust" "clean" '{"vulnerabilities": 0}'
        else
            echo -e "${RED}✗ Found ${RUST_VULNS} vulnerabilities in Rust dependencies${NC}"
            CRITICAL_VULNS=$((CRITICAL_VULNS + $(echo "$RUST_AUDIT" | jq '[.vulnerabilities.list[] | select(.advisory.severity == "critical")] | length')))
            HIGH_VULNS=$((HIGH_VULNS + $(echo "$RUST_AUDIT" | jq '[.vulnerabilities.list[] | select(.advisory.severity == "high")] | length')))
            MEDIUM_VULNS=$((MEDIUM_VULNS + $(echo "$RUST_AUDIT" | jq '[.vulnerabilities.list[] | select(.advisory.severity == "medium")] | length')))
            LOW_VULNS=$((LOW_VULNS + $(echo "$RUST_AUDIT" | jq '[.vulnerabilities.list[] | select(.advisory.severity == "low")] | length')))

            add_audit_result "rust" "vulnerable" "$RUST_AUDIT"
        fi
    else
        echo -e "${RED}✗ Error running cargo audit${NC}"
        add_audit_result "rust" "error" '{"error": "Failed to run cargo audit"}'
    fi
else
    echo -e "${YELLOW}⊘ No Cargo.toml found, skipping Rust audit${NC}"
    add_audit_result "rust" "skipped" '{"reason": "No Cargo.toml found"}'
fi

echo ""

# =====================================
# Elixir Dependency Audit
# =====================================
echo -e "${YELLOW}[2/3] Auditing Elixir dependencies...${NC}"

if [ -f "${PROJECT_ROOT}/mix.exs" ]; then
    cd "${PROJECT_ROOT}"

    # Run mix hex.audit
    if ELIXIR_AUDIT=$(mix hex.audit 2>&1); then
        if echo "$ELIXIR_AUDIT" | grep -q "No retired packages found"; then
            echo -e "${GREEN}✓ No vulnerabilities found in Elixir dependencies${NC}"
            add_audit_result "elixir" "clean" '{"vulnerabilities": 0}'
        else
            ELIXIR_VULNS=$(echo "$ELIXIR_AUDIT" | grep -c "Retired" || echo "0")
            echo -e "${RED}✗ Found ${ELIXIR_VULNS} retired packages in Elixir dependencies${NC}"
            HIGH_VULNS=$((HIGH_VULNS + ELIXIR_VULNS))

            add_audit_result "elixir" "vulnerable" "{\"vulnerabilities\": ${ELIXIR_VULNS}, \"details\": \"$(echo "$ELIXIR_AUDIT" | jq -Rs .)\"}"
        fi
    else
        echo -e "${RED}✗ Error running mix hex.audit${NC}"
        add_audit_result "elixir" "error" '{"error": "Failed to run mix hex.audit"}'
    fi
else
    echo -e "${YELLOW}⊘ No mix.exs found, skipping Elixir audit${NC}"
    add_audit_result "elixir" "skipped" '{"reason": "No mix.exs found"}'
fi

echo ""

# =====================================
# Node.js Dependency Audit
# =====================================
echo -e "${YELLOW}[3/3] Auditing Node.js dependencies...${NC}"

if [ -f "${PROJECT_ROOT}/package.json" ]; then
    cd "${PROJECT_ROOT}"

    # Run npm audit
    if NPM_AUDIT=$(npm audit --json 2>&1); then
        NPM_VULNS=$(echo "$NPM_AUDIT" | jq '.metadata.vulnerabilities.total // 0')

        if [ "$NPM_VULNS" -eq 0 ]; then
            echo -e "${GREEN}✓ No vulnerabilities found in Node.js dependencies${NC}"
            add_audit_result "nodejs" "clean" '{"vulnerabilities": 0}'
        else
            echo -e "${RED}✗ Found ${NPM_VULNS} vulnerabilities in Node.js dependencies${NC}"
            CRITICAL_VULNS=$((CRITICAL_VULNS + $(echo "$NPM_AUDIT" | jq '.metadata.vulnerabilities.critical // 0')))
            HIGH_VULNS=$((HIGH_VULNS + $(echo "$NPM_AUDIT" | jq '.metadata.vulnerabilities.high // 0')))
            MEDIUM_VULNS=$((MEDIUM_VULNS + $(echo "$NPM_AUDIT" | jq '.metadata.vulnerabilities.moderate // 0')))
            LOW_VULNS=$((LOW_VULNS + $(echo "$NPM_AUDIT" | jq '.metadata.vulnerabilities.low // 0')))

            add_audit_result "nodejs" "vulnerable" "$NPM_AUDIT"
        fi
    else
        echo -e "${RED}✗ Error running npm audit${NC}"
        add_audit_result "nodejs" "error" '{"error": "Failed to run npm audit"}'
    fi
else
    echo -e "${YELLOW}⊘ No package.json found, skipping Node.js audit${NC}"
    add_audit_result "nodejs" "skipped" '{"reason": "No package.json found"}'
fi

# Close JSON report
cat >> "${REPORT_FILE}" <<EOF
  },
  "summary": {
    "critical": ${CRITICAL_VULNS},
    "high": ${HIGH_VULNS},
    "medium": ${MEDIUM_VULNS},
    "low": ${LOW_VULNS},
    "total": $((CRITICAL_VULNS + HIGH_VULNS + MEDIUM_VULNS + LOW_VULNS))
  }
}
EOF

echo ""
echo "========================================="
echo "Audit Summary"
echo "========================================="
echo -e "Critical: ${RED}${CRITICAL_VULNS}${NC}"
echo -e "High:     ${RED}${HIGH_VULNS}${NC}"
echo -e "Medium:   ${YELLOW}${MEDIUM_VULNS}${NC}"
echo -e "Low:      ${YELLOW}${LOW_VULNS}${NC}"
echo -e "Total:    $((CRITICAL_VULNS + HIGH_VULNS + MEDIUM_VULNS + LOW_VULNS))"
echo ""
echo "Report saved to: ${REPORT_FILE}"
echo "========================================="

# Exit with error if critical or high vulnerabilities found
if [ $((CRITICAL_VULNS + HIGH_VULNS)) -gt 0 ]; then
    echo -e "${RED}FAIL: Critical or high severity vulnerabilities detected${NC}"
    exit 1
fi

echo -e "${GREEN}PASS: No critical or high severity vulnerabilities detected${NC}"
exit 0
