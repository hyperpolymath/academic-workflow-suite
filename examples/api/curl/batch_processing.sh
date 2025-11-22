#!/bin/bash
# Example: Batch process multiple TMAs using cURL
# This demonstrates submitting multiple TMAs and tracking their progress

set -e

# Configuration
API_URL="${AWS_API_URL:-http://localhost:8080}"
TMA_DIR="${1:-.}"
RUBRIC="${RUBRIC:-default}"

echo "Batch Process TMAs via cURL Example"
echo "===================================="
echo ""

# Create tracking file
BATCH_FILE="batch_jobs_$(date +%Y%m%d_%H%M%S).json"
echo "[]" > "$BATCH_FILE"

# Find and submit all PDFs
for tma_file in "$TMA_DIR"/*.pdf; do
    [ -f "$tma_file" ] || continue

    student_id=$(basename "$tma_file" .pdf)

    echo "Submitting: $tma_file (Student: $student_id)"

    # Upload
    upload_response=$(curl -s -X POST "$API_URL/api/v1/tma/upload" \
        -F "file=@$tma_file" \
        -F "student_id=$student_id" \
        -F "rubric=$RUBRIC")

    tma_id=$(echo "$upload_response" | jq -r '.tma_id')

    if [ "$tma_id" == "null" ]; then
        echo "  Failed to upload"
        continue
    fi

    # Submit for marking
    mark_response=$(curl -s -X POST "$API_URL/api/v1/tma/$tma_id/mark" \
        -H "Content-Type: application/json" \
        -d '{"rubric": "'"$RUBRIC"'", "auto_feedback": true}')

    job_id=$(echo "$mark_response" | jq -r '.job_id')

    if [ "$job_id" == "null" ]; then
        echo "  Failed to submit for marking"
        continue
    fi

    # Track the job
    jq --arg student_id "$student_id" \
       --arg tma_id "$tma_id" \
       --arg job_id "$job_id" \
       '. += [{student_id: $student_id, tma_id: $tma_id, job_id: $job_id, status: "submitted"}]' \
       "$BATCH_FILE" > "${BATCH_FILE}.tmp" && mv "${BATCH_FILE}.tmp" "$BATCH_FILE"

    echo "  Submitted: Job ID $job_id, TMA ID $tma_id"
done

echo ""
echo "All TMAs submitted!"
echo "Tracking file: $BATCH_FILE"
echo ""

# Monitor progress
echo "Monitoring progress..."
echo ""

total=$(jq 'length' "$BATCH_FILE")
completed=0

while [ $completed -lt $total ]; do
    completed=0
    failed=0

    # Update status for each job
    jobs=$(jq -c '.[]' "$BATCH_FILE")

    while IFS= read -r job; do
        job_id=$(echo "$job" | jq -r '.job_id')
        current_status=$(echo "$job" | jq -r '.status')

        if [ "$current_status" == "completed" ] || [ "$current_status" == "failed" ]; then
            [ "$current_status" == "completed" ] && ((completed++)) || ((failed++))
            continue
        fi

        # Check status
        status_response=$(curl -s "$API_URL/api/v1/jobs/$job_id")
        status=$(echo "$status_response" | jq -r '.status')

        if [ "$status" == "completed" ] || [ "$status" == "failed" ]; then
            # Update tracking file
            jq --arg job_id "$job_id" --arg status "$status" \
               'map(if .job_id == $job_id then .status = $status else . end)' \
               "$BATCH_FILE" > "${BATCH_FILE}.tmp" && mv "${BATCH_FILE}.tmp" "$BATCH_FILE"

            student_id=$(echo "$job" | jq -r '.student_id')
            echo "  $student_id: $status"

            [ "$status" == "completed" ] && ((completed++)) || ((failed++))
        fi
    done <<< "$jobs"

    echo "Progress: $completed/$total completed, $failed failed"

    if [ $completed -lt $total ]; then
        sleep 10
    fi
done

echo ""
echo "All jobs completed!"
echo ""
echo "Fetching results..."
echo ""

# Create results directory
results_dir="batch_results_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$results_dir"

# Fetch results for completed jobs
jq -c '.[] | select(.status == "completed")' "$BATCH_FILE" | while IFS= read -r job; do
    student_id=$(echo "$job" | jq -r '.student_id')
    tma_id=$(echo "$job" | jq -r '.tma_id')

    results=$(curl -s "$API_URL/api/v1/tma/$tma_id/results")
    echo "$results" | jq . > "$results_dir/${student_id}_results.json"

    score=$(echo "$results" | jq -r '.score')
    grade=$(echo "$results" | jq -r '.grade')

    echo "$student_id: Score $score, Grade $grade"
done

# Create summary CSV
echo "student_id,score,grade" > "$results_dir/summary.csv"
jq -c '.[] | select(.status == "completed")' "$BATCH_FILE" | while IFS= read -r job; do
    student_id=$(echo "$job" | jq -r '.student_id')
    tma_id=$(echo "$job" | jq -r '.tma_id')

    results=$(curl -s "$API_URL/api/v1/tma/$tma_id/results")
    score=$(echo "$results" | jq -r '.score')
    grade=$(echo "$results" | jq -r '.grade')

    echo "$student_id,$score,$grade" >> "$results_dir/summary.csv"
done

echo ""
echo "Results saved to: $results_dir"
echo "  - summary.csv: Summary of all results"
echo "  - *_results.json: Individual result files"
