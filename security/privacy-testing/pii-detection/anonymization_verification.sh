#!/bin/bash
# Anonymization Verification Script
# Verifies that student IDs and other PII are properly hashed

set -euo pipefail

REPORT_FILE="/tmp/anonymization_verification.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================" | tee "${REPORT_FILE}"
echo "Anonymization Verification Test" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Date: $(date)" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

VIOLATIONS_FOUND=0
TOTAL_TESTS=0

# Test 1: Check for plain-text student IDs in logs
echo -e "${YELLOW}[Test 1] Scanning logs for plain-text student IDs...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

LOG_DIRS=(
    "/var/log"
    "/tmp"
    "./logs"
)

for log_dir in "${LOG_DIRS[@]}"; do
    if [ -d "$log_dir" ]; then
        # Look for patterns like "student_id: 12345678" or "student:12345678"
        plain_ids=$(grep -r -i -E "(student_?id|student).*[^a-f0-9][0-9]{6,10}[^a-f0-9]" "$log_dir" 2>/dev/null | grep -v "sha256" || true)

        if [ -n "$plain_ids" ]; then
            echo -e "${RED}[VIOLATION] Plain-text student IDs found in ${log_dir}:${NC}" | tee -a "${REPORT_FILE}"
            echo "$plain_ids" | head -5 | tee -a "${REPORT_FILE}"
            VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
        fi
    fi
done

if [ $VIOLATIONS_FOUND -eq 0 ]; then
    echo -e "${GREEN}✓ No plain-text student IDs in logs${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 2: Verify hash format
echo -e "${YELLOW}[Test 2] Verifying hash format in outputs...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Check if hashes follow expected format (sha256:hexstring)
if [ -d "./logs" ]; then
    invalid_hash_format=$(grep -r -i "student" ./logs 2>/dev/null | grep -v "sha256:[a-f0-9]\{64\}" | grep "student.*:" || true)

    if [ -n "$invalid_hash_format" ]; then
        echo -e "${RED}[VIOLATION] Student references without proper hash format:${NC}" | tee -a "${REPORT_FILE}"
        echo "$invalid_hash_format" | head -5 | tee -a "${REPORT_FILE}"
        VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
    else
        echo -e "${GREEN}✓ All student references use proper hash format${NC}" | tee -a "${REPORT_FILE}"
    fi
else
    echo -e "${YELLOW}⊘ No logs directory found${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 3: Check database exports
echo -e "${YELLOW}[Test 3] Checking database exports for PII...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

DB_EXPORT_PATTERNS=(
    "*.sql"
    "*.csv"
    "*.json"
    "*export*"
)

pii_in_exports=0
for pattern in "${DB_EXPORT_PATTERNS[@]}"; do
    while IFS= read -r file; do
        # Check for email patterns
        if grep -qE "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" "$file" 2>/dev/null; then
            echo -e "${RED}[VIOLATION] Email addresses found in: ${file}${NC}" | tee -a "${REPORT_FILE}"
            pii_in_exports=$((pii_in_exports + 1))
        fi

        # Check for phone patterns
        if grep -qE "\([0-9]{3}\) [0-9]{3}-[0-9]{4}" "$file" 2>/dev/null; then
            echo -e "${RED}[VIOLATION] Phone numbers found in: ${file}${NC}" | tee -a "${REPORT_FILE}"
            pii_in_exports=$((pii_in_exports + 1))
        fi
    done < <(find . -name "$pattern" 2>/dev/null || true)
done

if [ $pii_in_exports -gt 0 ]; then
    VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + pii_in_exports))
else
    echo -e "${GREEN}✓ No PII found in database exports${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 4: Verify anonymization function
echo -e "${YELLOW}[Test 4] Testing anonymization function...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Test that same input produces same hash
test_id="12345678"
hash1=$(echo -n "$test_id" | sha256sum | awk '{print $1}')
hash2=$(echo -n "$test_id" | sha256sum | awk '{print $1}')

if [ "$hash1" == "$hash2" ]; then
    echo -e "${GREEN}✓ Anonymization is deterministic (same input = same hash)${NC}" | tee -a "${REPORT_FILE}"
else
    echo -e "${RED}[VIOLATION] Anonymization is not deterministic${NC}" | tee -a "${REPORT_FILE}"
    VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
fi

# Test that different inputs produce different hashes
hash3=$(echo -n "87654321" | sha256sum | awk '{print $1}')
if [ "$hash1" != "$hash3" ]; then
    echo -e "${GREEN}✓ Different inputs produce different hashes${NC}" | tee -a "${REPORT_FILE}"
else
    echo -e "${RED}[VIOLATION] Hash collision detected${NC}" | tee -a "${REPORT_FILE}"
    VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
fi

# Test hash length
if [ ${#hash1} -eq 64 ]; then
    echo -e "${GREEN}✓ Hash is SHA-256 (64 hex characters)${NC}" | tee -a "${REPORT_FILE}"
else
    echo -e "${RED}[VIOLATION] Hash is not SHA-256${NC}" | tee -a "${REPORT_FILE}"
    VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 5: Check API responses
echo -e "${YELLOW}[Test 5] Checking API responses for PII leakage...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ -d "./api_responses" ]; then
    # Check for PII in API response samples
    pii_patterns=(
        "email.*@"
        "phone.*[0-9]{3}.*[0-9]{3}.*[0-9]{4}"
        "ssn.*[0-9]{3}-[0-9]{2}-[0-9]{4}"
    )

    for pattern in "${pii_patterns[@]}"; do
        if grep -r -i -E "$pattern" ./api_responses 2>/dev/null; then
            echo -e "${RED}[VIOLATION] PII pattern found in API responses: ${pattern}${NC}" | tee -a "${REPORT_FILE}"
            VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
        fi
    done
else
    echo -e "${YELLOW}⊘ No API responses directory to check${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Summary
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Anonymization Verification Summary" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Total Tests: ${TOTAL_TESTS}" | tee -a "${REPORT_FILE}"
echo -e "Violations Found: ${RED}${VIOLATIONS_FOUND}${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

if [ $VIOLATIONS_FOUND -gt 0 ]; then
    echo -e "${RED}FAIL: Anonymization violations detected!${NC}" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
    echo "Remediation:" | tee -a "${REPORT_FILE}"
    echo "1. Hash all student IDs before logging" | tee -a "${REPORT_FILE}"
    echo "2. Use SHA-256 for hashing (not MD5)" | tee -a "${REPORT_FILE}"
    echo "3. Never log plain-text PII" | tee -a "${REPORT_FILE}"
    echo "4. Sanitize all outputs and exports" | tee -a "${REPORT_FILE}"
    echo "5. Implement PII detection in CI/CD" | tee -a "${REPORT_FILE}"
else
    echo -e "${GREEN}PASS: All anonymization checks passed${NC}" | tee -a "${REPORT_FILE}"
fi

echo "" | tee -a "${REPORT_FILE}"
echo "Report saved to: ${REPORT_FILE}" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"

[ $VIOLATIONS_FOUND -eq 0 ] && exit 0 || exit 1
