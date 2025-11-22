#!/bin/bash
# Batch Mark Multiple TMAs
# This script demonstrates how to process multiple TMAs in parallel

set -e

# Configuration
API_URL="${AWS_API_URL:-http://localhost:8080}"
RUBRIC="${RUBRIC:-default}"
TMA_DIR="${1:-.}"
MAX_CONCURRENT="${MAX_CONCURRENT:-3}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Academic Workflow Suite - Batch Marking${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Create output directory
OUTPUT_DIR="batch_results_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"
LOG_FILE="$OUTPUT_DIR/batch.log"

echo -e "${GREEN}Configuration:${NC}"
echo "  TMA Directory: $TMA_DIR"
echo "  Output Directory: $OUTPUT_DIR"
echo "  Rubric: $RUBRIC"
echo "  Max Concurrent Jobs: $MAX_CONCURRENT"
echo "  API URL: $API_URL"
echo ""

# Function to mark a single TMA
mark_tma() {
    local tma_file="$1"
    local student_id=$(basename "$tma_file" .pdf)
    local log_prefix="[$student_id]"

    echo "$log_prefix Starting..." | tee -a "$LOG_FILE"

    # Upload TMA
    upload_response=$(curl -s -X POST "$API_URL/api/v1/tma/upload" \
        -F "file=@$tma_file" \
        -F "student_id=$student_id" \
        -F "rubric=$RUBRIC" 2>&1)

    tma_id=$(echo "$upload_response" | jq -r '.tma_id' 2>/dev/null)

    if [ "$tma_id" == "null" ] || [ -z "$tma_id" ]; then
        echo "$log_prefix ${RED}Upload failed${NC}" | tee -a "$LOG_FILE"
        echo "$upload_response" >> "$OUTPUT_DIR/${student_id}_error.log"
        return 1
    fi

    echo "$log_prefix Uploaded (TMA ID: $tma_id)" | tee -a "$LOG_FILE"

    # Submit for marking
    mark_response=$(curl -s -X POST "$API_URL/api/v1/tma/$tma_id/mark" \
        -H "Content-Type: application/json" \
        -d '{"rubric": "'"$RUBRIC"'", "auto_feedback": true}' 2>&1)

    job_id=$(echo "$mark_response" | jq -r '.job_id' 2>/dev/null)

    if [ "$job_id" == "null" ] || [ -z "$job_id" ]; then
        echo "$log_prefix ${RED}Marking submission failed${NC}" | tee -a "$LOG_FILE"
        echo "$mark_response" >> "$OUTPUT_DIR/${student_id}_error.log"
        return 1
    fi

    echo "$log_prefix Submitted for marking (Job ID: $job_id)" | tee -a "$LOG_FILE"

    # Wait for completion
    timeout=300
    elapsed=0
    while [ $elapsed -lt $timeout ]; do
        status_response=$(curl -s "$API_URL/api/v1/jobs/$job_id" 2>&1)
        status=$(echo "$status_response" | jq -r '.status' 2>/dev/null)

        if [ "$status" == "completed" ]; then
            echo "$log_prefix ${GREEN}Completed${NC}" | tee -a "$LOG_FILE"

            # Get results
            result=$(curl -s "$API_URL/api/v1/tma/$tma_id/results" 2>&1)
            echo "$result" | jq . > "$OUTPUT_DIR/${student_id}_feedback.json"

            # Extract score and grade
            score=$(echo "$result" | jq -r '.score' 2>/dev/null)
            grade=$(echo "$result" | jq -r '.grade' 2>/dev/null)

            echo "$student_id,$score,$grade,completed" >> "$OUTPUT_DIR/summary.csv"
            echo "$log_prefix Score: $score, Grade: $grade" | tee -a "$LOG_FILE"

            return 0
        elif [ "$status" == "failed" ]; then
            echo "$log_prefix ${RED}Marking failed${NC}" | tee -a "$LOG_FILE"
            echo "$status_response" >> "$OUTPUT_DIR/${student_id}_error.log"
            echo "$student_id,,,failed" >> "$OUTPUT_DIR/summary.csv"
            return 1
        fi

        sleep 5
        elapsed=$((elapsed + 5))
    done

    echo "$log_prefix ${YELLOW}Timeout${NC}" | tee -a "$LOG_FILE"
    echo "$student_id,,,timeout" >> "$OUTPUT_DIR/summary.csv"
    return 1
}

export -f mark_tma
export API_URL RUBRIC OUTPUT_DIR LOG_FILE GREEN RED YELLOW NC

# Find all PDF files
tma_files=()
while IFS= read -r -d '' file; do
    tma_files+=("$file")
done < <(find "$TMA_DIR" -maxdepth 1 -name "*.pdf" -print0)

total=${#tma_files[@]}

if [ $total -eq 0 ]; then
    echo -e "${RED}No PDF files found in $TMA_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}Found $total TMA files to process${NC}\n"

# Create CSV header
echo "student_id,score,grade,status" > "$OUTPUT_DIR/summary.csv"

# Process files in parallel
echo -e "${BLUE}Processing TMAs...${NC}\n"
printf '%s\n' "${tma_files[@]}" | xargs -P "$MAX_CONCURRENT" -I {} bash -c 'mark_tma "$@"' _ {}

echo -e "\n${BLUE}Batch Processing Complete${NC}"
echo -e "${BLUE}=========================${NC}\n"

# Generate summary report
completed=$(grep -c ",completed$" "$OUTPUT_DIR/summary.csv" || true)
failed=$(grep -c ",failed$" "$OUTPUT_DIR/summary.csv" || true)
timeout=$(grep -c ",timeout$" "$OUTPUT_DIR/summary.csv" || true)

echo -e "${GREEN}Summary:${NC}"
echo "  Total TMAs: $total"
echo "  Completed: $completed"
echo "  Failed: $failed"
echo "  Timeout: $timeout"
echo ""
echo -e "${GREEN}Results saved to:${NC} $OUTPUT_DIR"
echo "  - summary.csv: Overall results"
echo "  - *_feedback.json: Individual feedback files"
echo "  - batch.log: Processing log"

# Display score distribution if any completed
if [ $completed -gt 0 ]; then
    echo -e "\n${BLUE}Score Distribution:${NC}"
    awk -F',' 'NR>1 && $4=="completed" {print $2}' "$OUTPUT_DIR/summary.csv" | \
        sort -n | \
        awk '{sum+=$1; if(NR==1){min=$1} max=$1} END {
            printf "  Min: %.1f\n  Max: %.1f\n  Avg: %.1f\n", min, max, sum/NR
        }'
fi
