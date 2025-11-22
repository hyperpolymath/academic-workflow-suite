#!/bin/bash
# Container Escape Prevention Test
# Verifies that the AI container cannot escape to the host system
#
# Exit codes:
#   0 - All tests passed (escape prevented)
#   1 - Test failed (escape possible)
#   2 - Test setup error

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "AI Container Escape Prevention Test"
echo "=========================================="
echo ""

CONTAINER_NAME="${1:-ai-grading-container}"
PASS_COUNT=0
FAIL_COUNT=0
test_number=1

run_test() {
    local test_name="$1"
    local test_command="$2"
    local expect_failure="${3:-true}"

    echo -e "${YELLOW}Test $test_number: $test_name${NC}"

    if $expect_failure; then
        if eval "$test_command" &> /dev/null; then
            echo -e "${RED}✗ FAILED${NC} - Security breach detected"
            FAIL_COUNT=$((FAIL_COUNT + 1))
            return 1
        else
            echo -e "${GREEN}✓ PASSED${NC} - Attack prevented"
            PASS_COUNT=$((PASS_COUNT + 1))
            return 0
        fi
    else
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

# Verify container exists and is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}Error: Container '${CONTAINER_NAME}' not running${NC}"
    exit 2
fi

echo "Testing container: ${CONTAINER_NAME}"
echo ""

# Test 1: Verify container is not running as privileged
echo -e "${YELLOW}Test $test_number: Container privilege level${NC}"
PRIVILEGED=$(docker inspect ${CONTAINER_NAME} --format='{{.HostConfig.Privileged}}')
if [ "$PRIVILEGED" = "false" ]; then
    echo -e "${GREEN}✓ PASSED${NC} - Container not privileged"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "${RED}✗ FAILED${NC} - Container running with elevated privileges"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
test_number=$((test_number + 1))
echo ""

# Test 2: Check for dangerous capabilities
echo -e "${YELLOW}Test $test_number: Container capabilities${NC}"
CAPS=$(docker inspect ${CONTAINER_NAME} --format='{{.HostConfig.CapAdd}}')
DANGEROUS_CAPS="SYS_ADMIN|SYS_MODULE|SYS_RAWIO|SYS_PTRACE|DAC_READ_SEARCH"
if echo "$CAPS" | grep -qE "$DANGEROUS_CAPS"; then
    echo -e "${RED}✗ FAILED${NC} - Dangerous capabilities detected: $CAPS"
    FAIL_COUNT=$((FAIL_COUNT + 1))
else
    echo -e "${GREEN}✓ PASSED${NC} - No dangerous capabilities"
    PASS_COUNT=$((PASS_COUNT + 1))
fi
test_number=$((test_number + 1))
echo ""

# Test 3: Attempt to access host filesystem via /proc
run_test "Block /proc/sys access" \
    "docker exec ${CONTAINER_NAME} sh -c 'echo 1 > /proc/sys/kernel/hostname'"

# Test 4: Attempt to access host devices
run_test "Block /dev/sda access" \
    "docker exec ${CONTAINER_NAME} test -b /dev/sda"

# Test 5: Attempt to load kernel modules
run_test "Block kernel module loading" \
    "docker exec ${CONTAINER_NAME} modprobe dummy_module"

# Test 6: Check if Docker socket is mounted
echo -e "${YELLOW}Test $test_number: Docker socket exposure${NC}"
DOCKER_SOCK=$(docker exec ${CONTAINER_NAME} test -S /var/run/docker.sock && echo "present" || echo "absent")
if [ "$DOCKER_SOCK" = "absent" ]; then
    echo -e "${GREEN}✓ PASSED${NC} - Docker socket not exposed"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "${RED}✗ FAILED${NC} - Docker socket accessible in container"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
test_number=$((test_number + 1))
echo ""

# Test 7: Verify read-only filesystem (if configured)
echo -e "${YELLOW}Test $test_number: Filesystem write protection${NC}"
READONLY=$(docker inspect ${CONTAINER_NAME} --format='{{.HostConfig.ReadonlyRootfs}}')
# Note: This might be false for legitimate reasons (temp files, logs)
# Just log the status
echo "Readonly filesystem: $READONLY"
if [ "$READONLY" = "true" ]; then
    echo -e "${GREEN}✓ INFO${NC} - Root filesystem is read-only (enhanced security)"
else
    echo -e "${YELLOW}ℹ INFO${NC} - Root filesystem is writable (standard)"
fi
test_number=$((test_number + 1))
echo ""

# Test 8: Attempt to access host network namespaces
run_test "Block host network namespace access" \
    "docker exec ${CONTAINER_NAME} test -r /var/run/netns"

# Test 9: Check for privileged mount points
echo -e "${YELLOW}Test $test_number: Dangerous volume mounts${NC}"
MOUNTS=$(docker inspect ${CONTAINER_NAME} --format='{{range .Mounts}}{{.Source}}:{{.Destination}} {{end}}')
DANGEROUS_MOUNTS="/proc|/sys|/dev|/boot|/lib/modules"
if echo "$MOUNTS" | grep -qE "$DANGEROUS_MOUNTS"; then
    echo -e "${RED}✗ FAILED${NC} - Dangerous mounts detected"
    echo "Mounts: $MOUNTS"
    FAIL_COUNT=$((FAIL_COUNT + 1))
else
    echo -e "${GREEN}✓ PASSED${NC} - No dangerous mounts"
    PASS_COUNT=$((PASS_COUNT + 1))
fi
test_number=$((test_number + 1))
echo ""

# Test 10: Verify user is not root (or properly namespaced)
echo -e "${YELLOW}Test $test_number: Container user permissions${NC}"
CONTAINER_USER=$(docker exec ${CONTAINER_NAME} whoami)
if [ "$CONTAINER_USER" != "root" ]; then
    echo -e "${GREEN}✓ PASSED${NC} - Running as non-root user: $CONTAINER_USER"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    # Check if user namespacing is enabled
    USER_NS=$(docker inspect ${CONTAINER_NAME} --format='{{.HostConfig.UsernsMode}}')
    if [ "$USER_NS" = "host" ]; then
        echo -e "${RED}✗ WARNING${NC} - Running as root without user namespace remapping"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        echo -e "${YELLOW}ℹ INFO${NC} - Running as root but with user namespacing"
        PASS_COUNT=$((PASS_COUNT + 1))
    fi
fi
test_number=$((test_number + 1))
echo ""

# Test 11: Attempt cgroup manipulation
run_test "Block cgroup manipulation" \
    "docker exec ${CONTAINER_NAME} sh -c 'echo 1 > /sys/fs/cgroup/memory/memory.limit_in_bytes'"

# Test 12: Check for AppArmor/SELinux profiles
echo -e "${YELLOW}Test $test_number: Security profiles${NC}"
APPARMOR=$(docker inspect ${CONTAINER_NAME} --format='{{.AppArmorProfile}}')
SELINUX=$(docker inspect ${CONTAINER_NAME} --format='{{.HostConfig.SecurityOpt}}')
if [ -n "$APPARMOR" ] || [ -n "$SELINUX" ]; then
    echo -e "${GREEN}✓ PASSED${NC} - Security profile active"
    echo "AppArmor: ${APPARMOR:-none}, SELinux: ${SELINUX:-none}"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "${YELLOW}ℹ INFO${NC} - No mandatory access control profile detected"
    # Not failing this as it may be acceptable depending on setup
    PASS_COUNT=$((PASS_COUNT + 1))
fi
test_number=$((test_number + 1))
echo ""

# Test 13: Verify PID namespace isolation
echo -e "${YELLOW}Test $test_number: PID namespace isolation${NC}"
PID_MODE=$(docker inspect ${CONTAINER_NAME} --format='{{.HostConfig.PidMode}}')
if [ "$PID_MODE" = "" ] || [ "$PID_MODE" = "private" ]; then
    echo -e "${GREEN}✓ PASSED${NC} - PID namespace isolated"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "${RED}✗ FAILED${NC} - PID namespace: $PID_MODE"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
test_number=$((test_number + 1))
echo ""

# Test 14: Attempt to ptrace host processes
run_test "Block ptrace of host processes" \
    "docker exec ${CONTAINER_NAME} strace -p 1"

# Test 15: Resource limits verification
echo -e "${YELLOW}Test $test_number: Resource limits${NC}"
MEMORY_LIMIT=$(docker inspect ${CONTAINER_NAME} --format='{{.HostConfig.Memory}}')
CPU_QUOTA=$(docker inspect ${CONTAINER_NAME} --format='{{.HostConfig.CpuQuota}}')
if [ "$MEMORY_LIMIT" != "0" ] && [ "$CPU_QUOTA" != "0" ]; then
    echo -e "${GREEN}✓ PASSED${NC} - Resource limits configured"
    echo "Memory: $MEMORY_LIMIT, CPU Quota: $CPU_QUOTA"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "${YELLOW}ℹ INFO${NC} - No resource limits (may allow resource exhaustion)"
    # Not failing as unlimited resources may be intentional
    PASS_COUNT=$((PASS_COUNT + 1))
fi
test_number=$((test_number + 1))
echo ""

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
    echo "Container escape prevention measures are properly configured."
    exit 0
else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    echo "Container may be vulnerable to escape attacks."
    exit 1
fi
