#!/bin/bash
# Build script for AI Jail container

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

echo -e "${GREEN}Building AI Jail Container${NC}"
echo "================================"
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Runtime: ${CONTAINER_RUNTIME}"
echo ""

# Check if container runtime is available
if ! command -v "${CONTAINER_RUNTIME}" &> /dev/null; then
    echo -e "${RED}Error: ${CONTAINER_RUNTIME} is not installed${NC}"
    echo "Please install ${CONTAINER_RUNTIME} first"
    exit 1
fi

# Check if Rust is available for local builds
if ! command -v cargo &> /dev/null; then
    echo -e "${YELLOW}Warning: Rust/Cargo not found${NC}"
    echo "Skipping local build test"
else
    echo -e "${GREEN}Testing local build...${NC}"
    cargo build --release
    echo -e "${GREEN}✓ Local build successful${NC}"
    echo ""
fi

# Build container image
echo -e "${GREEN}Building container image...${NC}"
"${CONTAINER_RUNTIME}" build \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    -f Containerfile \
    .

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Container image built successfully${NC}"
    echo ""
    echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"

    # Show image size
    echo ""
    echo "Image details:"
    "${CONTAINER_RUNTIME}" images "${IMAGE_NAME}:${IMAGE_TAG}"

    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo "1. Download model files to /models/mistral-7b/"
    echo "2. Run: ./run.sh"
else
    echo -e "${RED}✗ Container build failed${NC}"
    exit 1
fi
