#!/bin/bash
# Example: Get feedback for a TMA using cURL
# This demonstrates checking job status and retrieving results

set -e

# Configuration
API_URL="${AWS_API_URL:-http://localhost:8080}"
JOB_ID="${1}"
TMA_ID="${2}"

if [ -z "$JOB_ID" ] || [ -z "$TMA_ID" ]; then
    echo "Usage: $0 <job_id> <tma_id>"
    exit 1
fi

echo "Get TMA Feedback via cURL Example"
echo "=================================="
echo ""
echo "Job ID: $JOB_ID"
echo "TMA ID: $TMA_ID"
echo ""

# Poll for completion
echo "Polling for completion..."
TIMEOUT=300
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    # Check job status
    STATUS_RESPONSE=$(curl -s "$API_URL/api/v1/jobs/$JOB_ID")
    STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.status')

    if [ "$STATUS" == "completed" ]; then
        echo ""
        echo "Job completed!"
        echo ""
        break
    elif [ "$STATUS" == "failed" ]; then
        echo ""
        echo "Job failed!"
        echo "$STATUS_RESPONSE" | jq .
        exit 1
    fi

    echo -n "."
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo ""
    echo "Timeout: Job did not complete in time"
    exit 1
fi

# Get results
echo "Fetching results..."
echo ""

RESULTS=$(curl -s "$API_URL/api/v1/tma/$TMA_ID/results")

echo "Results:"
echo "========"
echo "$RESULTS" | jq .
echo ""

# Display summary
echo "Summary:"
echo "--------"
echo "Score: $(echo "$RESULTS" | jq -r '.score')"
echo "Grade: $(echo "$RESULTS" | jq -r '.grade')"
echo ""

echo "Feedback Summary:"
echo "$RESULTS" | jq -r '.feedback.summary'
echo ""

echo "Strengths:"
echo "$RESULTS" | jq -r '.feedback.strengths[]' | sed 's/^/  • /'
echo ""

echo "Areas for Improvement:"
echo "$RESULTS" | jq -r '.feedback.areas_for_improvement[]' | sed 's/^/  • /'
echo ""

# Save to file
OUTPUT_FILE="tma_${TMA_ID}_results.json"
echo "$RESULTS" | jq . > "$OUTPUT_FILE"
echo "Full results saved to: $OUTPUT_FILE"
