# AWS CLI - Academic Workflow Suite Command-Line Interface

A powerful, user-friendly command-line interface for the Academic Workflow Suite, designed to streamline academic marking workflows for educators and tutors.

## Features

- **Intuitive Commands** - Simple, clear commands for all workflows
- **Interactive Mode** - Guided workflows for new users
- **Batch Processing** - Mark multiple TMAs concurrently
- **Moodle Integration** - Seamless sync with Moodle LMS
- **Rich Output** - Colorized output with progress indicators
- **Shell Completions** - Tab completion for bash, zsh, fish, and PowerShell
- **Configurable** - Flexible configuration management
- **Self-Diagnostic** - Built-in health checks and issue detection

## Installation

### Prerequisites

- Rust 1.70 or later (for building from source)
- Docker and Docker Compose (for running services)
- Git

### Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/academic-workflow-suite.git
cd academic-workflow-suite/cli

# Build the CLI
cargo build --release

# Install to system path
sudo cp target/release/aws /usr/local/bin/aws-cli

# Or create an alias
alias aws='./target/release/aws'
```

### Install Shell Completions

```bash
# Generate completions
cd completions
./generate_completions.sh

# Install for your shell (see script output for instructions)
```

## Quick Start

### 1. Initialize a Project

```bash
# Initialize AWS in current directory
aws init

# Non-interactive initialization
aws init --name "My Course" --yes
```

### 2. Start Services

```bash
# Start all services
aws start

# Start specific services
aws start backend ai-service

# Start in detached mode
aws start --detach
```

### 3. Check Status

```bash
# Quick status check
aws status

# Detailed status
aws status --detailed
```

### 4. Mark a TMA

```bash
# Interactive marking (recommended for beginners)
aws mark --interactive

# Direct marking
aws mark submission.pdf --student S12345 --assignment TMA01

# Mark from specific path
aws mark /path/to/submission.pdf
```

### 5. Batch Mark TMAs

```bash
# Mark all PDFs in a directory
aws batch ./submissions

# Custom pattern and concurrency
aws batch ./submissions --pattern "*.pdf" --concurrency 10
```

## Commands Reference

### Core Commands

#### `init` - Initialize AWS

Initialize AWS in the current directory, creating configuration and directory structure.

```bash
aws init [OPTIONS]

Options:
  -n, --name <NAME>    Project name
  -y, --yes            Skip interactive prompts
```

#### `start` - Start Services

Start AWS backend services using Docker Compose.

```bash
aws start [SERVICES...] [OPTIONS]

Options:
  -d, --detach         Run in detached mode

Services:
  backend              Backend API server
  frontend             Web interface
  database             PostgreSQL database
  ai-service           AI marking service
  moodle-connector     Moodle integration service
```

#### `stop` - Stop Services

Stop running AWS services.

```bash
aws stop [SERVICES...] [OPTIONS]

Options:
  -f, --force          Force stop without confirmation
```

#### `status` - Service Status

Show the current status of AWS services.

```bash
aws status [OPTIONS]

Options:
  -d, --detailed       Show detailed status information
```

### Marking Commands

#### `mark` - Mark a TMA

Submit a TMA for AI-assisted marking.

```bash
aws mark [FILE] [OPTIONS]

Arguments:
  <FILE>               Path to TMA file

Options:
  -s, --student <ID>       Student ID
  -a, --assignment <ID>    Assignment ID
  -i, --interactive        Interactive mode
```

**Examples:**

```bash
# Interactive mode
aws mark --interactive

# Mark with metadata
aws mark tma01.pdf --student S12345 --assignment TMA01

# Quick mark
aws mark submission.pdf
```

#### `batch` - Batch Mark TMAs

Mark multiple TMAs concurrently.

```bash
aws batch <DIRECTORY> [OPTIONS]

Arguments:
  <DIRECTORY>          Directory containing TMA files

Options:
  -p, --pattern <PATTERN>     File pattern (default: *.pdf)
  -c, --concurrency <NUM>     Max concurrent jobs (default: 5)
```

**Examples:**

```bash
# Mark all PDFs in submissions folder
aws batch ./submissions

# Custom pattern
aws batch ./submissions --pattern "TMA01_*.pdf"

# High concurrency
aws batch ./submissions --concurrency 20
```

#### `feedback` - View/Edit Feedback

View or edit generated feedback for a TMA.

```bash
aws feedback <ID> [OPTIONS]

Arguments:
  <ID>                 TMA ID or student ID

Options:
  -e, --edit           Open feedback in editor
  -o, --output <FILE>  Export feedback to file
```

**Examples:**

```bash
# View feedback
aws feedback abc123

# Edit feedback
aws feedback abc123 --edit

# Export feedback
aws feedback abc123 --output feedback.txt
```

### Configuration Commands

#### `config` - Manage Configuration

Manage AWS configuration settings.

```bash
aws config <SUBCOMMAND>

Subcommands:
  show                 Show current configuration
  set <KEY> <VALUE>    Set a configuration value
  get <KEY>            Get a configuration value
  reset                Reset to defaults
  edit                 Edit interactively
```

**Configuration Keys:**

- `project_name` - Project name
- `backend_url` - Backend API URL
- `moodle_url` - Moodle URL
- `auto_sync` - Enable auto-sync (true/false)
- `ai_model` - AI model to use
- `marking_rubric` - Path to marking rubric

**Examples:**

```bash
# Show all settings
aws config show

# Set backend URL
aws config set backend_url http://localhost:8000

# Get a value
aws config get moodle_url

# Interactive edit
aws config edit

# Reset to defaults
aws config reset
```

### Moodle Integration

#### `login` - Login to Moodle

Authenticate with Moodle to enable sync features.

```bash
aws login [OPTIONS]

Options:
  -u, --username <USERNAME>    Moodle username
  --url <URL>                  Moodle URL
  -s, --save                   Save credentials
```

**Examples:**

```bash
# Interactive login
aws login

# Login with credentials
aws login --username john.doe --url https://moodle.example.com --save
```

#### `sync` - Sync with Moodle

Sync assignments and feedback with Moodle.

```bash
aws sync [OPTIONS]

Options:
  -d, --download       Download new assignments
  -u, --upload         Upload marked assignments
  -n, --dry-run        Show what would be synced
```

**Examples:**

```bash
# Download new assignments
aws sync --download

# Upload feedback
aws sync --upload

# Both (default)
aws sync

# Dry run
aws sync --dry-run
```

### Maintenance Commands

#### `update` - Update AWS

Update AWS CLI to the latest version.

```bash
aws update [OPTIONS]

Options:
  -v, --version <VERSION>    Update to specific version
  -c, --check                Check for updates only
```

**Examples:**

```bash
# Update to latest
aws update

# Check for updates
aws update --check

# Update to specific version
aws update --version 1.2.0
```

#### `doctor` - Diagnose Issues

Run diagnostics to identify and fix common issues.

```bash
aws doctor [OPTIONS]

Options:
  -f, --fix            Automatically fix issues
```

**Examples:**

```bash
# Run diagnostics
aws doctor

# Auto-fix issues
aws doctor --fix
```

## Global Options

These options work with all commands:

```bash
-v, --verbose          Enable verbose output
--no-color             Disable colored output
-c, --config <FILE>    Path to configuration file
--format <FORMAT>      Output format (text, json)
-h, --help             Show help
--version              Show version
```

**Examples:**

```bash
# Verbose mode
aws status --verbose

# JSON output
aws status --format json

# Custom config file
aws start --config /path/to/config.yaml

# No colors (for scripts)
aws status --no-color
```

## Configuration

AWS uses a YAML configuration file located at `.aws/config.yaml`.

### Default Configuration

```yaml
project_name: "Academic Workflow Suite"
backend_url: "http://localhost:8000"
moodle_url: null
auto_sync: false
ai_model: null
marking_rubric: null
default_concurrency: 5
timeout_seconds: 300
```

### Environment Variables

You can override configuration using environment variables:

```bash
export AWS_BACKEND_URL="http://custom-backend:8000"
export AWS_VERBOSE=1
export AWS_NO_COLOR=1
```

## Directory Structure

After initialization, AWS creates the following structure:

```
.aws/
├── config.yaml          # Configuration file
├── credentials.json     # Moodle credentials (encrypted)
├── submissions/         # Downloaded TMA submissions
├── feedback/            # Generated feedback files
└── logs/                # Application logs
```

## Workflows

### Complete Marking Workflow

```bash
# 1. Initialize project
aws init

# 2. Start services
aws start

# 3. Login to Moodle
aws login --save

# 4. Download assignments
aws sync --download

# 5. Batch mark submissions
aws batch .aws/submissions

# 6. Review and edit feedback
aws feedback <id> --edit

# 7. Upload to Moodle
aws sync --upload
```

### Quick Single TMA Workflow

```bash
# Mark a single TMA interactively
aws mark --interactive

# Review feedback
aws feedback <id>

# Edit if needed
aws feedback <id> --edit
```

### Automated Batch Workflow

```bash
# Create a script for automated marking
#!/bin/bash
aws sync --download
aws batch .aws/submissions --concurrency 10
aws sync --upload --dry-run  # Review first
aws sync --upload             # Then upload
```

## Shell Completions

Shell completions provide tab-completion for commands and options.

### Installation

```bash
# Generate completions
cd completions
./generate_completions.sh

# Bash
sudo cp aws.bash /etc/bash_completion.d/aws

# Zsh
cp _aws ~/.zsh/completion/

# Fish
cp aws.fish ~/.config/fish/completions/

# PowerShell
# Add to profile: . /path/to/_aws.ps1
```

## Troubleshooting

### Services Won't Start

```bash
# Run diagnostics
aws doctor --fix

# Check Docker
docker --version
docker-compose --version

# View logs
docker-compose logs
```

### Backend Unreachable

```bash
# Check status
aws status --detailed

# Restart services
aws stop --force
aws start
```

### Moodle Sync Issues

```bash
# Re-login
aws login

# Check credentials
cat .aws/credentials.json

# Test connection
aws status --detailed
```

### Configuration Issues

```bash
# Reset configuration
aws config reset

# Re-initialize
aws init --yes
```

## Development

### Building

```bash
# Debug build
cargo build

# Release build
cargo build --release

# Run tests
cargo test

# Run with logging
RUST_LOG=debug cargo run -- status
```

### Testing

```bash
# Unit tests
cargo test

# Integration tests
cargo test --test '*'

# Specific test
cargo test test_config
```

## Contributing

Contributions are welcome! Please see the main repository's CONTRIBUTING.md for guidelines.

## License

This project is licensed under the GNU General Public License v3.0. See the LICENSE file for details.

## Support

- **Documentation**: https://github.com/yourusername/academic-workflow-suite/wiki
- **Issues**: https://github.com/yourusername/academic-workflow-suite/issues
- **Discussions**: https://github.com/yourusername/academic-workflow-suite/discussions

## Changelog

### Version 0.1.0 (Initial Release)

- Core commands: init, start, stop, status
- TMA marking: mark, batch, feedback
- Moodle integration: login, sync
- Configuration management
- Shell completions
- Diagnostics tool

---

**Made with ❤️ for educators by the Academic Workflow Suite team**
