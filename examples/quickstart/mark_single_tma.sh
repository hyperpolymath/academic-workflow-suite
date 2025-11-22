#!/bin/bash
# Quick Start: Mark a Single TMA via CLI
# This script demonstrates how to submit a TMA for automated marking

set -e

# Configuration
API_URL="${AWS_API_URL:-http://localhost:8080}"
TMA_FILE="${1:-sample_tma.pdf}"
RUBRIC="${2:-default}"
STUDENT_ID="${3:-student001}"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Academic Workflow Suite - Quick Start${NC}"
echo -e "${BLUE}======================================${NC}\n"

# Check if TMA file exists
if [ ! -f "$TMA_FILE" ]; then
    echo -e "${RED}Error: TMA file not found: $TMA_FILE${NC}"
    echo "Usage: $0 <tma_file.pdf> [rubric] [student_id]"
    exit 1
fi

echo -e "${GREEN}Step 1:${NC} Uploading TMA..."
UPLOAD_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/tma/upload" \
    -F "file=@$TMA_FILE" \
    -F "student_id=$STUDENT_ID" \
    -F "rubric=$RUBRIC")

TMA_ID=$(echo "$UPLOAD_RESPONSE" | jq -r '.tma_id')

if [ "$TMA_ID" == "null" ] || [ -z "$TMA_ID" ]; then
    echo -e "${RED}Error: Failed to upload TMA${NC}"
    echo "$UPLOAD_RESPONSE" | jq .
    exit 1
fi

echo -e "${GREEN}✓ TMA uploaded successfully${NC}"
echo "  TMA ID: $TMA_ID"

echo -e "\n${GREEN}Step 2:${NC} Submitting for marking..."
MARK_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/tma/$TMA_ID/mark" \
    -H "Content-Type: application/json" \
    -d '{"rubric": "'"$RUBRIC"'", "auto_feedback": true}')

JOB_ID=$(echo "$MARK_RESPONSE" | jq -r '.job_id')

echo -e "${GREEN}✓ Marking job submitted${NC}"
echo "  Job ID: $JOB_ID"

echo -e "\n${GREEN}Step 3:${NC} Waiting for results..."
TIMEOUT=300
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    STATUS_RESPONSE=$(curl -s "$API_URL/api/v1/jobs/$JOB_ID")
    STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.status')

    if [ "$STATUS" == "completed" ]; then
        echo -e "${GREEN}✓ Marking completed!${NC}\n"

        # Get results
        RESULT=$(curl -s "$API_URL/api/v1/tma/$TMA_ID/results")

        echo -e "${BLUE}Results:${NC}"
        echo "========"
        echo "$RESULT" | jq '{
            score: .score,
            grade: .grade,
            feedback_summary: .feedback.summary,
            strengths: .feedback.strengths,
            areas_for_improvement: .feedback.areas_for_improvement
        }'

        # Save detailed feedback
        FEEDBACK_FILE="${TMA_FILE%.pdf}_feedback.json"
        echo "$RESULT" | jq . > "$FEEDBACK_FILE"
        echo -e "\n${GREEN}Full feedback saved to:${NC} $FEEDBACK_FILE"

        exit 0
    elif [ "$STATUS" == "failed" ]; then
        echo -e "${RED}✗ Marking failed${NC}"
        echo "$STATUS_RESPONSE" | jq .
        exit 1
    fi

    echo -n "."
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

echo -e "\n${RED}Timeout: Marking took too long${NC}"
exit 1
