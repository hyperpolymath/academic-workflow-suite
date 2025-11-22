#!/bin/bash
# Privilege Escalation Tests
# Tests for privilege escalation vulnerabilities within containers

set -euo pipefail

REPORT_FILE="/tmp/privilege_escalation_report.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================" | tee "${REPORT_FILE}"
echo "Privilege Escalation Penetration Test" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Date: $(date)" | tee -a "${REPORT_FILE}"
echo "Current User: $(whoami)" | tee -a "${REPORT_FILE}"
echo "Current UID: $(id -u)" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

VULNERABILITIES_FOUND=0
TOTAL_TESTS=0

# Test 1: Check for SUID binaries
echo -e "${YELLOW}[Test 1] Scanning for SUID binaries...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

DANGEROUS_SUID=(
    "/bin/su"
    "/bin/sudo"
    "/usr/bin/sudo"
    "/bin/mount"
    "/usr/bin/docker"
    "/usr/bin/find"
    "/usr/bin/vim"
    "/usr/bin/nano"
    "/usr/bin/less"
    "/usr/bin/more"
)

suid_found=0
while IFS= read -r suid_file; do
    # Check if it's a dangerous SUID
    for dangerous in "${DANGEROUS_SUID[@]}"; do
        if [[ "$suid_file" == "$dangerous" ]]; then
            echo -e "${RED}[VULNERABLE] Dangerous SUID binary: ${suid_file}${NC}" | tee -a "${REPORT_FILE}"
            ls -l "$suid_file" | tee -a "${REPORT_FILE}"
            suid_found=$((suid_found + 1))
        fi
    done
done < <(find / -perm -4000 -type f 2>/dev/null)

if [ $suid_found -gt 0 ]; then
    VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
    echo "  Impact: May allow privilege escalation to root" | tee -a "${REPORT_FILE}"
else
    echo -e "${GREEN}✓ No dangerous SUID binaries found${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 2: Check for writable files in privileged directories
echo -e "${YELLOW}[Test 2] Checking for writable privileged files...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

PRIVILEGED_DIRS=(
    "/etc"
    "/usr/bin"
    "/usr/sbin"
    "/bin"
    "/sbin"
)

writable_found=0
for dir in "${PRIVILEGED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        while IFS= read -r writable_file; do
            echo -e "${RED}[VULNERABLE] Writable privileged file: ${writable_file}${NC}" | tee -a "${REPORT_FILE}"
            ls -l "$writable_file" | tee -a "${REPORT_FILE}"
            writable_found=$((writable_found + 1))

            # Limit output
            if [ $writable_found -ge 5 ]; then
                echo "  ... (stopping after 5 findings)" | tee -a "${REPORT_FILE}"
                break 2
            fi
        done < <(find "$dir" -type f -writable 2>/dev/null)
    fi
done

if [ $writable_found -gt 0 ]; then
    VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
    echo "  Impact: Can modify system binaries or configs" | tee -a "${REPORT_FILE}"
else
    echo -e "${GREEN}✓ No writable privileged files found${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 3: Check sudo permissions
echo -e "${YELLOW}[Test 3] Checking sudo permissions...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if command -v sudo &> /dev/null; then
    sudo_perms=$(sudo -l 2>&1 || echo "")

    if echo "$sudo_perms" | grep -q "may run the following"; then
        echo -e "${YELLOW}[INFO] User has sudo permissions:${NC}" | tee -a "${REPORT_FILE}"
        echo "$sudo_perms" | tee -a "${REPORT_FILE}"

        # Check for dangerous sudo rules
        if echo "$sudo_perms" | grep -qE "(ALL|NOPASSWD)"; then
            echo -e "${RED}[VULNERABLE] Dangerous sudo configuration${NC}" | tee -a "${REPORT_FILE}"
            VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
        fi
    else
        echo -e "${GREEN}✓ No sudo permissions for current user${NC}" | tee -a "${REPORT_FILE}"
    fi
else
    echo -e "${GREEN}✓ sudo not available${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 4: Check for writable cron jobs
echo -e "${YELLOW}[Test 4] Checking for writable cron configurations...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

CRON_DIRS=(
    "/etc/cron.d"
    "/etc/cron.daily"
    "/etc/cron.hourly"
    "/etc/cron.monthly"
    "/etc/cron.weekly"
    "/var/spool/cron"
)

cron_writable=0
for cron_dir in "${CRON_DIRS[@]}"; do
    if [ -d "$cron_dir" ] && [ -w "$cron_dir" ]; then
        echo -e "${RED}[VULNERABLE] Writable cron directory: ${cron_dir}${NC}" | tee -a "${REPORT_FILE}"
        cron_writable=$((cron_writable + 1))
    fi
done

if [ -f "/etc/crontab" ] && [ -w "/etc/crontab" ]; then
    echo -e "${RED}[VULNERABLE] /etc/crontab is writable${NC}" | tee -a "${REPORT_FILE}"
    cron_writable=$((cron_writable + 1))
fi

if [ $cron_writable -gt 0 ]; then
    VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
    echo "  Impact: Can execute commands as root via cron" | tee -a "${REPORT_FILE}"
else
    echo -e "${GREEN}✓ Cron configurations are protected${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 5: Check for capabilities
echo -e "${YELLOW}[Test 5] Checking process capabilities...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if command -v capsh &> /dev/null; then
    capabilities=$(capsh --print 2>/dev/null || echo "")
    echo "Current capabilities:" | tee -a "${REPORT_FILE}"
    echo "$capabilities" | tee -a "${REPORT_FILE}"

    # Check for dangerous capabilities
    DANGEROUS_CAPS=(
        "cap_sys_admin"
        "cap_sys_module"
        "cap_sys_rawio"
        "cap_dac_override"
        "cap_dac_read_search"
    )

    for cap in "${DANGEROUS_CAPS[@]}"; do
        if echo "$capabilities" | grep -qi "$cap"; then
            echo -e "${RED}[VULNERABLE] Has dangerous capability: ${cap}${NC}" | tee -a "${REPORT_FILE}"
            VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
        fi
    done
elif command -v getpcaps &> /dev/null; then
    current_caps=$(getpcaps $$ 2>&1 || echo "")
    echo "Current capabilities: $current_caps" | tee -a "${REPORT_FILE}"
else
    echo -e "${YELLOW}⊘ Capability tools not available${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 6: Check for Docker group membership
echo -e "${YELLOW}[Test 6] Checking Docker group membership...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if groups | grep -q docker; then
    echo -e "${RED}[VULNERABLE] User is in docker group${NC}" | tee -a "${REPORT_FILE}"
    echo "  Impact: Equivalent to root access on host" | tee -a "${REPORT_FILE}"
    VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
else
    echo -e "${GREEN}✓ User not in docker group${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 7: Check for writable /etc/passwd or /etc/shadow
echo -e "${YELLOW}[Test 7] Checking authentication file permissions...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ -w /etc/passwd ]; then
    echo -e "${RED}[CRITICAL] /etc/passwd is writable!${NC}" | tee -a "${REPORT_FILE}"
    echo "  Impact: Can add root user" | tee -a "${REPORT_FILE}"
    VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
fi

if [ -w /etc/shadow ]; then
    echo -e "${RED}[CRITICAL] /etc/shadow is writable!${NC}" | tee -a "${REPORT_FILE}"
    echo "  Impact: Can modify root password" | tee -a "${REPORT_FILE}"
    VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
fi

if [ ! -w /etc/passwd ] && [ ! -w /etc/shadow ]; then
    echo -e "${GREEN}✓ Authentication files are protected${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 8: Check for world-writable directories in PATH
echo -e "${YELLOW}[Test 8] Checking for writable directories in PATH...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

path_vulnerable=0
IFS=':' read -ra PATH_DIRS <<< "$PATH"
for path_dir in "${PATH_DIRS[@]}"; do
    if [ -d "$path_dir" ] && [ -w "$path_dir" ]; then
        echo -e "${RED}[VULNERABLE] Writable PATH directory: ${path_dir}${NC}" | tee -a "${REPORT_FILE}"
        path_vulnerable=$((path_vulnerable + 1))
    fi
done

if [ $path_vulnerable -gt 0 ]; then
    echo "  Impact: Can hijack system commands" | tee -a "${REPORT_FILE}"
    VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
else
    echo -e "${GREEN}✓ No writable directories in PATH${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Test 9: Check for LD_PRELOAD/LD_LIBRARY_PATH exploitation
echo -e "${YELLOW}[Test 9] Checking for library injection vectors...${NC}" | tee -a "${REPORT_FILE}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ -n "${LD_PRELOAD:-}" ]; then
    echo -e "${YELLOW}[WARNING] LD_PRELOAD is set: ${LD_PRELOAD}${NC}" | tee -a "${REPORT_FILE}"
fi

if [ -n "${LD_LIBRARY_PATH:-}" ]; then
    echo -e "${YELLOW}[WARNING] LD_LIBRARY_PATH is set: ${LD_LIBRARY_PATH}${NC}" | tee -a "${REPORT_FILE}"

    # Check if any directories are writable
    IFS=':' read -ra LIB_DIRS <<< "$LD_LIBRARY_PATH"
    for lib_dir in "${LIB_DIRS[@]}"; do
        if [ -d "$lib_dir" ] && [ -w "$lib_dir" ]; then
            echo -e "${RED}[VULNERABLE] Writable library path: ${lib_dir}${NC}" | tee -a "${REPORT_FILE}"
            VULNERABILITIES_FOUND=$((VULNERABILITIES_FOUND + 1))
        fi
    done
fi

if [ -z "${LD_PRELOAD:-}" ] && [ -z "${LD_LIBRARY_PATH:-}" ]; then
    echo -e "${GREEN}✓ No library injection environment variables set${NC}" | tee -a "${REPORT_FILE}"
fi
echo "" | tee -a "${REPORT_FILE}"

# Summary
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Privilege Escalation Test Summary" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Total Tests: ${TOTAL_TESTS}" | tee -a "${REPORT_FILE}"
echo -e "Vulnerabilities Found: ${RED}${VULNERABILITIES_FOUND}${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

if [ $VULNERABILITIES_FOUND -gt 0 ]; then
    echo -e "${RED}CRITICAL: Privilege escalation vulnerabilities detected!${NC}" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
    echo "Remediation:" | tee -a "${REPORT_FILE}"
    echo "1. Remove SUID bit from unnecessary binaries" | tee -a "${REPORT_FILE}"
    echo "2. Fix file permissions in privileged directories" | tee -a "${REPORT_FILE}"
    echo "3. Review and restrict sudo permissions" | tee -a "${REPORT_FILE}"
    echo "4. Drop unnecessary capabilities" | tee -a "${REPORT_FILE}"
    echo "5. Run containers as non-root user" | tee -a "${REPORT_FILE}"
    echo "6. Use read-only root filesystem" | tee -a "${REPORT_FILE}"
    echo "7. Remove users from docker group (use sudo instead)" | tee -a "${REPORT_FILE}"
else
    echo -e "${GREEN}PASS: No privilege escalation vulnerabilities detected${NC}" | tee -a "${REPORT_FILE}"
fi

echo "" | tee -a "${REPORT_FILE}"
echo "Report saved to: ${REPORT_FILE}" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"

# Exit with error if vulnerabilities found
[ $VULNERABILITIES_FOUND -eq 0 ] && exit 0 || exit 1
