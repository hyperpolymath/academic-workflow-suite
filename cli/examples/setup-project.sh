#!/usr/bin/env bash

# Example: Complete Project Setup
# This script sets up a new AWS project from scratch

set -e

echo "===== AWS Project Setup ====="
echo ""

# Get project information
read -p "Enter project name (default: My Course): " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-"My Course"}

read -p "Enter backend URL (default: http://localhost:8000): " BACKEND_URL
BACKEND_URL=${BACKEND_URL:-"http://localhost:8000"}

read -p "Enter Moodle URL (optional, press Enter to skip): " MOODLE_URL

echo ""
echo "Configuration:"
echo "  Project: $PROJECT_NAME"
echo "  Backend: $BACKEND_URL"
if [ -n "$MOODLE_URL" ]; then
    echo "  Moodle: $MOODLE_URL"
fi
echo ""

read -p "Proceed with setup? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

# Step 1: Initialize AWS
echo ""
echo "Step 1: Initializing AWS..."
aws init --name "$PROJECT_NAME" --yes

# Step 2: Configure settings
echo ""
echo "Step 2: Configuring settings..."
aws config set backend_url "$BACKEND_URL"

if [ -n "$MOODLE_URL" ]; then
    aws config set moodle_url "$MOODLE_URL"
fi

# Step 3: Show configuration
echo ""
echo "Step 3: Verifying configuration..."
aws config show

# Step 4: Start services
echo ""
read -p "Start AWS services now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting services..."
    aws start --detach
    echo "Services started in detached mode"
fi

# Step 5: Moodle login (if configured)
if [ -n "$MOODLE_URL" ]; then
    echo ""
    read -p "Login to Moodle now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        aws login --save
    fi
fi

# Step 6: Run diagnostics
echo ""
echo "Step 6: Running diagnostics..."
aws doctor

# Summary
echo ""
echo "===== Setup Complete ====="
echo ""
echo "Project initialized successfully!"
echo ""
echo "Next steps:"
echo "  1. Check status: aws status"
echo "  2. Mark a TMA: aws mark --interactive"
echo "  3. Sync with Moodle: aws sync --download"
echo "  4. Batch mark: aws batch ./submissions"
echo ""
echo "For help: aws --help"
echo "Documentation: cat README.md"
