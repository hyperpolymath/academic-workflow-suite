#!/bin/bash
# Example: Submit a TMA using cURL
# This demonstrates the raw HTTP API calls for submitting a TMA

set -e

# Configuration
API_URL="${AWS_API_URL:-http://localhost:8080}"
TMA_FILE="${1:-essay.pdf}"
STUDENT_ID="${2:-student001}"
RUBRIC="${3:-default}"

echo "Submit TMA via cURL Example"
echo "============================"
echo ""

# Check if file exists
if [ ! -f "$TMA_FILE" ]; then
    echo "Error: File not found: $TMA_FILE"
    exit 1
fi

echo "Step 1: Upload TMA"
echo "  File: $TMA_FILE"
echo "  Student ID: $STUDENT_ID"
echo "  Rubric: $RUBRIC"
echo ""

# Upload TMA
UPLOAD_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/tma/upload" \
    -F "file=@$TMA_FILE" \
    -F "student_id=$STUDENT_ID" \
    -F "rubric=$RUBRIC")

echo "Upload Response:"
echo "$UPLOAD_RESPONSE" | jq .
echo ""

# Extract TMA ID
TMA_ID=$(echo "$UPLOAD_RESPONSE" | jq -r '.tma_id')

if [ "$TMA_ID" == "null" ] || [ -z "$TMA_ID" ]; then
    echo "Error: Upload failed"
    exit 1
fi

echo "TMA uploaded successfully!"
echo "TMA ID: $TMA_ID"
echo ""

echo "Step 2: Submit for marking"
echo ""

# Submit for marking
MARK_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/tma/$TMA_ID/mark" \
    -H "Content-Type: application/json" \
    -d '{
        "rubric": "'"$RUBRIC"'",
        "auto_feedback": true
    }')

echo "Marking Response:"
echo "$MARK_RESPONSE" | jq .
echo ""

# Extract job ID
JOB_ID=$(echo "$MARK_RESPONSE" | jq -r '.job_id')

if [ "$JOB_ID" == "null" ] || [ -z "$JOB_ID" ]; then
    echo "Error: Marking submission failed"
    exit 1
fi

echo "Marking job submitted successfully!"
echo "Job ID: $JOB_ID"
echo "TMA ID: $TMA_ID"
echo ""
echo "Use get_feedback.sh to check the results:"
echo "  ./get_feedback.sh $JOB_ID $TMA_ID"
