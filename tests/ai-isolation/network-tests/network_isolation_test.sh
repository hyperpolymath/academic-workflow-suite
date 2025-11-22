#!/bin/bash
# Network Isolation Test for AI Container
# Verifies that the AI grading container has no network access
#
# Exit codes:
#   0 - All tests passed (network properly isolated)
#   1 - Test failed (network access detected)
#   2 - Test setup error

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "AI Container Network Isolation Test"
echo "=========================================="
echo ""

# Configuration
CONTAINER_NAME="${1:-ai-grading-container}"
TEST_TIMEOUT=30
PASS_COUNT=0
FAIL_COUNT=0

# Test counter
test_number=1

# Helper function to run test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_failure="${3:-true}"  # Most tests expect failure (no network)

    echo -e "${YELLOW}Test $test_number: $test_name${NC}"

    if $expected_failure; then
        # We expect this command to fail (no network access)
        if eval "$test_command" &> /dev/null; then
            echo -e "${RED}✗ FAILED${NC} - Network access detected (expected failure)"
            FAIL_COUNT=$((FAIL_COUNT + 1))
            return 1
        else
            echo -e "${GREEN}✓ PASSED${NC} - Network properly blocked"
            PASS_COUNT=$((PASS_COUNT + 1))
            return 0
        fi
    else
        # We expect this command to succeed
        if eval "$test_command" &> /dev/null; then
            echo -e "${GREEN}✓ PASSED${NC}"
            PASS_COUNT=$((PASS_COUNT + 1))
            return 0
        else
            echo -e "${RED}✗ FAILED${NC}"
            FAIL_COUNT=$((FAIL_COUNT + 1))
            return 1
        fi
    fi

    test_number=$((test_number + 1))
    echo ""
}

# Check if container exists
if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}Error: Container '${CONTAINER_NAME}' not found${NC}"
    echo "Available containers:"
    docker ps -a --format '{{.Names}}'
    exit 2
fi

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}Warning: Container '${CONTAINER_NAME}' is not running${NC}"
    echo "Starting container..."
    docker start "${CONTAINER_NAME}" || exit 2
    sleep 2
fi

echo "Testing container: ${CONTAINER_NAME}"
echo ""

# Test 1: Ping external host
run_test "Ping external host (google.com)" \
    "timeout 5 docker exec ${CONTAINER_NAME} ping -c 1 google.com"

# Test 2: DNS resolution
run_test "DNS resolution" \
    "timeout 5 docker exec ${CONTAINER_NAME} nslookup google.com"

# Test 3: HTTP request
run_test "HTTP GET request" \
    "timeout 5 docker exec ${CONTAINER_NAME} curl -s http://example.com"

# Test 4: HTTPS request
run_test "HTTPS GET request" \
    "timeout 5 docker exec ${CONTAINER_NAME} curl -s https://example.com"

# Test 5: TCP connection to external port
run_test "TCP connection to external port 80" \
    "timeout 5 docker exec ${CONTAINER_NAME} nc -zv -w 2 example.com 80"

# Test 6: TCP connection to external port 443
run_test "TCP connection to external port 443" \
    "timeout 5 docker exec ${CONTAINER_NAME} nc -zv -w 2 example.com 443"

# Test 7: UDP packet
run_test "UDP packet send" \
    "timeout 5 docker exec ${CONTAINER_NAME} sh -c 'echo test | nc -u -w 2 8.8.8.8 53'"

# Test 8: Check for network interfaces (should only have loopback)
run_test "Verify only loopback interface exists" \
    "docker exec ${CONTAINER_NAME} sh -c 'ip link show | grep -v \"lo:\" | grep -q \"state UP\"'" \
    "true"

# Test 9: Attempt to download file
run_test "Attempt file download" \
    "timeout 5 docker exec ${CONTAINER_NAME} wget -q -O /dev/null http://example.com"

# Test 10: Check iptables rules (if available)
run_test "Verify no default route" \
    "docker exec ${CONTAINER_NAME} sh -c 'ip route | grep -q default'" \
    "true"

# Test 11: Attempt connection to common API endpoints
run_test "Block OpenAI API" \
    "timeout 5 docker exec ${CONTAINER_NAME} curl -s https://api.openai.com"

run_test "Block Anthropic API" \
    "timeout 5 docker exec ${CONTAINER_NAME} curl -s https://api.anthropic.com"

# Test 12: Check for network namespaces isolation
echo -e "${YELLOW}Test $test_number: Network namespace isolation${NC}"
HOST_NS=$(readlink /proc/1/ns/net)
CONTAINER_NS=$(docker exec ${CONTAINER_NAME} readlink /proc/1/ns/net 2>/dev/null || echo "unknown")

if [ "$HOST_NS" != "$CONTAINER_NS" ] && [ "$CONTAINER_NS" != "unknown" ]; then
    echo -e "${GREEN}✓ PASSED${NC} - Container has separate network namespace"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "${RED}✗ FAILED${NC} - Network namespace not properly isolated"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
test_number=$((test_number + 1))
echo ""

# Test 13: Verify network mode is 'none'
echo -e "${YELLOW}Test $test_number: Docker network mode${NC}"
NETWORK_MODE=$(docker inspect ${CONTAINER_NAME} --format='{{.HostConfig.NetworkMode}}')
if [ "$NETWORK_MODE" = "none" ]; then
    echo -e "${GREEN}✓ PASSED${NC} - Network mode is 'none'"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "${RED}✗ FAILED${NC} - Network mode is '${NETWORK_MODE}' (expected 'none')"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
test_number=$((test_number + 1))
echo ""

# Test 14: Check for suspicious processes that might enable networking
echo -e "${YELLOW}Test $test_number: No network proxy processes${NC}"
SUSPICIOUS_PROCS=$(docker exec ${CONTAINER_NAME} sh -c 'ps aux | grep -E "(proxy|vpn|tunnel)" | grep -v grep' || echo "")
if [ -z "$SUSPICIOUS_PROCS" ]; then
    echo -e "${GREEN}✓ PASSED${NC} - No suspicious networking processes found"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "${RED}✗ FAILED${NC} - Found suspicious processes:"
    echo "$SUSPICIOUS_PROCS"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
test_number=$((test_number + 1))
echo ""

# Test 15: Verify localhost/127.0.0.1 is accessible (should work)
run_test "Localhost is accessible" \
    "docker exec ${CONTAINER_NAME} ping -c 1 127.0.0.1" \
    "false"

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "Total tests: $((test_number - 1))"
echo -e "${GREEN}Passed: ${PASS_COUNT}${NC}"
echo -e "${RED}Failed: ${FAIL_COUNT}${NC}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
    echo "Network isolation is properly configured."
    exit 0
else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    echo "Network isolation may be compromised."
    exit 1
fi
