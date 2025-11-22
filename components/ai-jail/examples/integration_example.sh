#!/bin/bash
# Example integration script showing how to use AI Jail from another component

set -euo pipefail

# Configuration
CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-podman}"
IMAGE_NAME="ai-jail:latest"
MODELS_DIR="${MODELS_DIR:-/models}"

# Request template
create_request() {
    local tma_content="$1"
    local rubric="$2"
    local question_number="$3"
    local student_answer="${4:-}"

    cat <<EOF
{
  "tma_content": "${tma_content}",
  "rubric": "${rubric}",
  "question_number": ${question_number},
  "student_answer": ${student_answer:+\"$student_answer\"},
  "max_tokens": 512,
  "temperature": 0.7,
  "top_p": 0.9
}
EOF
}

# Start AI Jail container
start_jail() {
    echo "Starting AI Jail container..."

    ${CONTAINER_RUNTIME} run \
        --rm \
        -i \
        --name ai-jail-session \
        --network=none \
        --security-opt=no-new-privileges \
        --cap-drop=ALL \
        --memory=10g \
        -v "${MODELS_DIR}:/models:ro" \
        -e RUST_LOG=info \
        "${IMAGE_NAME}"
}

# Send request and get response
send_request() {
    local request="$1"

    echo "Sending request:"
    echo "${request}" | jq .
    echo ""

    # Send to AI Jail and parse response
    response=$(echo "${request}" | start_jail)

    echo "Received response:"
    echo "${response}" | jq .
    echo ""

    # Extract feedback
    feedback=$(echo "${response}" | jq -r '.feedback // .message')
    confidence=$(echo "${response}" | jq -r '.confidence // 0')

    echo "Feedback: ${feedback}"
    echo "Confidence: ${confidence}"

    return 0
}

# Example usage
main() {
    echo "AI Jail Integration Example"
    echo "==========================="
    echo ""

    # Example 1: Basic request
    echo "Example 1: Basic TMA grading"
    echo "-----------------------------"

    request=$(create_request \
        "Explain the water cycle." \
        "Award 5 marks for covering evaporation, condensation, and precipitation." \
        1 \
        "Water evaporates from oceans, forms clouds, and falls as rain.")

    send_request "${request}"

    echo ""
    echo "Integration example complete!"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
