#!/usr/bin/env bash

# Example: Interactive Marking Workflow
# This script demonstrates interactive marking of a single TMA

set -e

echo "===== AWS Interactive Marking ====="
echo ""

# Step 1: Check if services are running
echo "Checking AWS services..."
if ! aws status &> /dev/null; then
    echo "AWS services are not running."
    read -p "Start services now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        aws start
        echo "Waiting for services to be ready..."
        sleep 5
    else
        echo "Please start services with: aws start"
        exit 1
    fi
fi

aws status

echo ""
read -p "Press Enter to start interactive marking..."
echo ""

# Step 2: Interactive marking
echo "Starting interactive marking wizard..."
aws mark --interactive

echo ""
echo "===== Marking Complete ====="
echo ""
echo "View feedback files in: .aws/feedback/"
echo ""
echo "Next steps:"
echo "  - Review feedback: ls .aws/feedback/"
echo "  - Edit feedback: aws feedback <id> --edit"
echo "  - Mark another: aws mark --interactive"
echo "  - Upload to Moodle: aws sync --upload"
