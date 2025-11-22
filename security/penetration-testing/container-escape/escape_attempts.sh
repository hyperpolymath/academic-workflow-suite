#!/bin/bash
# Container Escape Penetration Tests
# Tests for container breakout vulnerabilities

set -euo pipefail

REPORT_FILE="/tmp/container_escape_report.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================" | tee "${REPORT_FILE}"
echo "Container Escape Penetration Test" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Date: $(date)" | tee -a "${REPORT_FILE}"
echo "Host: $(hostname)" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

VULNERABILITIES_FOUND=0
TOTAL_TESTS=0

# Test 1: Check if running in container
echo -e "${YELLOW}[Test 1] Detecting container environment...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ -f "/.dockerenv" ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    echo -e "${GREEN}✓ Running inside container${NC}" | tee -a "${REPORT_FILE}"
else
    echo -e "${YELLOW}⚠ Not running in a container${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 2: Check for privileged mode
echo -e "${YELLOW}[Test 2] Checking for privileged container...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ -e /proc/1/attr/current ]; then
    selinux_context=$(cat /proc/1/attr/current 2>/dev/null || echo "")
    if [[ "$selinux_context" == *"unconfined"* ]]; then
        echo -e "${RED}[VULNERABLE] Container running in privileged mode${NC}" | tee -a "${REPORT_FILE}"
        echo "  SELinux context: ${selinux_context}" | tee -a "${REPORT_FILE}"
        VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
    else
        echo -e "${GREEN}✓ Not running privileged${NC}" | tee -a "${REPORT_FILE}"
    fi
fi

# Check capabilities
if command -v capsh &> /dev/null; then
    capabilities=$(capsh --print 2>/dev/null || echo "")
    if echo "$capabilities" | grep -q "cap_sys_admin"; then
        echo -e "${RED}[VULNERABLE] Has CAP_SYS_ADMIN capability${NC}" | tee -a "${REPORT_FILE}"
        echo "  This capability can be exploited for container escape" | tee -a "${REPORT_FILE}"
        VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
    fi
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 3: Check for Docker socket exposure
echo -e "${YELLOW}[Test 3] Checking for exposed Docker socket...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ -S /var/run/docker.sock ]; then
    echo -e "${RED}[CRITICAL] Docker socket is accessible!${NC}" | tee -a "${REPORT_FILE}"
    echo "  Path: /var/run/docker.sock" | tee -a "${REPORT_FILE}"
    echo "  Impact: Direct host access possible" | tee -a "${REPORT_FILE}"

    # Try to access it
    if command -v docker &> /dev/null; then
        if docker ps &> /dev/null; then
            echo -e "${RED}[CRITICAL] Can execute Docker commands!${NC}" | tee -a "${REPORT_FILE}"
            docker ps | head -5 | tee -a "${REPORT_FILE}"
        fi
    fi

    VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
else
    echo -e "${GREEN}✓ Docker socket not accessible${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 4: Check for /proc/sys/kernel mounts
echo -e "${YELLOW}[Test 4] Checking for sensitive /proc mounts...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ -w /proc/sys/kernel ]; then
    echo -e "${RED}[VULNERABLE] /proc/sys/kernel is writable${NC}" | tee -a "${REPORT_FILE}"
    echo "  Impact: Can modify kernel parameters" | tee -a "${REPORT_FILE}"
    VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
else
    echo -e "${GREEN}✓ /proc/sys/kernel is read-only${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 5: Check for host path mounts
echo -e "${YELLOW}[Test 5] Checking for dangerous host mounts...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

dangerous_mounts=0
while IFS= read -r mount; do
    # Check for mounts that could allow escape
    if echo "$mount" | grep -qE "^(/|/etc|/var|/usr|/bin|/sbin|/lib|/root|/home) "; then
        echo -e "${RED}[VULNERABLE] Dangerous mount detected:${NC}" | tee -a "${REPORT_FILE}"
        echo "  $mount" | tee -a "${REPORT_FILE}"
        dangerous_mounts=$((dangerous_mounts + 1))
    fi
done < /proc/mounts

if [ $dangerous_mounts -gt 0 ]; then
    VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
else
    echo -e "${GREEN}✓ No dangerous mounts detected${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 6: Check for writable cgroup
echo -e "${YELLOW}[Test 6] Checking for writable cgroup...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ -w /sys/fs/cgroup/devices/devices.allow ] 2>/dev/null; then
    echo -e "${RED}[CRITICAL] Can modify cgroup device permissions!${NC}" | tee -a "${REPORT_FILE}"
    echo "  Impact: Can grant access to host devices" | tee -a "${REPORT_FILE}"
    VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
else
    echo -e "${GREEN}✓ cgroup is read-only${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 7: Check for accessible host devices
echo -e "${YELLOW}[Test 7] Checking for host device access...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

dangerous_devices=0
for device in /dev/sd* /dev/nvme* /dev/vd*; do
    if [ -e "$device" ] && [ -r "$device" ]; then
        echo -e "${RED}[VULNERABLE] Host block device accessible: ${device}${NC}" | tee -a "${REPORT_FILE}"
        dangerous_devices=$((dangerous_devices + 1))
    fi
done

if [ $dangerous_devices -gt 0 ]; then
    echo "  Impact: Can read/write host disk" | tee -a "${REPORT_FILE}"
    VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
else
    echo -e "${GREEN}✓ No host block devices accessible${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 8: Check for kernel module loading
echo -e "${YELLOW}[Test 8] Checking kernel module loading capability...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ -w /proc/sys/kernel/modules_disabled ] 2>/dev/null || \
   [ -w /sys/module ] 2>/dev/null; then
    echo -e "${RED}[CRITICAL] May be able to load kernel modules!${NC}" | tee -a "${REPORT_FILE}"
    echo "  Impact: Complete system compromise possible" | tee -a "${REPORT_FILE}"
    VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
else
    echo -e "${GREEN}✓ Cannot load kernel modules${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 9: Check for AppArmor/SELinux
echo -e "${YELLOW}[Test 9] Checking MAC (Mandatory Access Control)...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

has_mac=false

# Check AppArmor
if [ -f /proc/self/attr/current ]; then
    apparmor_profile=$(cat /proc/self/attr/current 2>/dev/null || echo "")
    if [[ "$apparmor_profile" != "unconfined" ]] && [ -n "$apparmor_profile" ]; then
        echo -e "${GREEN}✓ AppArmor enabled: ${apparmor_profile}${NC}" | tee -a "${REPORT_FILE}"
        has_mac=true
    fi
fi

# Check SELinux
if command -v getenforce &> /dev/null; then
    selinux_status=$(getenforce 2>/dev/null || echo "")
    if [[ "$selinux_status" == "Enforcing" ]]; then
        echo -e "${GREEN}✓ SELinux enforcing${NC}" | tee -a "${REPORT_FILE}"
        has_mac=true
    fi
fi

if [ "$has_mac" = false ]; then
    echo -e "${YELLOW}[WARNING] No MAC (AppArmor/SELinux) detected${NC}" | tee -a "${REPORT_FILE}"
    echo "  Recommendation: Enable AppArmor or SELinux" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 10: Attempt common escape techniques (safe tests only)
echo -e "${YELLOW}[Test 10] Testing escape via /proc/self/exe...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ -L /proc/self/exe ]; then
    exe_target=$(readlink /proc/self/exe)
    if [[ "$exe_target" =~ ^/usr/bin/docker ]]; then
        echo -e "${RED}[VULNERABLE] /proc/self/exe points to docker binary${NC}" | tee -a "${REPORT_FILE}"
        echo "  This could indicate container breakout vector" | tee -a "${REPORT_FILE}"
        VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
    fi
fi
echo "" | tee -a "${REPORT_FILE}"

# Summary
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Container Escape Test Summary" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Total Tests: ${TOTAL_TESTS}" | tee -a "${REPORT_FILE}"
echo -e "Vulnerabilities Found: ${RED}${VULNERABILITIES_FOUND}${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

if [ $VULNERABILITIES_FOUND -gt 0 ]; then
    echo -e "${RED}CRITICAL: Container escape vulnerabilities detected!${NC}" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
    echo "Remediation:" | tee -a "${REPORT_FILE}"
    echo "1. Never run containers in privileged mode" | tee -a "${REPORT_FILE}"
    echo "2. Never mount Docker socket inside containers" | tee -a "${REPORT_FILE}"
    echo "3. Use AppArmor or SELinux profiles" | tee -a "${REPORT_FILE}"
    echo "4. Drop unnecessary capabilities" | tee -a "${REPORT_FILE}"
    echo "5. Use read-only root filesystem when possible" | tee -a "${REPORT_FILE}"
    echo "6. Never mount sensitive host paths" | tee -a "${REPORT_FILE}"
    echo "7. Enable user namespaces" | tee -a "${REPORT_FILE}"
    echo "8. Use security scanning tools like Trivy/Grype" | tee -a "${REPORT_FILE}"
else
    echo -e "${GREEN}PASS: No container escape vulnerabilities detected${NC}" | tee -a "${REPORT_FILE}"
fi

echo "" | tee -a "${REPORT_FILE}"
echo "Report saved to: ${REPORT_FILE}" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"

# Exit with error if vulnerabilities found
[ $VULNERABILITIES_FOUND -eq 0 ] && exit 0 || exit 1
