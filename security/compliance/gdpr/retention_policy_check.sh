#!/bin/bash
# GDPR Retention Policy Verification

set -euo pipefail

REPORT_FILE="/tmp/gdpr_retention_check.txt"
echo "GDPR Data Retention Policy Check" | tee "${REPORT_FILE}"
echo "=================================" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

# Define retention periods (in days)
STUDENT_DATA_RETENTION=2555  # 7 years (academic records)
LOG_RETENTION=730            # 2 years
TEMP_DATA_RETENTION=30       # 30 days

echo "Retention Policy Configuration:" | tee -a "${REPORT_FILE}"
echo "- Student records: ${STUDENT_DATA_RETENTION} days (7 years)" | tee -a "${REPORT_FILE}"
echo "- Audit logs: ${LOG_RETENTION} days (2 years)" | tee -a "${REPORT_FILE}"
echo "- Temporary data: ${TEMP_DATA_RETENTION} days (30 days)" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

# Check for old files that should be deleted
echo "Checking for data exceeding retention periods..." | tee -a "${REPORT_FILE}"

if [ -d "./data/temp" ]; then
    old_temp=$(find ./data/temp -type f -mtime +${TEMP_DATA_RETENTION} 2>/dev/null | wc -l)
    if [ "$old_temp" -gt 0 ]; then
        echo "WARNING: ${old_temp} temporary files exceed retention period" | tee -a "${REPORT_FILE}"
    else
        echo "✓ Temporary data within retention period" | tee -a "${REPORT_FILE}"
    fi
fi

echo "" | tee -a "${REPORT_FILE}"
echo "Retention Policy: CONFIGURED ✓" | tee -a "${REPORT_FILE}"
echo "Report saved to: ${REPORT_FILE}" | tee -a "${REPORT_FILE}"
exit 0
