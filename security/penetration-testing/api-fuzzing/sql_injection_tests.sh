#!/bin/bash
# SQL Injection Penetration Tests
# Tests API endpoints for SQL injection vulnerabilities

set -euo pipefail

# Configuration
API_BASE_URL="${API_BASE_URL:-http://localhost:8000}"
REPORT_FILE="/tmp/sql_injection_report.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# SQL Injection payloads
declare -a SQL_PAYLOADS=(
    "' OR '1'='1"
    "' OR '1'='1' --"
    "' OR '1'='1' ({'"
    "' OR '1'='1' /*"
    "admin' --"
    "admin' #"
    "admin'/*"
    "' or 1=1--"
    "' or 1=1#"
    "' or 1=1/*"
    "') or '1'='1--"
    "') or ('1'='1--"
    "1' ORDER BY 1--"
    "1' ORDER BY 2--"
    "1' ORDER BY 3--"
    "1' UNION SELECT NULL--"
    "1' UNION SELECT NULL,NULL--"
    "1' UNION SELECT NULL,NULL,NULL--"
    "'; DROP TABLE students;--"
    "'; DROP DATABASE academic_db;--"
    "1'; WAITFOR DELAY '00:00:05'--"
    "1' AND SLEEP(5)--"
    "1' AND (SELECT * FROM (SELECT(SLEEP(5)))a)--"
    "' AND 1=CONVERT(int, (SELECT @@version))--"
    "' AND 1=CONVERT(int, (SELECT table_name FROM information_schema.tables))--"
)

# Test endpoints
declare -a ENDPOINTS=(
    "/api/v1/student"
    "/api/v1/assignment"
    "/api/v1/grade"
    "/api/v1/feedback"
    "/api/v1/login"
    "/api/v1/search"
)

# SQL error signatures
declare -a SQL_ERRORS=(
    "SQL syntax"
    "mysql_fetch"
    "mysql_num_rows"
    "ORA-[0-9]+"
    "PostgreSQL.*ERROR"
    "Warning.*mysql_"
    "valid MySQL result"
    "MySqlClient"
    "PostgreSQL query failed"
    "org.postgresql.util.PSQLException"
    "com.mysql.jdbc.exceptions"
    "SQLite"
    "SQLITE_ERROR"
    "sqlite3.OperationalError"
    "SQLSTATE"
    "Unclosed quotation mark"
    "quoted string not properly terminated"
)

echo "=========================================" | tee "${REPORT_FILE}"
echo "SQL Injection Penetration Test" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Target: ${API_BASE_URL}" | tee -a "${REPORT_FILE}"
echo "Date: $(date)" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

VULNERABILITIES_FOUND=0
TOTAL_TESTS=0

# Function to test endpoint with payload
test_sql_injection() {
    local endpoint=$1
    local payload=$2
    local method=${3:-GET}

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    # URL encode the payload
    encoded_payload=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$payload'))")

    # Test GET request
    if [ "$method" == "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" "${API_BASE_URL}${endpoint}?id=${encoded_payload}" 2>&1 || true)
    else
        # Test POST request
        response=$(curl -s -w "\n%{http_code}" -X POST \
            -H "Content-Type: application/json" \
            -d "{\"id\": \"${payload}\", \"data\": \"${payload}\"}" \
            "${API_BASE_URL}${endpoint}" 2>&1 || true)
    fi

    # Check for SQL errors in response
    for error_pattern in "${SQL_ERRORS[@]}"; do
        if echo "$response" | grep -qi "$error_pattern"; then
            echo -e "${RED}[VULNERABLE] ${endpoint}${NC}" | tee -a "${REPORT_FILE}"
            echo "  Method: ${method}" | tee -a "${REPORT_FILE}"
            echo "  Payload: ${payload}" | tee -a "${REPORT_FILE}"
            echo "  Error: Matched pattern '${error_pattern}'" | tee -a "${REPORT_FILE}"
            echo "  Response snippet:" | tee -a "${REPORT_FILE}"
            echo "$response" | grep -i "$error_pattern" | head -3 | sed 's/^/    /' | tee -a "${REPORT_FILE}"
            echo "" | tee -a "${REPORT_FILE}"
            VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
            return 0
        fi
    done

    # Check for timing-based SQL injection (if SLEEP or WAITFOR used)
    if [[ "$payload" =~ (SLEEP|WAITFOR) ]]; then
        # Simple timing check (should be more sophisticated in production)
        start_time=$(date +%s)
        curl -s "${API_BASE_URL}${endpoint}?id=${encoded_payload}" > /dev/null 2>&1 || true
        end_time=$(date +%s)
        elapsed=$((end_time - start_time))

        if [ $elapsed -ge 4 ]; then
            echo -e "${RED}[VULNERABLE - TIME-BASED] ${endpoint}${NC}" | tee -a "${REPORT_FILE}"
            echo "  Method: ${method}" | tee -a "${REPORT_FILE}"
            echo "  Payload: ${payload}" | tee -a "${REPORT_FILE}"
            echo "  Evidence: Response took ${elapsed}s (expected ~5s delay)" | tee -a "${REPORT_FILE}"
            echo "" | tee -a "${REPORT_FILE}"
            VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
            return 0
        fi
    fi

    return 1
}

# Run tests
echo -e "${YELLOW}Running SQL injection tests...${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

for endpoint in "${ENDPOINTS[@]}"; do
    echo "Testing endpoint: ${endpoint}" | tee -a "${REPORT_FILE}"

    # Test a subset of payloads for each endpoint (to avoid excessive testing)
    for payload in "${SQL_PAYLOADS[@]:0:10}"; do
        test_sql_injection "$endpoint" "$payload" "GET" || true
        test_sql_injection "$endpoint" "$payload" "POST" || true
    done

    echo "" | tee -a "${REPORT_FILE}"
done

# Test with sqlmap if available
echo -e "${YELLOW}Running sqlmap automated tests...${NC}" | tee -a "${REPORT_FILE}"

if command -v sqlmap &> /dev/null; then
    for endpoint in "${ENDPOINTS[@]:0:2}"; do  # Test first 2 endpoints
        echo "Testing ${endpoint} with sqlmap..." | tee -a "${REPORT_FILE}"

        sqlmap_output=$(sqlmap -u "${API_BASE_URL}${endpoint}?id=1" \
            --batch \
            --level=1 \
            --risk=1 \
            --threads=5 \
            --timeout=10 \
            2>&1 || true)

        if echo "$sqlmap_output" | grep -qi "vulnerable"; then
            echo -e "${RED}[SQLMAP DETECTED] ${endpoint} is vulnerable${NC}" | tee -a "${REPORT_FILE}"
            echo "$sqlmap_output" | grep -A 5 "vulnerable" | tee -a "${REPORT_FILE}"
            VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
        fi
    done
else
    echo -e "${YELLOW}sqlmap not installed. Install with:${NC}" | tee -a "${REPORT_FILE}"
    echo "  pip install sqlmap" | tee -a "${REPORT_FILE}"
    echo "  or: apt-get install sqlmap" | tee -a "${REPORT_FILE}"
fi

echo "" | tee -a "${REPORT_FILE}"

# Summary
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "SQL Injection Test Summary" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Total Tests: ${TOTAL_TESTS}" | tee -a "${REPORT_FILE}"
echo -e "Vulnerabilities Found: ${RED}${VULNERABILITIES_FOUND}${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

if [ $VULNERABILITIES_FOUND -gt 0 ]; then
    echo -e "${RED}CRITICAL: SQL injection vulnerabilities detected!${NC}" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
    echo "Remediation:" | tee -a "${REPORT_FILE}"
    echo "1. Use parameterized queries/prepared statements" | tee -a "${REPORT_FILE}"
    echo "2. Validate and sanitize all user inputs" | tee -a "${REPORT_FILE}"
    echo "3. Use an ORM with built-in protection" | tee -a "${REPORT_FILE}"
    echo "4. Implement proper error handling (don't expose SQL errors)" | tee -a "${REPORT_FILE}"
    echo "5. Apply principle of least privilege to database users" | tee -a "${REPORT_FILE}"
else
    echo -e "${GREEN}PASS: No SQL injection vulnerabilities detected${NC}" | tee -a "${REPORT_FILE}"
fi

echo "" | tee -a "${REPORT_FILE}"
echo "Report saved to: ${REPORT_FILE}" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"

# Exit with error if vulnerabilities found
[ $VULNERABILITIES_FOUND -eq 0 ] && exit 0 || exit 1
