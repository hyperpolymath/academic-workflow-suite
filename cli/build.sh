#!/usr/bin/env bash

# AWS CLI Build Script
# Builds the CLI and optionally installs it

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BINARY_NAME="aws"
BUILD_MODE="release"
INSTALL=false
INSTALL_PATH="/usr/local/bin"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            BUILD_MODE="debug"
            shift
            ;;
        --install)
            INSTALL=true
            shift
            ;;
        --install-path)
            INSTALL_PATH="$2"
            shift 2
            ;;
        --help)
            echo "AWS CLI Build Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --debug              Build in debug mode (default: release)"
            echo "  --install            Install after building"
            echo "  --install-path PATH  Installation path (default: /usr/local/bin)"
            echo "  --help               Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}AWS CLI Build Script${NC}"
echo ""

# Check for Rust/Cargo
if ! command -v cargo &> /dev/null; then
    echo -e "${RED}Error: cargo not found. Please install Rust.${NC}"
    echo "Visit: https://rustup.rs/"
    exit 1
fi

echo -e "${GREEN}✓ Rust/Cargo found${NC}"

# Show build configuration
echo ""
echo "Build configuration:"
echo "  Mode: $BUILD_MODE"
echo "  Binary: $BINARY_NAME"
if [ "$INSTALL" = true ]; then
    echo "  Install: Yes ($INSTALL_PATH)"
else
    echo "  Install: No"
fi
echo ""

# Build
echo -e "${YELLOW}Building...${NC}"

if [ "$BUILD_MODE" = "release" ]; then
    cargo build --release
    BINARY_PATH="target/release/$BINARY_NAME"
else
    cargo build
    BINARY_PATH="target/debug/$BINARY_NAME"
fi

if [ ! -f "$BINARY_PATH" ]; then
    echo -e "${RED}Error: Build failed - binary not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Build complete${NC}"

# Show binary info
BINARY_SIZE=$(du -h "$BINARY_PATH" | cut -f1)
echo ""
echo "Binary information:"
echo "  Path: $BINARY_PATH"
echo "  Size: $BINARY_SIZE"
echo ""

# Test the binary
echo -e "${YELLOW}Testing binary...${NC}"
if "$BINARY_PATH" --version &> /dev/null; then
    VERSION=$("$BINARY_PATH" --version)
    echo -e "${GREEN}✓ Binary works: $VERSION${NC}"
else
    echo -e "${RED}Error: Binary test failed${NC}"
    exit 1
fi

# Install if requested
if [ "$INSTALL" = true ]; then
    echo ""
    echo -e "${YELLOW}Installing...${NC}"

    if [ -w "$INSTALL_PATH" ]; then
        cp "$BINARY_PATH" "$INSTALL_PATH/$BINARY_NAME"
        chmod +x "$INSTALL_PATH/$BINARY_NAME"
    else
        echo "Installing to $INSTALL_PATH requires sudo..."
        sudo cp "$BINARY_PATH" "$INSTALL_PATH/$BINARY_NAME"
        sudo chmod +x "$INSTALL_PATH/$BINARY_NAME"
    fi

    echo -e "${GREEN}✓ Installed to $INSTALL_PATH/$BINARY_NAME${NC}"
fi

# Summary
echo ""
echo -e "${GREEN}Build complete!${NC}"
echo ""

if [ "$INSTALL" = true ]; then
    echo "Next steps:"
    echo "  1. Run: $BINARY_NAME --help"
    echo "  2. Initialize a project: $BINARY_NAME init"
else
    echo "Next steps:"
    echo "  1. Test: $BINARY_PATH --help"
    echo "  2. Install: ./build.sh --install"
    echo "  3. Or run directly: $BINARY_PATH init"
fi

echo ""
echo "Generate shell completions:"
echo "  cd completions && ./generate_completions.sh"
echo ""
