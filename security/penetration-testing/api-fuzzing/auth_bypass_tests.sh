#!/bin/bash
# Authentication Bypass Penetration Tests
# Tests for authentication and authorization vulnerabilities

set -euo pipefail

# Configuration
API_BASE_URL="${API_BASE_URL:-http://localhost:8000}"
REPORT_FILE="/tmp/auth_bypass_report.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================" | tee "${REPORT_FILE}"
echo "Authentication Bypass Penetration Test" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Target: ${API_BASE_URL}" | tee -a "${REPORT_FILE}"
echo "Date: $(date)" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

VULNERABILITIES_FOUND=0
TOTAL_TESTS=0

# Protected endpoints that should require authentication
declare -a PROTECTED_ENDPOINTS=(
    "/api/v1/admin"
    "/api/v1/admin/users"
    "/api/v1/grades"
    "/api/v1/student/private"
    "/api/v1/profile"
    "/api/v1/settings"
)

# Test 1: Access without authentication
echo -e "${YELLOW}[Test 1] Testing access without authentication...${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

for endpoint in "${PROTECTED_ENDPOINTS[@]}"; do
    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    response=$(curl -s -w "\n%{http_code}" "${API_BASE_URL}${endpoint}" 2>&1 || true)
    status_code=$(echo "$response" | tail -1)

    if [ "$status_code" == "200" ]; then
        echo -e "${RED}[VULNERABLE] ${endpoint}${NC}" | tee -a "${REPORT_FILE}"
        echo "  Issue: Endpoint accessible without authentication" | tee -a "${REPORT_FILE}"
        echo "  Status Code: 200 OK" | tee -a "${REPORT_FILE}"
        echo "" | tee -a "${REPORT_FILE}"
        VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
    elif [ "$status_code" != "401" ] && [ "$status_code" != "403" ]; then
        echo -e "${YELLOW}[WARNING] ${endpoint}${NC}" | tee -a "${REPORT_FILE}"
        echo "  Issue: Unexpected status code (should be 401/403)" | tee -a "${REPORT_FILE}"
        echo "  Status Code: ${status_code}" | tee -a "${REPORT_FILE}"
        echo "" | tee -a "${REPORT_FILE}"
    fi
done

# Test 2: Invalid/Expired tokens
echo -e "${YELLOW}[Test 2] Testing with invalid/expired tokens...${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

declare -a INVALID_TOKENS=(
    "invalid_token"
    "Bearer invalid"
    "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.invalid"
    ""
    "null"
)

for endpoint in "${PROTECTED_ENDPOINTS[@]:0:2}"; do
    for token in "${INVALID_TOKENS[@]}"; do
        TOTAL_TESTS=$((TOTAL_TESTS + 1))

        response=$(curl -s -w "\n%{http_code}" \
            -H "Authorization: ${token}" \
            "${API_BASE_URL}${endpoint}" 2>&1 || true)
        status_code=$(echo "$response" | tail -1)

        if [ "$status_code" == "200" ]; then
            echo -e "${RED}[VULNERABLE] ${endpoint}${NC}" | tee -a "${REPORT_FILE}"
            echo "  Issue: Accepts invalid token: ${token}" | tee -a "${REPORT_FILE}"
            echo "  Status Code: 200 OK" | tee -a "${REPORT_FILE}"
            echo "" | tee -a "${REPORT_FILE}"
            VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
        fi
    done
done

# Test 3: Parameter manipulation
echo -e "${YELLOW}[Test 3] Testing parameter manipulation...${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

declare -a PARAM_ATTACKS=(
    "?user_id=1&admin=true"
    "?role=admin"
    "?is_admin=1"
    "?auth=bypass"
    "?debug=true"
)

for endpoint in "${PROTECTED_ENDPOINTS[@]:0:3}"; do
    for params in "${PARAM_ATTACKS[@]}"; do
        TOTAL_TESTS=$((TOTAL_TESTS + 1))

        response=$(curl -s -w "\n%{http_code}" \
            "${API_BASE_URL}${endpoint}${params}" 2>&1 || true)
        status_code=$(echo "$response" | tail -1)

        if [ "$status_code" == "200" ]; then
            echo -e "${RED}[VULNERABLE] ${endpoint}${NC}" | tee -a "${REPORT_FILE}"
            echo "  Issue: Parameter manipulation successful: ${params}" | tee -a "${REPORT_FILE}"
            echo "  Status Code: 200 OK" | tee -a "${REPORT_FILE}"
            echo "" | tee -a "${REPORT_FILE}"
            VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
        fi
    done
done

# Test 4: HTTP Method bypass
echo -e "${YELLOW}[Test 4] Testing HTTP method bypass...${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

declare -a HTTP_METHODS=(
    "GET"
    "POST"
    "PUT"
    "DELETE"
    "PATCH"
    "HEAD"
    "OPTIONS"
    "TRACE"
)

for endpoint in "${PROTECTED_ENDPOINTS[@]:0:2}"; do
    for method in "${HTTP_METHODS[@]}"; do
        TOTAL_TESTS=$((TOTAL_TESTS + 1))

        response=$(curl -s -w "\n%{http_code}" \
            -X "$method" \
            "${API_BASE_URL}${endpoint}" 2>&1 || true)
        status_code=$(echo "$response" | tail -1)

        if [ "$status_code" == "200" ] && [ "$method" != "OPTIONS" ]; then
            echo -e "${RED}[VULNERABLE] ${endpoint}${NC}" | tee -a "${REPORT_FILE}"
            echo "  Issue: ${method} method bypasses authentication" | tee -a "${REPORT_FILE}"
            echo "  Status Code: 200 OK" | tee -a "${REPORT_FILE}"
            echo "" | tee -a "${REPORT_FILE}"
            VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
        fi
    done
done

# Test 5: IDOR (Insecure Direct Object Reference)
echo -e "${YELLOW}[Test 5] Testing for IDOR vulnerabilities...${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

# Simulate having a valid token for user 1
USER1_TOKEN="valid_user1_token"

declare -a IDOR_ENDPOINTS=(
    "/api/v1/student/1/grades"
    "/api/v1/student/2/grades"
    "/api/v1/student/999/grades"
    "/api/v1/user/1/profile"
    "/api/v1/user/2/profile"
)

for endpoint in "${IDOR_ENDPOINTS[@]}"; do
    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    # Try to access other users' data with user1's token
    response=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: Bearer ${USER1_TOKEN}" \
        "${API_BASE_URL}${endpoint}" 2>&1 || true)
    status_code=$(echo "$response" | tail -1)

    if [ "$status_code" == "200" ]; then
        echo -e "${YELLOW}[POTENTIAL IDOR] ${endpoint}${NC}" | tee -a "${REPORT_FILE}"
        echo "  Issue: May allow access to other users' data" | tee -a "${REPORT_FILE}"
        echo "  Note: Requires manual verification with valid tokens" | tee -a "${REPORT_FILE}"
        echo "" | tee -a "${REPORT_FILE}"
    fi
done

# Test 6: Session fixation
echo -e "${YELLOW}[Test 6] Testing for session fixation...${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Try to set session ID
response=$(curl -s -w "\n%{http_code}" \
    -H "Cookie: session_id=attacker_controlled_session" \
    "${API_BASE_URL}/api/v1/login" \
    -d "username=test&password=test" 2>&1 || true)

set_cookie=$(echo "$response" | grep -i "Set-Cookie:" || true)

if echo "$set_cookie" | grep -q "attacker_controlled_session"; then
    echo -e "${RED}[VULNERABLE] Session Fixation${NC}" | tee -a "${REPORT_FILE}"
    echo "  Issue: Application accepts externally provided session IDs" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
    VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
fi

# Test 7: JWT vulnerabilities
echo -e "${YELLOW}[Test 7] Testing JWT vulnerabilities...${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

# Test with "alg: none" JWT
NONE_ALG_JWT="eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJhZG1pbiIsImlhdCI6MTUxNjIzOTAyMn0."

TOTAL_TESTS=$((TOTAL_TESTS + 1))

response=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: Bearer ${NONE_ALG_JWT}" \
    "${API_BASE_URL}/api/v1/admin" 2>&1 || true)
status_code=$(echo "$response" | tail -1)

if [ "$status_code" == "200" ]; then
    echo -e "${RED}[CRITICAL] JWT 'none' algorithm accepted${NC}" | tee -a "${REPORT_FILE}"
    echo "  Issue: Server accepts JWT with 'alg: none'" | tee -a "${REPORT_FILE}"
    echo "  Impact: Complete authentication bypass" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
    VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
fi

# Test 8: Rate limiting on login
echo -e "${YELLOW}[Test 8] Testing rate limiting on authentication...${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

TOTAL_TESTS=$((TOTAL_TESTS + 1))

successful_attempts=0
for i in {1..50}; do
    response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -d "username=test&password=wrong$i" \
        "${API_BASE_URL}/api/v1/login" 2>&1 || true)
    status_code=$(echo "$response" | tail -1)

    if [ "$status_code" != "429" ] && [ "$status_code" != "403" ]; then
        successful_attempts=$((successful_attempts + 1))
    fi
done

if [ $successful_attempts -gt 40 ]; then
    echo -e "${RED}[VULNERABLE] No rate limiting${NC}" | tee -a "${REPORT_FILE}"
    echo "  Issue: ${successful_attempts}/50 login attempts succeeded" | tee -a "${REPORT_FILE}"
    echo "  Impact: Vulnerable to brute force attacks" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
    VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
fi

# Summary
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Authentication Bypass Test Summary" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Total Tests: ${TOTAL_TESTS}" | tee -a "${REPORT_FILE}"
echo -e "Vulnerabilities Found: ${RED}${VULNERABILITIES_FOUND}${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

if [ $VULNERABILITIES_FOUND -gt 0 ]; then
    echo -e "${RED}CRITICAL: Authentication vulnerabilities detected!${NC}" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
    echo "Remediation:" | tee -a "${REPORT_FILE}"
    echo "1. Implement proper authentication on all protected endpoints" | tee -a "${REPORT_FILE}"
    echo "2. Validate and verify all authentication tokens" | tee -a "${REPORT_FILE}"
    echo "3. Implement proper authorization checks (not just authentication)" | tee -a "${REPORT_FILE}"
    echo "4. Use secure session management" | tee -a "${REPORT_FILE}"
    echo "5. Implement rate limiting on authentication endpoints" | tee -a "${REPORT_FILE}"
    echo "6. Properly validate JWT tokens and reject 'alg: none'" | tee -a "${REPORT_FILE}"
    echo "7. Implement IDOR protection with proper access controls" | tee -a "${REPORT_FILE}"
else
    echo -e "${GREEN}PASS: No authentication bypass vulnerabilities detected${NC}" | tee -a "${REPORT_FILE}"
fi

echo "" | tee -a "${REPORT_FILE}"
echo "Report saved to: ${REPORT_FILE}" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"

# Exit with error if vulnerabilities found
[ $VULNERABILITIES_FOUND -eq 0 ] && exit 0 || exit 1
