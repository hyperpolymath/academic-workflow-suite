#!/bin/bash
# Master Security Test Runner
# Executes all security tests in sequence

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    Academic Workflow Suite - Security Test Suite          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_test() {
    local name=$1
    local script=$2
    local required=${3:-true}

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${YELLOW}[${TOTAL_TESTS}] Running: ${name}${NC}"

    if [ -f "$script" ]; then
        if bash "$script" 2>&1 | tee "/tmp/test_${TOTAL_TESTS}.log"; then
            echo -e "${GREEN}✓ PASS${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            if [ "$required" = true ]; then
                echo -e "${RED}✗ FAIL${NC}"
                FAILED_TESTS=$((FAILED_TESTS + 1))
            else
                echo -e "${YELLOW}⊘ SKIPPED (optional)${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⊘ SKIPPED (not found: ${script})${NC}"
    fi
    echo ""
}

# 1. AUDIT SCRIPTS
echo -e "${BLUE}═══ Phase 1: Dependency & Compliance Audits ═══${NC}"
run_test "Dependency Vulnerability Scan" "./audit-scripts/dependency-audit.sh" false
run_test "License Compliance Check" "./audit-scripts/license-check.sh" false
run_test "Secret Scanning" "./audit-scripts/secret-scan.sh" true
echo ""

# 2. STATIC ANALYSIS
echo -e "${BLUE}═══ Phase 2: Static Code Analysis ═══${NC}"
run_test "Clippy Security Linting" "./static-analysis/run_clippy.sh" false
run_test "Semgrep SAST" "./static-analysis/run_semgrep.sh" false
echo ""

# 3. API PENETRATION TESTING
echo -e "${BLUE}═══ Phase 3: API Penetration Testing ═══${NC}"
run_test "SQL Injection Tests" "./penetration-testing/api-fuzzing/sql_injection_tests.sh" false
run_test "XSS Vulnerability Tests" "./penetration-testing/api-fuzzing/xss_tests.sh" false
run_test "Authentication Bypass Tests" "./penetration-testing/api-fuzzing/auth_bypass_tests.sh" false
echo ""

# 4. CONTAINER SECURITY
echo -e "${BLUE}═══ Phase 4: Container Security ═══${NC}"
run_test "Container Escape Detection" "./penetration-testing/container-escape/escape_attempts.sh" true
run_test "Privilege Escalation Tests" "./penetration-testing/container-escape/privilege_escalation.sh" true
run_test "Network Isolation Verification" "./penetration-testing/container-escape/network_isolation_verify.sh" true
run_test "Filesystem Access Boundaries" "./penetration-testing/container-escape/filesystem_access.sh" true
echo ""

# 5. PRIVACY & PII PROTECTION
echo -e "${BLUE}═══ Phase 5: Privacy & PII Protection ═══${NC}"
run_test "Anonymization Verification" "./privacy-testing/pii-detection/anonymization_verification.sh" true
run_test "Audit Trail Verification" "./privacy-testing/pii-detection/audit_trail_verification.sh" true
echo ""

# 6. GDPR COMPLIANCE
echo -e "${BLUE}═══ Phase 6: GDPR Compliance ═══${NC}"
run_test "Data Flow Audit" "./compliance/gdpr/data_flow_audit.sh" true
run_test "Retention Policy Check" "./compliance/gdpr/retention_policy_check.sh" true
run_test "Right to Erasure Test" "./compliance/gdpr/right_to_erasure_test.sh" true
run_test "Data Portability Test" "./compliance/gdpr/data_portability_test.sh" true
echo ""

# 7. DYNAMIC ANALYSIS
echo -e "${BLUE}═══ Phase 7: Dynamic Analysis ═══${NC}"
run_test "Memory Safety Tests" "./dynamic-analysis/memory_safety.sh" false
run_test "Fuzzing Tests" "./dynamic-analysis/fuzz_core.sh" false
echo ""

# 8. GENERATE REPORT
echo -e "${BLUE}═══ Phase 8: Security Report Generation ═══${NC}"
if [ -f "./reporting/generate_security_report.py" ]; then
    echo "Generating comprehensive security report..."
    python3 ./reporting/generate_security_report.py || echo "Report generation failed"
fi
echo ""

# SUMMARY
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    Test Summary                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Total Tests:  ${TOTAL_TESTS}"
echo -e "${GREEN}Passed:       ${PASSED_TESTS}${NC}"
echo -e "${RED}Failed:       ${FAILED_TESTS}${NC}"
echo ""

PASS_RATE=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))
echo -e "Pass Rate:    ${PASS_RATE}%"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ ALL SECURITY TESTS PASSED                              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ✗ SOME SECURITY TESTS FAILED                             ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Review individual test logs in /tmp/test_*.log"
    echo "See security report for details: /tmp/security_report_*.html"
    exit 1
fi
