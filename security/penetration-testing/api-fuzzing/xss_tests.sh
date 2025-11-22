#!/bin/bash
# Cross-Site Scripting (XSS) Penetration Tests
# Tests for reflected, stored, and DOM-based XSS vulnerabilities

set -euo pipefail

# Configuration
API_BASE_URL="${API_BASE_URL:-http://localhost:8000}"
REPORT_FILE="/tmp/xss_test_report.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# XSS payloads
declare -a XSS_PAYLOADS=(
    # Basic XSS
    "<script>alert('XSS')</script>"
    "<img src=x onerror=alert('XSS')>"
    "<svg/onload=alert('XSS')>"
    "<iframe src=javascript:alert('XSS')>"
    "<body onload=alert('XSS')>"

    # Event handlers
    "<input onfocus=alert('XSS') autofocus>"
    "<select onfocus=alert('XSS') autofocus>"
    "<textarea onfocus=alert('XSS') autofocus>"
    "<marquee onstart=alert('XSS')>"
    "<div onmouseover=alert('XSS')>"

    # Filter bypass attempts
    "<scr<script>ipt>alert('XSS')</scr</script>ipt>"
    "<ScRiPt>alert('XSS')</ScRiPt>"
    "<script>alert(String.fromCharCode(88,83,83))</script>"
    "\"><script>alert('XSS')</script>"
    "'><script>alert('XSS')</script>"

    # Encoded payloads
    "%3Cscript%3Ealert('XSS')%3C/script%3E"
    "&lt;script&gt;alert('XSS')&lt;/script&gt;"
    "&#60;script&#62;alert('XSS')&#60;/script&#62;"

    # DOM-based XSS
    "javascript:alert('XSS')"
    "data:text/html,<script>alert('XSS')</script>"
    "vbscript:msgbox('XSS')"

    # Advanced XSS
    "<img src='x' onerror='eval(atob(\"YWxlcnQoJ1hTUycp\"))'>"
    "<svg><animate onbegin=alert('XSS') attributeName=x dur=1s>"
    "<math><mi xlink:href=\"data:x,<script>alert('XSS')</script>\">"

    # Polyglot payloads
    "jaVasCript:/*-/*\`/*\\\`/*'/*\"/**/(/* */oNcliCk=alert('XSS') )//%0D%0A%0d%0a//</stYle/</titLe/</teXtarEa/</scRipt/--!>\\x3csVg/<sVg/oNloAd=alert('XSS')//>"
)

# Test endpoints
declare -a ENDPOINTS=(
    "/api/v1/feedback"
    "/api/v1/comment"
    "/api/v1/search"
    "/api/v1/profile"
    "/api/v1/submit"
)

echo "=========================================" | tee "${REPORT_FILE}"
echo "Cross-Site Scripting (XSS) Penetration Test" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Target: ${API_BASE_URL}" | tee -a "${REPORT_FILE}"
echo "Date: $(date)" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

VULNERABILITIES_FOUND=0
TOTAL_TESTS=0

# Function to test for reflected XSS
test_reflected_xss() {
    local endpoint=$1
    local payload=$2

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    # URL encode the payload
    encoded_payload=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$payload'''))" 2>/dev/null || echo "$payload")

    # Test GET request
    response=$(curl -s "${API_BASE_URL}${endpoint}?input=${encoded_payload}&search=${encoded_payload}" 2>&1 || true)

    # Check if payload is reflected unescaped
    if echo "$response" | grep -F "$payload" > /dev/null; then
        # Further check if it's actually executable (not escaped)
        if ! echo "$response" | grep -F "&lt;script&gt;" > /dev/null && \
           ! echo "$response" | grep -F "\\u003cscript\\u003e" > /dev/null; then

            echo -e "${RED}[REFLECTED XSS] ${endpoint}${NC}" | tee -a "${REPORT_FILE}"
            echo "  Payload: ${payload}" | tee -a "${REPORT_FILE}"
            echo "  Evidence: Payload reflected without proper encoding" | tee -a "${REPORT_FILE}"

            # Show snippet of reflection
            context=$(echo "$response" | grep -o ".{0,50}${payload:0:20}.{0,50}" | head -1)
            echo "  Context: ${context}" | tee -a "${REPORT_FILE}"
            echo "" | tee -a "${REPORT_FILE}"

            VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
            return 0
        fi
    fi

    return 1
}

# Function to test for stored XSS
test_stored_xss() {
    local endpoint=$1
    local payload=$2

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    # Generate unique marker
    marker="XSS_TEST_$(date +%s)_$$"
    marked_payload="${payload}<!--${marker}-->"

    # POST the payload
    post_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"content\": \"${marked_payload}\", \"comment\": \"${marked_payload}\"}" \
        "${API_BASE_URL}${endpoint}" 2>&1 || true)

    # Try to retrieve the stored data
    get_response=$(curl -s "${API_BASE_URL}${endpoint}" 2>&1 || true)

    # Check if our marker exists and payload is unescaped
    if echo "$get_response" | grep -F "$marker" > /dev/null; then
        if echo "$get_response" | grep -F "$payload" > /dev/null; then
            if ! echo "$get_response" | grep -F "&lt;script&gt;" > /dev/null; then

                echo -e "${RED}[STORED XSS] ${endpoint}${NC}" | tee -a "${REPORT_FILE}"
                echo "  Payload: ${payload}" | tee -a "${REPORT_FILE}"
                echo "  Evidence: Payload stored and rendered without encoding" | tee -a "${REPORT_FILE}"
                echo "  Marker: ${marker}" | tee -a "${REPORT_FILE}"
                echo "" | tee -a "${REPORT_FILE}"

                VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
                return 0
            fi
        fi
    fi

    return 1
}

# Function to test for DOM-based XSS
test_dom_xss() {
    local endpoint=$1
    local payload=$2

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    # Test with hash fragment (DOM-based)
    response=$(curl -s "${API_BASE_URL}${endpoint}#${payload}" 2>&1 || true)

    # Check for dangerous JavaScript patterns
    if echo "$response" | grep -E "(document\.write|innerHTML|eval|location)" > /dev/null; then
        if echo "$response" | grep -E "(location\.hash|window\.location)" > /dev/null; then

            echo -e "${YELLOW}[POTENTIAL DOM XSS] ${endpoint}${NC}" | tee -a "${REPORT_FILE}"
            echo "  Payload: ${payload}" | tee -a "${REPORT_FILE}"
            echo "  Evidence: Uses DOM manipulation with user-controlled data" | tee -a "${REPORT_FILE}"
            echo "  Note: Requires manual verification" | tee -a "${REPORT_FILE}"
            echo "" | tee -a "${REPORT_FILE}"

            VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
            return 0
        fi
    fi

    return 1
}

# Run tests
echo -e "${YELLOW}Testing for Reflected XSS...${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

for endpoint in "${ENDPOINTS[@]}"; do
    for payload in "${XSS_PAYLOADS[@]:0:5}"; do
        test_reflected_xss "$endpoint" "$payload" || true
    done
done

echo "" | tee -a "${REPORT_FILE}"
echo -e "${YELLOW}Testing for Stored XSS...${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

for endpoint in "${ENDPOINTS[@]}"; do
    for payload in "${XSS_PAYLOADS[@]:0:3}"; do
        test_stored_xss "$endpoint" "$payload" || true
    done
done

echo "" | tee -a "${REPORT_FILE}"
echo -e "${YELLOW}Testing for DOM-based XSS...${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

for endpoint in "${ENDPOINTS[@]}"; do
    for payload in "${XSS_PAYLOADS[@]:0:3}"; do
        test_dom_xss "$endpoint" "$payload" || true
    done
done

# Test with XSStrike if available
echo "" | tee -a "${REPORT_FILE}"
echo -e "${YELLOW}Running XSStrike automated tests...${NC}" | tee -a "${REPORT_FILE}"

if command -v xsstrike &> /dev/null || [ -f "/opt/XSStrike/xsstrike.py" ]; then
    for endpoint in "${ENDPOINTS[@]:0:2}"; do
        echo "Testing ${endpoint} with XSStrike..." | tee -a "${REPORT_FILE}"

        xsstrike_output=$(python3 /opt/XSStrike/xsstrike.py \
            -u "${API_BASE_URL}${endpoint}?q=test" \
            --skip-dom \
            2>&1 || true)

        if echo "$xsstrike_output" | grep -qi "vulnerable"; then
            echo -e "${RED}[XSSTRIKE DETECTED] ${endpoint} is vulnerable${NC}" | tee -a "${REPORT_FILE}"
            echo "$xsstrike_output" | grep -A 5 -i "vulnerable" | tee -a "${REPORT_FILE}"
            VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
        fi
    done
else
    echo -e "${YELLOW}XSStrike not installed. Install with:${NC}" | tee -a "${REPORT_FILE}"
    echo "  git clone https://github.com/s0md3v/XSStrike /opt/XSStrike" | tee -a "${REPORT_FILE}"
fi

echo "" | tee -a "${REPORT_FILE}"

# Summary
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "XSS Test Summary" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Total Tests: ${TOTAL_TESTS}" | tee -a "${REPORT_FILE}"
echo -e "Vulnerabilities Found: ${RED}${VULNERABILITIES_FOUND}${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

if [ $VULNERABILITIES_FOUND -gt 0 ]; then
    echo -e "${RED}CRITICAL: XSS vulnerabilities detected!${NC}" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
    echo "Remediation:" | tee -a "${REPORT_FILE}"
    echo "1. Encode all user-supplied output (HTML entity encoding)" | tee -a "${REPORT_FILE}"
    echo "2. Use Content Security Policy (CSP) headers" | tee -a "${REPORT_FILE}"
    echo "3. Validate and sanitize all inputs" | tee -a "${REPORT_FILE}"
    echo "4. Use auto-escaping template engines" | tee -a "${REPORT_FILE}"
    echo "5. Set HTTPOnly and Secure flags on cookies" | tee -a "${REPORT_FILE}"
    echo "6. Implement proper output encoding based on context" | tee -a "${REPORT_FILE}"
else
    echo -e "${GREEN}PASS: No XSS vulnerabilities detected${NC}" | tee -a "${REPORT_FILE}"
fi

echo "" | tee -a "${REPORT_FILE}"
echo "Report saved to: ${REPORT_FILE}" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"

# Exit with error if vulnerabilities found
[ $VULNERABILITIES_FOUND -eq 0 ] && exit 0 || exit 1
