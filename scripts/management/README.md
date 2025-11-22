# Academic Workflow Suite - Management Scripts

This directory contains comprehensive management scripts for operating and maintaining the Academic Workflow Suite (AWS).

## Overview

All scripts follow consistent design patterns:
- **Strict mode** (`set -euo pipefail`) for reliability
- **Colorized output** using tput/ANSI codes
- **Logging** to `/var/log/aws/`
- **Sudo detection** and appropriate privilege handling
- **Dry-run mode** (`--dry-run`) for safe testing
- **Verbose mode** (`--verbose`) for detailed output

## Scripts

### 1. health-check.sh

**Purpose**: Comprehensive system health monitoring

**Usage**:
```bash
./health-check.sh [--json] [--verbose] [--dry-run]
```

**Features**:
- Checks backend service (port 4000)
- Checks AI jail service (port 8080)
- Verifies PostgreSQL connectivity
- Monitors disk space usage
- Monitors memory usage
- Detects GPU availability (nvidia-smi)
- Tests API endpoint health
- Validates LMDB event store

**Output Modes**:
- Terminal: Colorized table with status indicators
- JSON: Machine-readable format for automation

**Exit Codes**:
- `0`: All checks passed
- `1`: One or more checks failed
- `2`: Critical failure

**Examples**:
```bash
# Standard health check
./health-check.sh

# JSON output for monitoring tools
./health-check.sh --json > health.json

# Verbose diagnostics
./health-check.sh --verbose
```

---

### 2. backup.sh

**Purpose**: Backup and restore system for all AWS components

**Usage**:
```bash
./backup.sh <command> [OPTIONS]

Commands:
  backup    Create new backup
  restore   Restore from backup
  list      List available backups
  clean     Remove old backups
```

**Features**:
- Backs up LMDB event store
- Backs up PostgreSQL database (pg_dump)
- Backs up configuration files
- Optional AI model backup (large files)
- Compression support (gzip/zstd)
- Automatic rotation (7-day retention)
- Point-in-time restore

**Options**:
```bash
--backup-dir <path>    Backup location (default: /var/backups/aws)
--no-database          Skip database backup
--no-events            Skip event store backup
--no-config            Skip config backup
--include-models       Include AI models
--compression <type>   gzip, zstd, or none
--from <path>          Restore from specific backup
```

**Examples**:
```bash
# Create full backup
./backup.sh backup

# Create backup with models
./backup.sh backup --include-models

# List all backups
./backup.sh list

# Restore from specific backup
./backup.sh restore --from /var/backups/aws/backup_20231122_143022

# Clean old backups
./backup.sh clean
```

**Backup Structure**:
```
/var/backups/aws/
└── backup_20231122_143022/
    ├── backup.info           # Metadata
    ├── database.sql.zst      # Compressed database dump
    ├── event_store.tar.zst   # Compressed event store
    ├── config.tar.zst        # Configuration files
    └── models.tar.zst        # AI models (optional)
```

---

### 3. test-all.sh

**Purpose**: Comprehensive test runner for all components

**Usage**:
```bash
./test-all.sh [OPTIONS]
```

**Features**:
- Runs Rust tests (`cargo test`)
- Runs Elixir tests (`mix test`)
- Runs ReScript tests (`npm test`)
- Runs integration tests
- Runs AI isolation tests
- Generates coverage reports
- Parallel test execution (optional)
- Fail-fast mode

**Options**:
```bash
--coverage             Generate code coverage
--parallel             Run tests in parallel
--fail-fast            Stop on first failure
--rust-only            Run only Rust tests
--elixir-only          Run only Elixir tests
--rescript-only        Run only ReScript tests
--integration-only     Run only integration tests
--ai-only              Run only AI isolation tests
--skip-<component>     Skip specific test suite
```

**Exit Codes**:
- `0`: All tests passed
- `1`: One or more tests failed
- `2`: Test execution error

**Examples**:
```bash
# Run all tests
./test-all.sh

# Run with coverage
./test-all.sh --coverage

# Run only Rust tests
./test-all.sh --rust-only

# Fast fail for CI/CD
./test-all.sh --fail-fast

# Skip slow integration tests
./test-all.sh --skip-integration
```

**Coverage Reports**:
- Rust: `coverage/rust/index.html`
- Elixir: `coverage/elixir/excoveralls.html`
- ReScript: `coverage/rescript/index.html`

---

### 4. init-database.sh

**Purpose**: Database initialization and setup

**Usage**:
```bash
./init-database.sh [OPTIONS]
```

**Features**:
- Creates PostgreSQL databases
- Runs Ecto migrations (Elixir)
- Runs SQL migrations
- Creates LMDB event store
- Sets proper permissions
- Seeds test data (optional)
- Installs PostgreSQL extensions

**Options**:
```bash
--seed          Seed test data
--test          Also create test database
--force         Force recreate existing databases
```

**Environment Variables**:
```bash
POSTGRES_HOST         # Default: localhost
POSTGRES_PORT         # Default: 5432
POSTGRES_USER         # Default: postgres
POSTGRES_PASSWORD     # Required for remote hosts
POSTGRES_DB           # Default: aws_production
POSTGRES_TEST_DB      # Default: aws_test
EVENT_STORE_PATH      # Default: $PROJECT_ROOT/events
EVENT_STORE_SIZE      # Default: 10GB
```

**Examples**:
```bash
# Initialize production database
./init-database.sh

# Initialize with test database and seed data
./init-database.sh --test --seed

# Force recreate databases
./init-database.sh --force

# Dry run to see what would be created
./init-database.sh --dry-run --verbose
```

**Database Extensions Installed**:
- `uuid-ossp`: UUID generation
- `pg_trgm`: Trigram matching for text search
- `btree_gin`: GIN indexing for btree-compatible types

---

### 5. dev-setup.sh

**Purpose**: Complete development environment setup

**Usage**:
```bash
./dev-setup.sh [OPTIONS]
```

**Features**:
- Checks system dependencies
- Installs Rust dev tools (cargo-watch, cargo-edit, clippy)
- Installs Node.js packages
- Installs Elixir dependencies (hex, rebar)
- Sets up git hooks (pre-commit, commit-msg)
- Installs LSP servers (rust-analyzer, elixir-ls)
- Creates `.env` file from template
- Builds all components in dev mode

**Options**:
```bash
--skip-git-hooks    Skip git hooks installation
--skip-lsp          Skip LSP server installation
--skip-deps         Skip dependency installation
--skip-build        Skip initial build
```

**Git Hooks**:

**Pre-commit**:
- Rust formatting check (`cargo fmt --check`)
- Rust linting (`cargo clippy`)
- Elixir formatting check (`mix format --check`)
- JavaScript/TypeScript linting (ESLint)

**Commit-msg**:
- Enforces conventional commits format
- Validates message length (max 72 chars)

**Examples**:
```bash
# Full development setup
./dev-setup.sh

# Setup without building (faster)
./dev-setup.sh --skip-build

# Setup without git hooks
./dev-setup.sh --skip-git-hooks

# Verbose output for troubleshooting
./dev-setup.sh --verbose
```

**Post-Setup Steps**:
1. Review and update `.env` file
2. Initialize database: `./init-database.sh`
3. Run tests: `./test-all.sh`
4. Start development servers

---

### 6. uninstall.sh

**Purpose**: Clean and complete uninstallation

**Usage**:
```bash
./uninstall.sh [OPTIONS]
```

**Features**:
- Stops all systemd services
- Removes systemd units
- Drops PostgreSQL databases
- Removes LMDB event store
- Removes AI models
- Removes installed binaries
- Removes configuration files
- Unregisters Office add-in
- Cleans cache and logs

**Options**:
```bash
--keep-data     Preserve databases and event store
--keep-config   Preserve configuration files
--force         Skip confirmation prompts
```

**Safety Features**:
- Confirmation prompt (unless `--force`)
- Highlights data that will be deleted
- Supports data preservation
- Dry-run mode for preview

**Examples**:
```bash
# Standard uninstall (with confirmation)
./uninstall.sh

# Uninstall but keep data
./uninstall.sh --keep-data

# Force uninstall without prompts
./uninstall.sh --force

# Preview what would be removed
./uninstall.sh --dry-run --verbose
```

**Warning**: This permanently removes all AWS components. Data cannot be recovered unless backups exist or `--keep-data` is used.

---

### 7. update.sh

**Purpose**: System update and upgrade automation

**Usage**:
```bash
./update.sh [OPTIONS]
```

**Features**:
- Checks for available updates
- Creates pre-update backup
- Pulls latest code from git
- Detects changed components
- Rebuilds only changed components
- Runs database migrations
- Restarts affected services
- Verifies update success (health check)

**Options**:
```bash
--skip-backup       Skip pre-update backup
--skip-migrations   Skip database migrations
--skip-restart      Skip service restart
--auto-restart      Auto-restart without prompting
--force             Force update even if up-to-date
--branch <name>     Update from specific branch
```

**Update Process**:
1. Check git repository status
2. Fetch and compare versions
3. Create backup
4. Pull latest code
5. Detect changed components
6. Rebuild components
7. Run migrations
8. Restart services
9. Verify health

**Examples**:
```bash
# Standard update
./update.sh

# Update with automatic restart
./update.sh --auto-restart

# Update without backup (faster, risky)
./update.sh --skip-backup

# Update from develop branch
./update.sh --branch develop

# Preview update
./update.sh --dry-run --verbose

# Force update even if no changes
./update.sh --force
```

**Smart Rebuilding**:
- Only rebuilds changed components
- Detects migration changes
- Restarts only affected services
- Minimizes downtime

---

## Common Patterns

### Logging

All scripts log to `/var/log/aws/<script>.log`:

```bash
# View logs
tail -f /var/log/aws/health-check.log

# View all management logs
tail -f /var/log/aws/*.log
```

### Dry Run Mode

Test any script without making changes:

```bash
./backup.sh backup --dry-run --verbose
./update.sh --dry-run --verbose
./init-database.sh --dry-run
```

### Exit Codes

Standard exit codes:
- `0`: Success
- `1`: Failure (recoverable)
- `2`: Critical failure

### Environment Variables

Scripts respect standard AWS environment variables:

```bash
# Database
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=secret

# Services
export BACKEND_PORT=4000
export AI_JAIL_PORT=8080

# Paths
export INSTALL_DIR=/opt/aws
export BACKUP_ROOT=/var/backups/aws
```

## Automation Examples

### Daily Health Check

```bash
# Crontab entry
0 9 * * * /opt/aws/scripts/management/health-check.sh --json > /var/log/aws/daily-health.json
```

### Automated Backups

```bash
# Crontab entry - daily backup at 2 AM
0 2 * * * /opt/aws/scripts/management/backup.sh backup --no-models

# Weekly backup with models (Sunday 3 AM)
0 3 * * 0 /opt/aws/scripts/management/backup.sh backup --include-models
```

### CI/CD Integration

```bash
# .github/workflows/test.yml
- name: Run tests
  run: ./scripts/management/test-all.sh --coverage --fail-fast
```

### Monitoring Integration

```bash
# Send health check to monitoring system
./health-check.sh --json | curl -X POST https://monitoring.example.com/health -d @-
```

## Troubleshooting

### Permission Issues

If scripts fail with permission errors:

```bash
# Ensure scripts are executable
chmod +x scripts/management/*.sh

# Ensure log directory exists and is writable
sudo mkdir -p /var/log/aws
sudo chown $USER:$USER /var/log/aws
```

### Database Connection Issues

```bash
# Test PostgreSQL connection
psql -h localhost -U postgres -c "SELECT 1"

# Check if PostgreSQL is running
systemctl status postgresql
```

### Service Issues

```bash
# Check service status
systemctl status aws-backend aws-ai-jail

# View service logs
journalctl -u aws-backend -f
```

## Best Practices

1. **Always use --dry-run first** when testing new commands
2. **Create backups** before major operations
3. **Review logs** after operations complete
4. **Use --verbose** when troubleshooting
5. **Test updates** in non-production environments first
6. **Keep backups** for at least 7 days
7. **Monitor health** regularly
8. **Document** any custom configurations

## Support

For issues or questions:
- Check logs in `/var/log/aws/`
- Run with `--verbose` for detailed output
- Use `--dry-run` to preview operations
- Review script source code for detailed behavior

## License

These scripts are part of the Academic Workflow Suite project.
See LICENSE file in the project root for details.
