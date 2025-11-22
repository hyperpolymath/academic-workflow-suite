# AWS CLI Quick Reference

## Essential Commands

| Command | Description | Example |
|---------|-------------|---------|
| `aws init` | Initialize project | `aws init` |
| `aws start` | Start services | `aws start` |
| `aws stop` | Stop services | `aws stop` |
| `aws status` | Check status | `aws status` |
| `aws mark` | Mark a TMA | `aws mark file.pdf` |
| `aws batch` | Batch mark | `aws batch ./submissions` |
| `aws feedback` | View feedback | `aws feedback <id>` |

## Quick Start

```bash
# 1. Setup
aws init
aws start

# 2. Mark
aws mark --interactive

# 3. Review
aws feedback <id>
```

## Common Workflows

### Single TMA
```bash
aws mark submission.pdf --student S12345 --assignment TMA01
aws feedback <id> --edit
```

### Batch Marking
```bash
aws batch ./submissions --concurrency 10
```

### Moodle Sync
```bash
aws login --save
aws sync --download
aws batch .aws/submissions
aws sync --upload
```

## Global Options

| Option | Description |
|--------|-------------|
| `-v, --verbose` | Verbose output |
| `--no-color` | Disable colors |
| `--format json` | JSON output |
| `-h, --help` | Show help |

## Configuration

```bash
aws config show              # View config
aws config set key value     # Set value
aws config edit              # Interactive edit
```

### Common Config Keys
- `backend_url` - Backend API URL
- `moodle_url` - Moodle URL
- `auto_sync` - Enable auto-sync
- `ai_model` - AI model to use

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Services won't start | `aws doctor --fix` |
| Backend unreachable | `aws start` |
| Config issues | `aws config reset` |
| Moodle not connected | `aws login` |

## File Locations

| Path | Contents |
|------|----------|
| `.aws/config.yaml` | Configuration |
| `.aws/submissions/` | Downloaded TMAs |
| `.aws/feedback/` | Generated feedback |
| `.aws/logs/` | Application logs |

## Examples

```bash
# Initialize with name
aws init --name "CS101"

# Start in detached mode
aws start --detach

# Detailed status
aws status --detailed

# Interactive marking
aws mark --interactive

# Batch with pattern
aws batch ./submissions --pattern "*.pdf"

# Edit feedback
aws feedback abc123 --edit

# Export feedback
aws feedback abc123 --output report.txt

# Dry run sync
aws sync --dry-run

# Check for updates
aws update --check

# Run diagnostics
aws doctor
```

## Keyboard Shortcuts

(In interactive mode)

| Key | Action |
|-----|--------|
| `↑/↓` | Navigate |
| `Space` | Select |
| `Enter` | Confirm |
| `Esc` | Cancel |
| `Tab` | Autocomplete |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Invalid arguments |
| 3 | Configuration error |
| 4 | Service error |

## Environment Variables

```bash
export AWS_BACKEND_URL="http://localhost:8000"
export AWS_VERBOSE=1
export AWS_NO_COLOR=1
```

## Shell Completions

```bash
# Bash
source completions/aws.bash

# Zsh
source completions/_aws

# Fish
source completions/aws.fish
```

## Get Help

```bash
aws --help                   # General help
aws <command> --help         # Command help
aws config --help            # Config help
```

## Version Info

```bash
aws --version
```

## Links

- Full Documentation: `README.md`
- Examples: `examples/`
- Project: https://github.com/yourusername/academic-workflow-suite

---

**Tip**: Use `aws <command> --help` for detailed information on any command.
