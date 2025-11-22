#!/usr/bin/env bash

# Example: Batch Marking Workflow
# This script demonstrates a complete batch marking workflow

set -e

echo "===== AWS Batch Marking Workflow ====="
echo ""

# Configuration
SUBMISSIONS_DIR="${1:-./submissions}"
CONCURRENCY="${2:-5}"

echo "Configuration:"
echo "  Submissions directory: $SUBMISSIONS_DIR"
echo "  Concurrency: $CONCURRENCY"
echo ""

# Step 1: Check status
echo "Step 1: Checking AWS status..."
aws status

echo ""
read -p "Press Enter to continue..."
echo ""

# Step 2: Download new assignments (if Moodle is configured)
echo "Step 2: Syncing with Moodle..."
if aws sync --download --dry-run; then
    read -p "Download assignments? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        aws sync --download
    fi
fi

echo ""
read -p "Press Enter to continue..."
echo ""

# Step 3: Batch mark submissions
echo "Step 3: Batch marking submissions..."
if [ -d "$SUBMISSIONS_DIR" ]; then
    file_count=$(find "$SUBMISSIONS_DIR" -type f -name "*.pdf" | wc -l)
    echo "Found $file_count PDF files in $SUBMISSIONS_DIR"

    if [ "$file_count" -gt 0 ]; then
        read -p "Start batch marking? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            aws batch "$SUBMISSIONS_DIR" --pattern "*.pdf" --concurrency "$CONCURRENCY"
        fi
    else
        echo "No PDF files found. Skipping batch marking."
    fi
else
    echo "Submissions directory not found: $SUBMISSIONS_DIR"
    echo "Creating directory..."
    mkdir -p "$SUBMISSIONS_DIR"
    echo "Please add TMA files to $SUBMISSIONS_DIR and run this script again."
    exit 0
fi

echo ""
read -p "Press Enter to continue..."
echo ""

# Step 4: Review results
echo "Step 4: Reviewing results..."
echo "Feedback files are saved in .aws/feedback/"
ls -lh .aws/feedback/ 2>/dev/null || echo "No feedback files found"

echo ""
read -p "Press Enter to continue..."
echo ""

# Step 5: Upload to Moodle (optional)
echo "Step 5: Upload to Moodle..."
read -p "Upload feedback to Moodle? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Dry run first
    echo "Performing dry run..."
    aws sync --upload --dry-run

    echo ""
    read -p "Proceed with upload? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        aws sync --upload
    fi
fi

echo ""
echo "===== Workflow Complete ====="
echo ""
echo "Summary:"
echo "  - Marked files: $file_count"
echo "  - Feedback location: .aws/feedback/"
echo "  - Logs: .aws/logs/"
echo ""
echo "Next steps:"
echo "  - Review feedback: aws feedback <id>"
echo "  - Edit feedback: aws feedback <id> --edit"
echo "  - Check status: aws status"
