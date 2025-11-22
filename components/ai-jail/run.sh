#!/bin/bash
# Run script for AI Jail container

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="${IMAGE_NAME:-ai-jail}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-podman}"
MODELS_DIR="${MODELS_DIR:-/models}"

# Security options
NETWORK_MODE="none"
SECURITY_OPTS="no-new-privileges"
CAP_DROP="ALL"

# Resource limits
MEMORY_LIMIT="${MEMORY_LIMIT:-10g}"
CPU_SHARES="${CPU_SHARES:-1024}"

echo -e "${GREEN}Running AI Jail Container${NC}"
echo "================================"
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Models: ${MODELS_DIR}"
echo "Network: ${NETWORK_MODE}"
echo "Memory Limit: ${MEMORY_LIMIT}"
echo ""

# Validate models directory
if [ ! -d "${MODELS_DIR}" ]; then
    echo -e "${RED}Error: Models directory not found: ${MODELS_DIR}${NC}"
    echo "Please create the directory and download model files"
    exit 1
fi

if [ ! -d "${MODELS_DIR}/mistral-7b" ]; then
    echo -e "${YELLOW}Warning: Mistral 7B directory not found${NC}"
    echo "Expected: ${MODELS_DIR}/mistral-7b/"
    echo ""
fi

# Check if model files exist
MODEL_FILE="${MODELS_DIR}/mistral-7b/model.safetensors"
TOKENIZER_FILE="${MODELS_DIR}/mistral-7b/tokenizer.json"

if [ ! -f "${MODEL_FILE}" ]; then
    echo -e "${YELLOW}Warning: Model file not found: ${MODEL_FILE}${NC}"
fi

if [ ! -f "${TOKENIZER_FILE}" ]; then
    echo -e "${YELLOW}Warning: Tokenizer file not found: ${TOKENIZER_FILE}${NC}"
fi

# Check if image exists
if ! "${CONTAINER_RUNTIME}" image exists "${IMAGE_NAME}:${IMAGE_TAG}"; then
    echo -e "${RED}Error: Image not found: ${IMAGE_NAME}:${IMAGE_TAG}${NC}"
    echo "Please build the image first: ./build.sh"
    exit 1
fi

echo -e "${GREEN}Starting container...${NC}"
echo "Send JSON requests to stdin, receive responses on stdout"
echo "Press Ctrl+D to stop"
echo ""

# Run container with security restrictions
"${CONTAINER_RUNTIME}" run \
    --rm \
    -i \
    --network="${NETWORK_MODE}" \
    --security-opt="${SECURITY_OPTS}" \
    --cap-drop="${CAP_DROP}" \
    --memory="${MEMORY_LIMIT}" \
    --cpu-shares="${CPU_SHARES}" \
    -v "${MODELS_DIR}:/models:ro" \
    -e RUST_LOG="${RUST_LOG:-info}" \
    "${IMAGE_NAME}:${IMAGE_TAG}"

echo ""
echo -e "${GREEN}Container stopped${NC}"
