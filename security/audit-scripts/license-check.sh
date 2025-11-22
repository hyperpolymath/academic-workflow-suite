#!/bin/bash
# License Compliance Check Script
# Verifies all dependencies use GPL-compatible licenses

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPORT_DIR="${PROJECT_ROOT}/security/reports/license-audit"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/license_${TIMESTAMP}.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create report directory
mkdir -p "${REPORT_DIR}"

# GPL-compatible licenses
GPL_COMPATIBLE_LICENSES=(
    "MIT"
    "Apache-2.0"
    "BSD-2-Clause"
    "BSD-3-Clause"
    "ISC"
    "LGPL-2.1"
    "LGPL-3.0"
    "GPL-2.0"
    "GPL-3.0"
    "MPL-2.0"
    "CC0-1.0"
    "Unlicense"
    "0BSD"
    "Zlib"
    "Python-2.0"
)

# Problematic licenses
PROPRIETARY_LICENSES=(
    "UNLICENSED"
    "Commercial"
    "Proprietary"
    "AGPL-1.0"
    "AGPL-3.0"
)

echo "=========================================" | tee "${REPORT_FILE}"
echo "License Compliance Check" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Project: Academic Workflow Suite" | tee -a "${REPORT_FILE}"
echo "Timestamp: ${TIMESTAMP}" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

INCOMPATIBLE_COUNT=0
PROPRIETARY_COUNT=0
UNKNOWN_COUNT=0

# Function to check if license is GPL-compatible
is_gpl_compatible() {
    local license=$1
    for compat_license in "${GPL_COMPATIBLE_LICENSES[@]}"; do
        if [[ "$license" == "$compat_license"* ]]; then
            return 0
        fi
    done
    return 1
}

# Function to check if license is proprietary
is_proprietary() {
    local license=$1
    for prop_license in "${PROPRIETARY_LICENSES[@]}"; do
        if [[ "$license" == "$prop_license"* ]]; then
            return 0
        fi
    done
    return 1
}

# =====================================
# Check Rust Dependencies
# =====================================
echo -e "${YELLOW}[1/3] Checking Rust dependency licenses...${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

if [ -f "${PROJECT_ROOT}/Cargo.toml" ]; then
    # Install cargo-license if not present
    if ! command -v cargo-license &> /dev/null; then
        echo "Installing cargo-license..." | tee -a "${REPORT_FILE}"
        cargo install cargo-license
    fi

    cd "${PROJECT_ROOT}"
    echo "Rust Dependencies:" | tee -a "${REPORT_FILE}"
    echo "----------------------------------------" | tee -a "${REPORT_FILE}"

    while IFS=$'\t' read -r name version license; do
        if [ -z "$license" ] || [ "$license" == "Unknown" ]; then
            echo -e "${RED}⚠ ${name} ${version}: UNKNOWN LICENSE${NC}" | tee -a "${REPORT_FILE}"
            UNKNOWN_COUNT=$((UNKNOWN_COUNT + 1))
        elif is_proprietary "$license"; then
            echo -e "${RED}✗ ${name} ${version}: ${license} (PROPRIETARY)${NC}" | tee -a "${REPORT_FILE}"
            PROPRIETARY_COUNT=$((PROPRIETARY_COUNT + 1))
        elif ! is_gpl_compatible "$license"; then
            echo -e "${RED}✗ ${name} ${version}: ${license} (INCOMPATIBLE)${NC}" | tee -a "${REPORT_FILE}"
            INCOMPATIBLE_COUNT=$((INCOMPATIBLE_COUNT + 1))
        else
            echo -e "${GREEN}✓ ${name} ${version}: ${license}${NC}" | tee -a "${REPORT_FILE}"
        fi
    done < <(cargo license --json 2>/dev/null | jq -r '.[] | [.name, .version, (.license // "Unknown")] | @tsv')

    echo "" | tee -a "${REPORT_FILE}"
else
    echo "No Cargo.toml found, skipping Rust license check" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
fi

# =====================================
# Check Elixir Dependencies
# =====================================
echo -e "${YELLOW}[2/3] Checking Elixir dependency licenses...${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

if [ -f "${PROJECT_ROOT}/mix.exs" ]; then
    cd "${PROJECT_ROOT}"
    echo "Elixir Dependencies:" | tee -a "${REPORT_FILE}"
    echo "----------------------------------------" | tee -a "${REPORT_FILE}"

    # Get dependencies
    if command -v mix &> /dev/null; then
        mix deps.get 2>/dev/null || true

        # Parse mix.lock for dependencies
        if [ -f "mix.lock" ]; then
            while IFS= read -r line; do
                if [[ $line =~ \"([^\"]+)\" ]]; then
                    dep_name="${BASH_REMATCH[1]}"

                    # Try to get license from hex.pm
                    if command -v curl &> /dev/null; then
                        license=$(curl -s "https://hex.pm/api/packages/${dep_name}" 2>/dev/null | jq -r '.meta.licenses[0] // "Unknown"' 2>/dev/null || echo "Unknown")
                    else
                        license="Unknown"
                    fi

                    if [ "$license" == "Unknown" ]; then
                        echo -e "${RED}⚠ ${dep_name}: UNKNOWN LICENSE${NC}" | tee -a "${REPORT_FILE}"
                        UNKNOWN_COUNT=$((UNKNOWN_COUNT + 1))
                    elif is_proprietary "$license"; then
                        echo -e "${RED}✗ ${dep_name}: ${license} (PROPRIETARY)${NC}" | tee -a "${REPORT_FILE}"
                        PROPRIETARY_COUNT=$((PROPRIETARY_COUNT + 1))
                    elif ! is_gpl_compatible "$license"; then
                        echo -e "${RED}✗ ${dep_name}: ${license} (INCOMPATIBLE)${NC}" | tee -a "${REPORT_FILE}"
                        INCOMPATIBLE_COUNT=$((INCOMPATIBLE_COUNT + 1))
                    else
                        echo -e "${GREEN}✓ ${dep_name}: ${license}${NC}" | tee -a "${REPORT_FILE}"
                    fi
                fi
            done < mix.lock
        fi
    else
        echo "Mix not installed, cannot check Elixir licenses" | tee -a "${REPORT_FILE}"
    fi

    echo "" | tee -a "${REPORT_FILE}"
else
    echo "No mix.exs found, skipping Elixir license check" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
fi

# =====================================
# Check Node.js Dependencies
# =====================================
echo -e "${YELLOW}[3/3] Checking Node.js dependency licenses...${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

if [ -f "${PROJECT_ROOT}/package.json" ]; then
    # Install license-checker if not present
    if ! command -v license-checker &> /dev/null; then
        echo "Installing license-checker..." | tee -a "${REPORT_FILE}"
        npm install -g license-checker 2>/dev/null || npm install license-checker
    fi

    cd "${PROJECT_ROOT}"
    echo "Node.js Dependencies:" | tee -a "${REPORT_FILE}"
    echo "----------------------------------------" | tee -a "${REPORT_FILE}"

    if command -v license-checker &> /dev/null; then
        while IFS='@' read -r name_version; do
            # Parse name and version
            if [[ $name_version =~ ^(.+)@([0-9].+)$ ]]; then
                name="${BASH_REMATCH[1]}"
                license=$(npm view "$name" license 2>/dev/null || echo "Unknown")

                if [ "$license" == "Unknown" ]; then
                    echo -e "${RED}⚠ ${name}: UNKNOWN LICENSE${NC}" | tee -a "${REPORT_FILE}"
                    UNKNOWN_COUNT=$((UNKNOWN_COUNT + 1))
                elif is_proprietary "$license"; then
                    echo -e "${RED}✗ ${name}: ${license} (PROPRIETARY)${NC}" | tee -a "${REPORT_FILE}"
                    PROPRIETARY_COUNT=$((PROPRIETARY_COUNT + 1))
                elif ! is_gpl_compatible "$license"; then
                    echo -e "${RED}✗ ${name}: ${license} (INCOMPATIBLE)${NC}" | tee -a "${REPORT_FILE}"
                    INCOMPATIBLE_COUNT=$((INCOMPATIBLE_COUNT + 1))
                else
                    echo -e "${GREEN}✓ ${name}: ${license}${NC}" | tee -a "${REPORT_FILE}"
                fi
            fi
        done < <(license-checker --json 2>/dev/null | jq -r 'keys[]' 2>/dev/null || echo "")
    fi

    echo "" | tee -a "${REPORT_FILE}"
else
    echo "No package.json found, skipping Node.js license check" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
fi

# =====================================
# Summary
# =====================================
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "License Compliance Summary" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo -e "Proprietary Licenses:     ${RED}${PROPRIETARY_COUNT}${NC}" | tee -a "${REPORT_FILE}"
echo -e "Incompatible Licenses:    ${RED}${INCOMPATIBLE_COUNT}${NC}" | tee -a "${REPORT_FILE}"
echo -e "Unknown Licenses:         ${YELLOW}${UNKNOWN_COUNT}${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"
echo "Report saved to: ${REPORT_FILE}" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"

# Exit with error if issues found
if [ $((PROPRIETARY_COUNT + INCOMPATIBLE_COUNT)) -gt 0 ]; then
    echo -e "${RED}FAIL: Proprietary or incompatible licenses detected${NC}" | tee -a "${REPORT_FILE}"
    exit 1
fi

if [ $UNKNOWN_COUNT -gt 0 ]; then
    echo -e "${YELLOW}WARNING: Unknown licenses detected${NC}" | tee -a "${REPORT_FILE}"
    exit 2
fi

echo -e "${GREEN}PASS: All licenses are GPL-compatible${NC}" | tee -a "${REPORT_FILE}"
exit 0
