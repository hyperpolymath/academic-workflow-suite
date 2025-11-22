#!/bin/bash
# Secret Scanning Script
# Detects hardcoded secrets, API keys, and credentials

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPORT_DIR="${PROJECT_ROOT}/security/reports/secret-scan"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/secrets_${TIMESTAMP}.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create report directory
mkdir -p "${REPORT_DIR}"

echo "=========================================" | tee "${REPORT_FILE}"
echo "Secret Scanning Report" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Project: Academic Workflow Suite" | tee -a "${REPORT_FILE}"
echo "Timestamp: ${TIMESTAMP}" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

SECRETS_FOUND=0

# =====================================
# Check for .env files in git
# =====================================
echo -e "${YELLOW}[1/4] Checking for .env files in git...${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

cd "${PROJECT_ROOT}"
ENV_FILES=$(git ls-files | grep -E '\.env$|\.env\.|credentials|secrets' || true)

if [ -n "$ENV_FILES" ]; then
    echo -e "${RED}✗ Found sensitive files committed to git:${NC}" | tee -a "${REPORT_FILE}"
    echo "$ENV_FILES" | while read -r file; do
        echo "  - $file" | tee -a "${REPORT_FILE}"
        SECRETS_FOUND=$((SECRETS_FOUND + 1))
    done
    echo "" | tee -a "${REPORT_FILE}"
else
    echo -e "${GREEN}✓ No .env files found in git${NC}" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
fi

# =====================================
# Pattern-based secret detection
# =====================================
echo -e "${YELLOW}[2/4] Scanning for hardcoded secrets...${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

# Secret patterns to detect
declare -A SECRET_PATTERNS=(
    ["AWS Access Key"]='AKIA[0-9A-Z]{16}'
    ["AWS Secret Key"]='[0-9a-zA-Z/+=]{40}'
    ["GitHub Token"]='ghp_[0-9a-zA-Z]{36}'
    ["GitHub OAuth"]='gho_[0-9a-zA-Z]{36}'
    ["Generic API Key"]='api[_-]?key["\s:=]+[0-9a-zA-Z]{20,}'
    ["Generic Secret"]='secret["\s:=]+[0-9a-zA-Z]{16,}'
    ["Password"]='password["\s:=]+[^ \n]{8,}'
    ["Private Key"]='BEGIN (RSA|DSA|EC|OPENSSH) PRIVATE KEY'
    ["Bearer Token"]='Bearer [0-9a-zA-Z\-._~+/]+=*'
    ["Slack Token"]='xox[baprs]-[0-9]{10,12}-[0-9]{10,12}-[0-9a-zA-Z]{24,32}'
    ["Stripe Key"]='sk_live_[0-9a-zA-Z]{24,}'
    ["Google API Key"]='AIza[0-9A-Za-z\-_]{35}'
    ["Heroku API Key"]='[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
)

# Exclude patterns (common false positives)
EXCLUDE_PATTERNS=(
    "\.git/"
    "node_modules/"
    "vendor/"
    "\.lock$"
    "\.min\.js$"
    "\.min\.css$"
    "test"
    "example"
    "sample"
    "\.md$"
)

EXCLUDE_ARGS=""
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    EXCLUDE_ARGS="$EXCLUDE_ARGS --glob !*${pattern}*"
done

for secret_type in "${!SECRET_PATTERNS[@]}"; do
    pattern="${SECRET_PATTERNS[$secret_type]}"

    # Use ripgrep if available, otherwise grep
    if command -v rg &> /dev/null; then
        results=$(rg -i -n "$pattern" $EXCLUDE_ARGS "${PROJECT_ROOT}" 2>/dev/null || true)
    else
        results=$(grep -r -i -n -E "$pattern" "${PROJECT_ROOT}" 2>/dev/null | \
                  grep -v -E "$(IFS='|'; echo "${EXCLUDE_PATTERNS[*]}")" || true)
    fi

    if [ -n "$results" ]; then
        echo -e "${RED}✗ Found potential ${secret_type}:${NC}" | tee -a "${REPORT_FILE}"
        echo "$results" | head -5 | tee -a "${REPORT_FILE}"

        count=$(echo "$results" | wc -l)
        SECRETS_FOUND=$((SECRETS_FOUND + count))

        if [ "$count" -gt 5 ]; then
            echo "  ... and $((count - 5)) more" | tee -a "${REPORT_FILE}"
        fi
        echo "" | tee -a "${REPORT_FILE}"
    fi
done

if [ $SECRETS_FOUND -eq 0 ]; then
    echo -e "${GREEN}✓ No hardcoded secrets detected by pattern matching${NC}" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
fi

# =====================================
# Gitleaks scan (if available)
# =====================================
echo -e "${YELLOW}[3/4] Running gitleaks scan...${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

if command -v gitleaks &> /dev/null; then
    cd "${PROJECT_ROOT}"
    GITLEAKS_REPORT="${REPORT_DIR}/gitleaks_${TIMESTAMP}.json"

    if gitleaks detect --report-path "$GITLEAKS_REPORT" --report-format json 2>&1; then
        echo -e "${GREEN}✓ Gitleaks: No secrets detected${NC}" | tee -a "${REPORT_FILE}"
    else
        GITLEAKS_COUNT=$(jq length "$GITLEAKS_REPORT" 2>/dev/null || echo "0")
        echo -e "${RED}✗ Gitleaks found ${GITLEAKS_COUNT} potential secrets${NC}" | tee -a "${REPORT_FILE}"
        echo "See detailed report: ${GITLEAKS_REPORT}" | tee -a "${REPORT_FILE}"
        SECRETS_FOUND=$((SECRETS_FOUND + GITLEAKS_COUNT))
    fi
    echo "" | tee -a "${REPORT_FILE}"
else
    echo -e "${YELLOW}⊘ Gitleaks not installed. Install with:${NC}" | tee -a "${REPORT_FILE}"
    echo "  brew install gitleaks" | tee -a "${REPORT_FILE}"
    echo "  or download from https://github.com/gitleaks/gitleaks" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
fi

# =====================================
# TruffleHog scan (if available)
# =====================================
echo -e "${YELLOW}[4/4] Running TruffleHog scan...${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

if command -v trufflehog &> /dev/null; then
    cd "${PROJECT_ROOT}"
    TRUFFLEHOG_REPORT="${REPORT_DIR}/trufflehog_${TIMESTAMP}.json"

    if trufflehog filesystem . --json > "$TRUFFLEHOG_REPORT" 2>&1; then
        TRUFFLEHOG_COUNT=$(wc -l < "$TRUFFLEHOG_REPORT" | tr -d ' ')

        if [ "$TRUFFLEHOG_COUNT" -eq 0 ]; then
            echo -e "${GREEN}✓ TruffleHog: No secrets detected${NC}" | tee -a "${REPORT_FILE}"
        else
            echo -e "${RED}✗ TruffleHog found ${TRUFFLEHOG_COUNT} potential secrets${NC}" | tee -a "${REPORT_FILE}"
            echo "See detailed report: ${TRUFFLEHOG_REPORT}" | tee -a "${REPORT_FILE}"
            SECRETS_FOUND=$((SECRETS_FOUND + TRUFFLEHOG_COUNT))
        fi
    else
        echo -e "${YELLOW}⊘ TruffleHog scan completed with warnings${NC}" | tee -a "${REPORT_FILE}"
    fi
    echo "" | tee -a "${REPORT_FILE}"
else
    echo -e "${YELLOW}⊘ TruffleHog not installed. Install with:${NC}" | tee -a "${REPORT_FILE}"
    echo "  brew install trufflehog" | tee -a "${REPORT_FILE}"
    echo "  or download from https://github.com/trufflesecurity/trufflehog" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
fi

# =====================================
# Summary
# =====================================
echo "=========================================" | tee -a "${REPORT_FILE}"
echo "Secret Scan Summary" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"
echo -e "Total Potential Secrets Found: ${RED}${SECRETS_FOUND}${NC}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

if [ $SECRETS_FOUND -gt 0 ]; then
    echo -e "${RED}⚠ ACTION REQUIRED:${NC}" | tee -a "${REPORT_FILE}"
    echo "1. Review all detected secrets" | tee -a "${REPORT_FILE}"
    echo "2. Remove hardcoded secrets from code" | tee -a "${REPORT_FILE}"
    echo "3. Use environment variables or secret management" | tee -a "${REPORT_FILE}"
    echo "4. Rotate any exposed credentials" | tee -a "${REPORT_FILE}"
    echo "5. Update .gitignore to prevent future leaks" | tee -a "${REPORT_FILE}"
fi

echo "" | tee -a "${REPORT_FILE}"
echo "Report saved to: ${REPORT_FILE}" | tee -a "${REPORT_FILE}"
echo "=========================================" | tee -a "${REPORT_FILE}"

# Exit with error if secrets found
if [ $SECRETS_FOUND -gt 0 ]; then
    echo -e "${RED}FAIL: Potential secrets detected${NC}" | tee -a "${REPORT_FILE}"
    exit 1
fi

echo -e "${GREEN}PASS: No secrets detected${NC}" | tee -a "${REPORT_FILE}"
exit 0
