#!/bin/bash
# Daily Moodle Sync - Cron Job
# Schedule: 0 2 * * * (2 AM daily)

set -e

# Configuration
MOODLE_URL="${MOODLE_URL:-https://moodle.example.com}"
AWAP_API_URL="${AWAP_API_URL:-http://localhost:8080}"
LOG_DIR="/var/log/awap"
LOG_FILE="$LOG_DIR/daily_sync_$(date +%Y%m%d).log"

# Create log directory
mkdir -p "$LOG_DIR"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting daily Moodle sync"

# Get new submissions from Moodle
log "Fetching new submissions from Moodle"
NEW_SUBMISSIONS=$(curl -s "$MOODLE_URL/webservice/rest/server.php" \
    -d "wstoken=$MOODLE_TOKEN" \
    -d "wsfunction=mod_assign_get_submissions" \
    -d "moodlewsrestformat=json" \
    | jq -r '.[] | select(.status == "submitted") | select(.graded == false)')

# Process each submission
PROCESSED=0
FAILED=0

echo "$NEW_SUBMISSIONS" | jq -c '.' | while read -r submission; do
    student_id=$(echo "$submission" | jq -r '.userid')
    assignment_id=$(echo "$submission" | jq -r '.assignment')

    log "Processing submission: Student $student_id, Assignment $assignment_id"

    # Download submission file
    file_url=$(echo "$submission" | jq -r '.plugins[0].fileareas[0].files[0].fileurl')

    # Submit to AWAP
    result=$(curl -s -X POST "$AWAP_API_URL/api/v1/tma/upload" \
        -F "file_url=$file_url" \
        -F "student_id=moodle_$student_id" \
        -F "rubric=default")

    if [ $? -eq 0 ]; then
        ((PROCESSED++))
        log "  ✓ Successfully processed"
    else
        ((FAILED++))
        log "  ✗ Failed to process"
    fi
done

log "Sync completed: $PROCESSED processed, $FAILED failed"

# Cleanup old logs (keep 30 days)
find "$LOG_DIR" -name "daily_sync_*.log" -mtime +30 -delete

# Send summary email if failures
if [ $FAILED -gt 0 ]; then
    mail -s "AWAP Daily Sync: $FAILED failures" admin@example.com < "$LOG_FILE"
fi
