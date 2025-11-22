# AWS CLI Examples

This directory contains example scripts demonstrating common AWS CLI workflows.

## Available Examples

### 1. Setup Project (`setup-project.sh`)

Complete project setup from scratch, including initialization, configuration, and service startup.

**Usage:**
```bash
./setup-project.sh
```

**Features:**
- Interactive project configuration
- Service initialization
- Moodle authentication (optional)
- System diagnostics

### 2. Interactive Marking (`interactive-marking.sh`)

Demonstrates the interactive marking workflow for single TMAs.

**Usage:**
```bash
./interactive-marking.sh
```

**Features:**
- Service health check
- Interactive TMA marking wizard
- Guided feedback review

### 3. Batch Marking (`batch-marking.sh`)

Complete batch marking workflow for multiple TMAs.

**Usage:**
```bash
# Default (./submissions directory, concurrency: 5)
./batch-marking.sh

# Custom directory
./batch-marking.sh /path/to/submissions

# Custom directory and concurrency
./batch-marking.sh /path/to/submissions 10
```

**Features:**
- Moodle sync (download assignments)
- Batch marking with configurable concurrency
- Results review
- Moodle sync (upload feedback)

## Running Examples

All example scripts are executable:

```bash
# Make executable (if needed)
chmod +x *.sh

# Run any example
./<example-name>.sh
```

## Creating Custom Scripts

You can use these examples as templates for your own workflows. Common patterns:

### Check Service Status
```bash
if ! aws status &> /dev/null; then
    echo "Services not running"
    aws start
fi
```

### Conditional Moodle Sync
```bash
if aws sync --download --dry-run; then
    aws sync --download
fi
```

### Error Handling
```bash
set -e  # Exit on error

if ! aws mark submission.pdf; then
    echo "Marking failed"
    aws doctor --fix
    exit 1
fi
```

### Batch Processing with Loop
```bash
for file in submissions/*.pdf; do
    echo "Marking: $file"
    aws mark "$file" || echo "Failed: $file"
done
```

## Advanced Examples

### Automated Nightly Marking

Create a cron job for automated marking:

```bash
#!/bin/bash
# nightly-marking.sh

# Change to project directory
cd /path/to/project

# Sync and mark
aws sync --download
aws batch .aws/submissions --concurrency 10

# Send email notification (requires mail setup)
echo "Marking complete. Check .aws/feedback/" | mail -s "AWS Marking Report" admin@example.com
```

Add to crontab:
```bash
0 2 * * * /path/to/nightly-marking.sh
```

### Parallel Course Marking

Mark multiple courses in parallel:

```bash
#!/bin/bash
# multi-course-marking.sh

courses=("CS101" "CS201" "CS301")

for course in "${courses[@]}"; do
    (
        cd "$course"
        aws batch ./submissions --concurrency 5
    ) &
done

wait
echo "All courses marked"
```

### Export Reports

Generate marking reports:

```bash
#!/bin/bash
# generate-report.sh

OUTPUT="marking-report-$(date +%Y%m%d).txt"

{
    echo "Marking Report - $(date)"
    echo "================================"
    echo ""
    aws status --detailed
    echo ""
    echo "Feedback Files:"
    ls -lh .aws/feedback/
    echo ""
    echo "Statistics:"
    aws config get total_marked || echo "N/A"
} > "$OUTPUT"

echo "Report saved to: $OUTPUT"
```

## Integration with Other Tools

### Git Integration

Commit feedback after marking:

```bash
#!/bin/bash
aws batch ./submissions
git add .aws/feedback/
git commit -m "Add feedback for $(date +%Y-%m-%d)"
git push
```

### Backup Script

Backup feedback before uploading:

```bash
#!/bin/bash
BACKUP_DIR="backups/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"
cp -r .aws/feedback/* "$BACKUP_DIR/"
aws sync --upload
```

## Troubleshooting Examples

If scripts fail, try:

```bash
# Check AWS status
aws status --detailed

# Run diagnostics
aws doctor --fix

# Check logs
cat .aws/logs/*.log

# Restart services
aws stop --force
aws start
```

## Contributing

To contribute new examples:

1. Create a descriptive script name
2. Add proper error handling
3. Include comments explaining each step
4. Update this README
5. Make the script executable
6. Test thoroughly

## Support

For issues with examples:
- Check the main CLI README
- Run `aws doctor`
- Review `.aws/logs/`
- Open an issue on GitHub
