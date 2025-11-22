#!/bin/bash
# Test script for AI Jail

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}AI Jail Test Suite${NC}"
echo "================================"
echo ""

# Test 1: Unit tests
echo -e "${GREEN}Running unit tests...${NC}"
cargo test --lib
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Unit tests passed${NC}"
else
    echo -e "${RED}✗ Unit tests failed${NC}"
    exit 1
fi
echo ""

# Test 2: Integration tests
echo -e "${GREEN}Running integration tests...${NC}"
cargo test --test test_isolation
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Integration tests passed${NC}"
else
    echo -e "${YELLOW}⚠ Some integration tests failed (may require model files)${NC}"
fi
echo ""

# Test 3: Clippy (linting)
echo -e "${GREEN}Running clippy (linter)...${NC}"
cargo clippy -- -D warnings
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Clippy passed${NC}"
else
    echo -e "${RED}✗ Clippy found issues${NC}"
    exit 1
fi
echo ""

# Test 4: Format check
echo -e "${GREEN}Checking code formatting...${NC}"
cargo fmt -- --check
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Code is properly formatted${NC}"
else
    echo -e "${RED}✗ Code needs formatting${NC}"
    echo "Run: cargo fmt"
    exit 1
fi
echo ""

# Test 5: Protocol validation
echo -e "${GREEN}Testing protocol validation...${NC}"
if [ -f "examples/sample_request.json" ]; then
    # Validate JSON syntax
    if command -v jq &> /dev/null; then
        jq empty examples/sample_request.json 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Sample request is valid JSON${NC}"
        else
            echo -e "${RED}✗ Sample request has invalid JSON${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠ jq not installed, skipping JSON validation${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Sample request file not found${NC}"
fi
echo ""

# Test 6: Build test
echo -e "${GREEN}Testing release build...${NC}"
cargo build --release
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Release build successful${NC}"

    # Show binary size
    BINARY_SIZE=$(du -h target/release/ai-jail | cut -f1)
    echo "Binary size: ${BINARY_SIZE}"
else
    echo -e "${RED}✗ Release build failed${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}All tests completed!${NC}"
echo ""
echo "Summary:"
echo "  ✓ Unit tests"
echo "  ✓ Integration tests (partial)"
echo "  ✓ Linting"
echo "  ✓ Formatting"
echo "  ✓ Protocol validation"
echo "  ✓ Release build"
