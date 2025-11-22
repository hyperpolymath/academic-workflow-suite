#!/bin/bash
# Filesystem Access Boundary Tests
# Tests filesystem access restrictions and boundary enforcement

set -euo pipefail

REPORT_FILE="/tmp/filesystem_access_report.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================" | tee "${REPORT_FILE}"
echo "Filesystem Access Boundary Test" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Date: $(date)" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

VIOLATIONS_FOUND=0
TOTAL_TESTS=0

# Test 1: Check if running with read-only root filesystem
echo -e "${YELLOW}[Test 1] Checking root filesystem permissions...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Try to create a file in root
if touch /test_write_$$  2>/dev/null; then
    echo -e "${YELLOW}[WARNING] Root filesystem is writable${NC}" | tee -a "${REPORT_FILE}"
    rm -f /test_write_$$ 2>/dev/null || true
else
    echo -e "${GREEN}✓ Root filesystem is read-only${NC}" | tee -a "${REPORT_FILE}"
fi

# Check mount options
if grep " / " /proc/mounts | grep -q "ro,"; then
    echo -e "${GREEN}✓ Root mounted read-only${NC}" | tee -a "${REPORT_FILE}"
else
    echo -e "${YELLOW}[WARNING] Root not mounted read-only${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 2: Check for sensitive host paths
echo -e "${YELLOW}[Test 2] Checking for sensitive host path mounts...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

SENSITIVE_PATHS=(
    "/proc"
    "/sys"
    "/dev"
    "/etc/passwd"
    "/etc/shadow"
    "/etc/group"
    "/boot"
    "/root"
    "/home"
)

sensitive_found=0
for path in "${SENSITIVE_PATHS[@]}"; do
    if [ -e "$path" ]; then
        # Check if it's a mount point from host
        if grep -q " $path " /proc/mounts 2>/dev/null; then
            mount_info=$(grep " $path " /proc/mounts)

            # Check if writable
            if [ -w "$path" ]; then
                echo -e "${RED}[VIOLATION] Writable sensitive path: ${path}${NC}" | tee -a "${REPORT_FILE}"
                echo "  Mount: $mount_info" | tee -a "${REPORT_FILE}"
                sensitive_found=$((sensitive_found + 1))
                VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
            fi
        fi
    fi
done

if [ $sensitive_found -eq 0 ]; then
    echo -e "${GREEN}✓ No writable sensitive paths found${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 3: Attempt to access /proc/1 (init on host)
echo -e "${YELLOW}[Test 3] Testing access to host init process...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ -r /proc/1/environ ] && [ -r /proc/1/cmdline ]; then
    cmdline=$(cat /proc/1/cmdline 2>/dev/null | tr '\0' ' ')

    # Check if this looks like container init or host init
    if echo "$cmdline" | grep -qE "(systemd|/sbin/init|launchd)"; then
        echo -e "${RED}[VIOLATION] Can access host init process${NC}" | tee -a "${REPORT_FILE}"
        echo "  PID 1 cmdline: $cmdline" | tee -a "${REPORT_FILE}"
        VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
    else
        echo -e "${GREEN}✓ PID 1 appears to be container init${NC}" | tee -a "${REPORT_FILE}"
    fi
else
    echo -e "${GREEN}✓ Cannot access PID 1 details${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 4: Check /tmp permissions
echo -e "${YELLOW}[Test 4] Checking /tmp permissions...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ -d /tmp ]; then
    if [ -w /tmp ]; then
        echo -e "${GREEN}✓ /tmp is writable (expected for temp files)${NC}" | tee -a "${REPORT_FILE}"

        # But check if it's a separate mount
        if ! grep -q " /tmp " /proc/mounts; then
            echo -e "${YELLOW}[INFO] /tmp not a separate mount (consider tmpfs)${NC}" | tee -a "${REPORT_FILE}"
        fi
    else
        echo -e "${YELLOW}[WARNING] /tmp is not writable${NC}" | tee -a "${REPORT_FILE}"
    fi
else
    echo -e "${YELLOW}[WARNING] /tmp does not exist${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 5: Check for host filesystem mounts
echo -e "${YELLOW}[Test 5] Scanning for host filesystem mounts...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

host_mounts=0
while IFS= read -r mount_line; do
    # Look for mounts that might be from host
    mount_point=$(echo "$mount_line" | awk '{print $2}')
    mount_type=$(echo "$mount_line" | awk '{print $3}')
    mount_options=$(echo "$mount_line" | awk '{print $4}')

    # Skip expected container mounts
    if [[ "$mount_point" =~ ^/(proc|sys|dev)$ ]]; then
        continue
    fi

    # Check for ext4, xfs, etc. (common host filesystems)
    if [[ "$mount_type" =~ ^(ext[234]|xfs|btrfs|zfs)$ ]]; then
        # Check if writable
        if echo "$mount_options" | grep -qv "ro"; then
            echo -e "${YELLOW}[WARNING] Potential host filesystem mount:${NC}" | tee -a "${REPORT_FILE}"
            echo "  $mount_line" | tee -a "${REPORT_FILE}"
            host_mounts=$((host_mounts + 1))
        fi
    fi
done < /proc/mounts

if [ $host_mounts -eq 0 ]; then
    echo -e "${GREEN}✓ No suspicious host filesystem mounts${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 6: Test directory traversal outside allowed paths
echo -e "${YELLOW}[Test 6] Testing directory traversal restrictions...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Try to access common system paths
SYSTEM_PATHS=(
    "/etc/hostname"
    "/etc/hosts"
    "/etc/ssl/certs"
    "/var/log"
    "/var/lib"
)

accessible_count=0
for sys_path in "${SYSTEM_PATHS[@]}"; do
    if [ -r "$sys_path" ]; then
        accessible_count=$((accessible_count + 1))
    fi
done

echo "Accessible system paths: ${accessible_count}/${#SYSTEM_PATHS[@]}" | tee -a "${REPORT_FILE}"

if [ $accessible_count -eq ${#SYSTEM_PATHS[@]} ]; then
    echo -e "${YELLOW}[INFO] All system paths accessible${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 7: Check for world-writable files
echo -e "${YELLOW}[Test 7] Scanning for world-writable files...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

world_writable=$(find / -xdev -type f -perm -0002 ! -path "/proc/*" ! -path "/sys/*" 2>/dev/null | head -10)

if [ -n "$world_writable" ]; then
    echo -e "${YELLOW}[WARNING] World-writable files found (first 10):${NC}" | tee -a "${REPORT_FILE}"
    echo "$world_writable" | while read -r file; do
        echo "  $file" | tee -a "${REPORT_FILE}"
        ls -l "$file" | tee -a "${REPORT_FILE}"
    done
else
    echo -e "${GREEN}✓ No world-writable files found${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 8: Check noexec on writable partitions
echo -e "${YELLOW}[Test 8] Checking noexec on writable partitions...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

noexec_violations=0
while IFS= read -r mount_line; do
    mount_point=$(echo "$mount_line" | awk '{print $2}')
    mount_options=$(echo "$mount_line" | awk '{print $4}')

    # Check if writable but not noexec
    if echo "$mount_options" | grep -qv "ro" && echo "$mount_options" | grep -qv "noexec"; then
        # Test if we can execute
        if [ -w "$mount_point" ] && [ "$mount_point" != "/" ] && [ "$mount_point" != "/proc" ] && [ "$mount_point" != "/sys" ]; then
            echo -e "${YELLOW}[WARNING] Writable partition without noexec: ${mount_point}${NC}" | tee -a "${REPORT_FILE}"
            noexec_violations=$((noexec_violations + 1))
        fi
    fi
done < /proc/mounts

if [ $noexec_violations -eq 0 ]; then
    echo -e "${GREEN}✓ Writable partitions have noexec or are root${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 9: Check filesystem capabilities
echo -e "${YELLOW}[Test 9] Checking for files with capabilities...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if command -v getcap &> /dev/null; then
    files_with_caps=$(find / -xdev -type f -exec getcap {} \; 2>/dev/null | grep -v "=" | head -10 || true)

    if [ -n "$files_with_caps" ]; then
        echo -e "${YELLOW}[WARNING] Files with capabilities found:${NC}" | tee -a "${REPORT_FILE}"
        echo "$files_with_caps" | tee -a "${REPORT_FILE}"
    else
        echo -e "${GREEN}✓ No files with capabilities found${NC}" | tee -a "${REPORT_FILE}"
    fi
else
    echo -e "${YELLOW}⊘ getcap not available${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 10: Check for symlink attacks
echo -e "${YELLOW}[Test 10] Checking symlink protections...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Check /proc/sys/fs/protected_symlinks
if [ -f /proc/sys/fs/protected_symlinks ]; then
    protected_symlinks=$(cat /proc/sys/fs/protected_symlinks)

    if [ "$protected_symlinks" == "1" ]; then
        echo -e "${GREEN}✓ Symlink protection enabled${NC}" | tee -a "${REPORT_FILE}"
    else
        echo -e "${YELLOW}[WARNING] Symlink protection disabled${NC}" | tee -a "${REPORT_FILE}"
    fi
else
    echo -e "${YELLOW}[INFO] Cannot check symlink protection${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Summary
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Filesystem Access Test Summary" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Total Tests: ${TOTAL_TESTS}" | tee -a "${REPORT_FILE}"
echo -e "Violations Found: ${RED}${VIOLATIONS_FOUND}${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

if [ $VIOLATIONS_FOUND -gt 0 ]; then
    echo -e "${RED}FAIL: Filesystem access violations detected!${NC}" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
    echo "Remediation:" | tee -a "${REPORT_FILE}"
    echo "1. Use read-only root filesystem (--read-only)" | tee -a "${REPORT_FILE}"
    echo "2. Never mount sensitive host paths" | tee -a "${REPORT_FILE}"
    echo "3. Use tmpfs for /tmp" | tee -a "${REPORT_FILE}"
    echo "4. Apply noexec to writable partitions" | tee -a "${REPORT_FILE}"
    echo "5. Use minimal base images" | tee -a "${REPORT_FILE}"
    echo "6. Enable filesystem protection features" | tee -a "${REPORT_FILE}"
else
    echo -e "${GREEN}PASS: Filesystem access properly restricted${NC}" | tee -a "${REPORT_FILE}"
fi

echo "" | tee -a "${REPORT_FILE}"
echo "Report saved to: ${REPORT_FILE}" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"

# Exit with error if violations found
[ $VIOLATIONS_FOUND -eq 0 ] && exit 0 || exit 1
