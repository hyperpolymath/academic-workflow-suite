#!/bin/bash
# Network Isolation Verification Tests
# Verifies container network is properly disabled/isolated

set -euo pipefail

REPORT_FILE="/tmp/network_isolation_report.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================" | tee "${REPORT_FILE}"
echo "Network Isolation Verification Test" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Date: $(date)" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

VIOLATIONS_FOUND=0
TOTAL_TESTS=0

# Test 1: Check network interfaces
echo -e "${YELLOW}[Test 1] Checking network interfaces...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if command -v ip &> /dev/null; then
    interfaces=$(ip link show | grep -v "lo:" || true)

    if [ -n "$interfaces" ]; then
        echo -e "${RED}[VIOLATION] Network interfaces found (expected only lo):${NC}" | tee -a "${REPORT_FILE}"
        ip link show | tee -a "${REPORT_FILE}"
        VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
    else
        echo -e "${GREEN}✓ Only loopback interface present${NC}" | tee -a "${REPORT_FILE}"
    fi
elif command -v ifconfig &> /dev/null; then
    interfaces=$(ifconfig | grep -v "lo" | grep "inet" || true)

    if [ -n "$interfaces" ]; then
        echo -e "${RED}[VIOLATION] Network interfaces found${NC}" | tee -a "${REPORT_FILE}"
        ifconfig | tee -a "${REPORT_FILE}"
        VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
    else
        echo -e "${GREEN}✓ Only loopback interface present${NC}" | tee -a "${REPORT_FILE}"
    fi
else
    echo -e "${YELLOW}⊘ Network tools not available${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 2: Attempt external network connectivity
echo -e "${YELLOW}[Test 2] Testing external connectivity...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

TEST_HOSTS=(
    "8.8.8.8"
    "1.1.1.1"
    "google.com"
    "github.com"
)

can_connect=false
for host in "${TEST_HOSTS[@]}"; do
    if ping -c 1 -W 2 "$host" &> /dev/null; then
        echo -e "${RED}[VIOLATION] Can ping ${host}${NC}" | tee -a "${REPORT_FILE}"
        can_connect=true
        VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
        break
    fi
done

if [ "$can_connect" = false ]; then
    echo -e "${GREEN}✓ No external connectivity${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 3: Test DNS resolution
echo -e "${YELLOW}[Test 3] Testing DNS resolution...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if command -v nslookup &> /dev/null; then
    if nslookup google.com &> /dev/null; then
        echo -e "${RED}[VIOLATION] DNS resolution works${NC}" | tee -a "${REPORT_FILE}"
        VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
    else
        echo -e "${GREEN}✓ DNS resolution disabled${NC}" | tee -a "${REPORT_FILE}"
    fi
elif command -v dig &> /dev/null; then
    if dig google.com &> /dev/null; then
        echo -e "${RED}[VIOLATION] DNS resolution works${NC}" | tee -a "${REPORT_FILE}"
        VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
    else
        echo -e "${GREEN}✓ DNS resolution disabled${NC}" | tee -a "${REPORT_FILE}"
    fi
else
    echo -e "${GREEN}✓ DNS tools not available${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 4: Test HTTP/HTTPS connectivity
echo -e "${YELLOW}[Test 4] Testing HTTP/HTTPS connectivity...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if command -v curl &> /dev/null; then
    if curl -s --max-time 5 https://www.google.com &> /dev/null; then
        echo -e "${RED}[VIOLATION] HTTPS connectivity works${NC}" | tee -a "${REPORT_FILE}"
        VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
    else
        echo -e "${GREEN}✓ HTTPS connectivity blocked${NC}" | tee -a "${REPORT_FILE}"
    fi
elif command -v wget &> /dev/null; then
    if wget --timeout=5 -q -O /dev/null https://www.google.com &> /dev/null; then
        echo -e "${RED}[VIOLATION] HTTPS connectivity works${NC}" | tee -a "${REPORT_FILE}"
        VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
    else
        echo -e "${GREEN}✓ HTTPS connectivity blocked${NC}" | tee -a "${REPORT_FILE}"
    fi
else
    echo -e "${GREEN}✓ HTTP tools not available${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 5: Check for open ports
echo -e "${YELLOW}[Test 5] Checking for listening ports...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if command -v netstat &> /dev/null; then
    listening=$(netstat -tuln 2>/dev/null | grep LISTEN | grep -v "127.0.0.1" || true)

    if [ -n "$listening" ]; then
        echo -e "${YELLOW}[WARNING] Found listening ports:${NC}" | tee -a "${REPORT_FILE}"
        echo "$listening" | tee -a "${REPORT_FILE}"
    else
        echo -e "${GREEN}✓ No external listening ports${NC}" | tee -a "${REPORT_FILE}"
    fi
elif command -v ss &> /dev/null; then
    listening=$(ss -tuln 2>/dev/null | grep LISTEN | grep -v "127.0.0.1" || true)

    if [ -n "$listening" ]; then
        echo -e "${YELLOW}[WARNING] Found listening ports:${NC}" | tee -a "${REPORT_FILE}"
        echo "$listening" | tee -a "${REPORT_FILE}"
    else
        echo -e "${GREEN}✓ No external listening ports${NC}" | tee -a "${REPORT_FILE}"
    fi
else
    echo -e "${YELLOW}⊘ Network stat tools not available${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 6: Check iptables rules
echo -e "${YELLOW}[Test 6] Checking iptables rules...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if command -v iptables &> /dev/null; then
    if iptables -L -n &> /dev/null; then
        rules=$(iptables -L -n 2>&1)
        echo "IPTables rules:" | tee -a "${REPORT_FILE}"
        echo "$rules" | tee -a "${REPORT_FILE}"

        # Check if all OUTPUT is dropped
        if echo "$rules" | grep -q "OUTPUT.*DROP"; then
            echo -e "${GREEN}✓ OUTPUT traffic is dropped${NC}" | tee -a "${REPORT_FILE}"
        else
            echo -e "${YELLOW}[WARNING] OUTPUT traffic not explicitly dropped${NC}" | tee -a "${REPORT_FILE}"
        fi
    else
        echo -e "${GREEN}✓ Cannot access iptables (good for containers)${NC}" | tee -a "${REPORT_FILE}"
    fi
else
    echo -e "${GREEN}✓ iptables not available${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 7: Check /etc/resolv.conf
echo -e "${YELLOW}[Test 7] Checking DNS configuration...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ -f /etc/resolv.conf ]; then
    nameservers=$(grep -v "^#" /etc/resolv.conf | grep nameserver || true)

    if [ -n "$nameservers" ]; then
        echo -e "${YELLOW}[WARNING] DNS nameservers configured:${NC}" | tee -a "${REPORT_FILE}"
        echo "$nameservers" | tee -a "${REPORT_FILE}"
    else
        echo -e "${GREEN}✓ No DNS nameservers configured${NC}" | tee -a "${REPORT_FILE}"
    fi
else
    echo -e "${GREEN}✓ /etc/resolv.conf not present${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 8: Check routing table
echo -e "${YELLOW}[Test 8] Checking routing table...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if command -v ip &> /dev/null; then
    routes=$(ip route 2>/dev/null || true)

    if [ -z "$routes" ] || (echo "$routes" | grep -q "^$"); then
        echo -e "${GREEN}✓ No routes configured${NC}" | tee -a "${REPORT_FILE}"
    else
        # Check for default route
        if echo "$routes" | grep -q "default"; then
            echo -e "${RED}[VIOLATION] Default route exists:${NC}" | tee -a "${REPORT_FILE}"
            echo "$routes" | tee -a "${REPORT_FILE}"
            VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
        else
            echo "Routes found (but no default):" | tee -a "${REPORT_FILE}"
            echo "$routes" | tee -a "${REPORT_FILE}"
        fi
    fi
elif command -v route &> /dev/null; then
    routes=$(route -n 2>/dev/null || true)

    if echo "$routes" | grep -qE "^0\.0\.0\.0"; then
        echo -e "${RED}[VIOLATION] Default route exists${NC}" | tee -a "${REPORT_FILE}"
        VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
    fi
else
    echo -e "${YELLOW}⊘ Route tools not available${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 9: Test localhost connectivity (should work)
echo -e "${YELLOW}[Test 9] Testing localhost connectivity...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if ping -c 1 127.0.0.1 &> /dev/null; then
    echo -e "${GREEN}✓ Localhost connectivity works (expected)${NC}" | tee -a "${REPORT_FILE}"
else
    echo -e "${YELLOW}[WARNING] Localhost connectivity broken${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 10: Check for network namespaces
echo -e "${YELLOW}[Test 10] Checking network namespace isolation...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ -f /proc/self/ns/net ]; then
    net_ns=$(readlink /proc/self/ns/net)
    init_ns=$(readlink /proc/1/ns/net 2>/dev/null || echo "")

    if [ "$net_ns" == "$init_ns" ]; then
        echo -e "${RED}[VIOLATION] Sharing network namespace with init${NC}" | tee -a "${REPORT_FILE}"
        VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
    else
        echo -e "${GREEN}✓ Separate network namespace${NC}" | tee -a "${REPORT_FILE}"
    fi
else
    echo -e "${YELLOW}⊘ Cannot check network namespace${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Summary
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Network Isolation Test Summary" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Total Tests: ${TOTAL_TESTS}" | tee -a "${REPORT_FILE}"
echo -e "Violations Found: ${RED}${VIOLATIONS_FOUND}${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

if [ $VIOLATIONS_FOUND -gt 0 ]; then
    echo -e "${RED}FAIL: Network isolation violations detected!${NC}" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
    echo "Remediation:" | tee -a "${REPORT_FILE}"
    echo "1. Run container with --network=none" | tee -a "${REPORT_FILE}"
    echo "2. Remove network capabilities" | tee -a "${REPORT_FILE}"
    echo "3. Use network namespaces" | tee -a "${REPORT_FILE}"
    echo "4. Configure iptables to drop all OUTPUT" | tee -a "${REPORT_FILE}"
    echo "5. Remove DNS configuration" | tee -a "${REPORT_FILE}"
else
    echo -e "${GREEN}PASS: Network properly isolated${NC}" | tee -a "${REPORT_FILE}"
fi

echo "" | tee -a "${REPORT_FILE}"
echo "Report saved to: ${REPORT_FILE}" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"

# Exit with error if violations found
[ $VIOLATIONS_FOUND -eq 0 ] && exit 0 || exit 1
