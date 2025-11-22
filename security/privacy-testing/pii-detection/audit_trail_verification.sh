#!/bin/bash
# Audit Trail Verification
# Ensures complete audit logging of all operations

set -euo pipefail

REPORT_FILE="/tmp/audit_trail_report.txt"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================" | tee "${REPORT_FILE}"
echo "Audit Trail Verification Test" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Date: $(date)" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

VIOLATIONS_FOUND=0
TOTAL_TESTS=0

# Test 1: Check audit log exists and is writable
echo -e "${YELLOW}[Test 1] Checking audit log configuration...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

AUDIT_LOG_PATHS=(
    "/var/log/audit/audit.log"
    "./logs/audit.log"
    "/var/log/academic-workflow/audit.log"
)

audit_log_found=false
for log_path in "${AUDIT_LOG_PATHS[@]}"; do
    if [ -f "$log_path" ]; then
        echo -e "${GREEN}✓ Audit log found: ${log_path}${NC}" | tee -a "${REPORT_FILE}"
        audit_log_found=true
        AUDIT_LOG="$log_path"
        break
    fi
done

if [ "$audit_log_found" = false ]; then
    echo -e "${RED}[VIOLATION] No audit log found${NC}" | tee -a "${REPORT_FILE}"
    VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 2: Verify required audit fields
echo -e "${YELLOW}[Test 2] Verifying audit log structure...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

REQUIRED_FIELDS=(
    "timestamp"
    "user"
    "action"
    "resource"
    "result"
)

if [ "$audit_log_found" = true ] && [ -s "$AUDIT_LOG" ]; then
    missing_fields=()
    for field in "${REQUIRED_FIELDS[@]}"; do
        if ! grep -q "$field" "$AUDIT_LOG"; then
            missing_fields+=("$field")
        fi
    done

    if [ ${#missing_fields[@]} -gt 0 ]; then
        echo -e "${RED}[VIOLATION] Missing audit fields: ${missing_fields[*]}${NC}" | tee -a "${REPORT_FILE}"
        VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
    else
        echo -e "${GREEN}✓ All required fields present${NC}" | tee -a "${REPORT_FILE}"
    fi
else
    echo -e "${YELLOW}⊘ Cannot verify (no audit log)${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 3: Check for operations without audit trail
echo -e "${YELLOW}[Test 3] Checking operation coverage...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

CRITICAL_OPERATIONS=(
    "grade_update"
    "student_data_access"
    "assignment_submission"
    "feedback_generation"
    "admin_access"
)

if [ "$audit_log_found" = true ]; then
    unlogged_ops=()
    for operation in "${CRITICAL_OPERATIONS[@]}"; do
        if ! grep -q "$operation" "$AUDIT_LOG" 2>/dev/null; then
            unlogged_ops+=("$operation")
        fi
    done

    if [ ${#unlogged_ops[@]} -gt 0 ]; then
        echo -e "${YELLOW}[WARNING] Operations with no audit entries: ${unlogged_ops[*]}${NC}" | tee -a "${REPORT_FILE}"
    else
        echo -e "${GREEN}✓ All critical operations have audit entries${NC}" | tee -a "${REPORT_FILE}"
    fi
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 4: Verify immutability
echo -e "${YELLOW}[Test 4] Checking audit log immutability...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ "$audit_log_found" = true ]; then
    # Check file permissions
    if [ -w "$AUDIT_LOG" ]; then
        echo -e "${YELLOW}[WARNING] Audit log is writable (should be append-only)${NC}" | tee -a "${REPORT_FILE}"
    else
        echo -e "${GREEN}✓ Audit log is read-only/append-only${NC}" | tee -a "${REPORT_FILE}"
    fi

    # Check if log rotation preserves logs
    if [ -d "$(dirname "$AUDIT_LOG")" ]; then
        rotated_logs=$(find "$(dirname "$AUDIT_LOG")" -name "audit.log.*" 2>/dev/null | wc -l)
        echo "Rotated audit logs found: ${rotated_logs}" | tee -a "${REPORT_FILE}"
    fi
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 5: Check timestamp accuracy
echo -e "${YELLOW}[Test 5] Verifying timestamp accuracy...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ "$audit_log_found" = true ] && [ -s "$AUDIT_LOG" ]; then
    # Check if timestamps are recent and properly formatted
    recent_entries=$(grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}" "$AUDIT_LOG" | tail -5)

    if [ -n "$recent_entries" ]; then
        echo -e "${GREEN}✓ Timestamps properly formatted (ISO 8601)${NC}" | tee -a "${REPORT_FILE}"
    else
        echo -e "${YELLOW}[WARNING] Timestamp format not verified${NC}" | tee -a "${REPORT_FILE}"
    fi
fi
echo "" | tee -a "${REPORT_FILE}"

# Summary
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Audit Trail Verification Summary" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Total Tests: ${TOTAL_TESTS}" | tee -a "${REPORT_FILE}"
echo -e "Violations Found: ${RED}${VIOLATIONS_FOUND}${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

if [ $VIOLATIONS_FOUND -gt 0 ]; then
    echo -e "${RED}FAIL: Audit trail violations detected!${NC}" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
    echo "Remediation:" | tee -a "${REPORT_FILE}"
    echo "1. Implement comprehensive audit logging" | tee -a "${REPORT_FILE}"
    echo "2. Log all critical operations" | tee -a "${REPORT_FILE}"
    echo "3. Use structured logging (JSON)" | tee -a "${REPORT_FILE}"
    echo "4. Make audit logs append-only" | tee -a "${REPORT_FILE}"
    echo "5. Implement log retention and archival" | tee -a "${REPORT_FILE}"
else
    echo -e "${GREEN}PASS: Audit trail properly configured${NC}" | tee -a "${REPORT_FILE}"
fi

echo "" | tee -a "${REPORT_FILE}"
echo "Report saved to: ${REPORT_FILE}" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"

[ $VIOLATIONS_FOUND -eq 0 ] && exit 0 || exit 1
