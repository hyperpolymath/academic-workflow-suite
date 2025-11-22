#!/usr/bin/env bash
#
# init-database.sh - Database initialization for Academic Workflow Suite
#
# Usage: ./init-database.sh [OPTIONS]
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="/var/log/aws"
LOG_FILE="$LOG_DIR/init-database.log"

# PostgreSQL configuration
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-aws_production}"
POSTGRES_TEST_DB="${POSTGRES_TEST_DB:-aws_test}"

# LMDB configuration
EVENT_STORE_PATH="$PROJECT_ROOT/events"
EVENT_STORE_SIZE="${EVENT_STORE_SIZE:-10737418240}"  # 10GB default

# ============================================================================
# Color Output
# ============================================================================

if [[ -t 1 ]]; then
    RED=$(tput setaf 1 2>/dev/null || echo '')
    GREEN=$(tput setaf 2 2>/dev/null || echo '')
    YELLOW=$(tput setaf 3 2>/dev/null || echo '')
    BLUE=$(tput setaf 4 2>/dev/null || echo '')
    MAGENTA=$(tput setaf 5 2>/dev/null || echo '')
    CYAN=$(tput setaf 6 2>/dev/null || echo '')
    BOLD=$(tput bold 2>/dev/null || echo '')
    RESET=$(tput sgr0 2>/dev/null || echo '')
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    BOLD=''
    RESET=''
fi

# ============================================================================
# Global Variables
# ============================================================================

VERBOSE=false
DRY_RUN=false
SEED_DATA=false
CREATE_TEST_DB=false
FORCE_RECREATE=false

# ============================================================================
# Functions
# ============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ -d "$LOG_DIR" ]] && [[ -w "$LOG_DIR" ]]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi

    if [[ "$VERBOSE" == true ]] || [[ "$level" != "DEBUG" ]]; then
        case "$level" in
            ERROR)   echo "${RED}[ERROR]${RESET} $message" >&2 ;;
            WARN)    echo "${YELLOW}[WARN]${RESET} $message" ;;
            SUCCESS) echo "${GREEN}[OK]${RESET} $message" ;;
            INFO)    echo "${BLUE}[INFO]${RESET} $message" ;;
            DEBUG)   echo "${CYAN}[DEBUG]${RESET} $message" ;;
            *)       echo "$message" ;;
        esac
    fi
}

usage() {
    cat << EOF
${BOLD}Academic Workflow Suite - Database Initialization${RESET}

Usage: $0 [OPTIONS]

OPTIONS:
    --verbose       Enable verbose output
    --dry-run       Simulate initialization without making changes
    --seed          Seed test data after initialization
    --test          Also create test database
    --force         Force recreation of existing databases
    -h, --help      Show this help message

DESCRIPTION:
    Initializes all database components for AWS:
    - Creates PostgreSQL databases
    - Runs database migrations
    - Creates LMDB event store
    - Sets proper permissions
    - Optionally seeds test data

ENVIRONMENT VARIABLES:
    POSTGRES_HOST       PostgreSQL host (default: localhost)
    POSTGRES_PORT       PostgreSQL port (default: 5432)
    POSTGRES_USER       PostgreSQL user (default: postgres)
    POSTGRES_PASSWORD   PostgreSQL password
    POSTGRES_DB         Production database name (default: aws_production)
    POSTGRES_TEST_DB    Test database name (default: aws_test)
    EVENT_STORE_PATH    Path to LMDB event store (default: $PROJECT_ROOT/events)
    EVENT_STORE_SIZE    LMDB max size in bytes (default: 10GB)

EXAMPLES:
    $0                  # Initialize production database
    $0 --test --seed    # Initialize with test database and seed data
    $0 --force          # Force recreate existing databases

EOF
    exit 0
}

check_dependencies() {
    local missing_deps=()

    if ! command -v psql &> /dev/null; then
        missing_deps+=("postgresql-client")
    fi

    if ! command -v createdb &> /dev/null; then
        missing_deps+=("postgresql-client")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log ERROR "Missing required dependencies: ${missing_deps[*]}"
        log INFO "Install with: sudo apt-get install postgresql-client"
        exit 1
    fi
}

check_postgres_connection() {
    log INFO "Checking PostgreSQL connection..."

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would check PostgreSQL connection"
        return 0
    fi

    if ! PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres -c "SELECT 1;" &> /dev/null; then
        log ERROR "Cannot connect to PostgreSQL at $POSTGRES_HOST:$POSTGRES_PORT"
        log ERROR "Please ensure PostgreSQL is running and credentials are correct"
        exit 1
    fi

    log SUCCESS "PostgreSQL connection successful"
}

database_exists() {
    local dbname="$1"

    if [[ "$DRY_RUN" == true ]]; then
        return 1
    fi

    PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres \
        -tAc "SELECT 1 FROM pg_database WHERE datname='$dbname'" | grep -q 1
}

create_database() {
    local dbname="$1"

    log INFO "Creating database: $dbname..."

    if database_exists "$dbname"; then
        if [[ "$FORCE_RECREATE" == true ]]; then
            log WARN "Database $dbname exists, recreating..."

            if [[ "$DRY_RUN" == false ]]; then
                # Terminate existing connections
                PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres << EOF
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = '$dbname'
  AND pid <> pg_backend_pid();
EOF

                # Drop database
                PGPASSWORD="${POSTGRES_PASSWORD:-}" dropdb -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" "$dbname"
                log SUCCESS "Dropped existing database: $dbname"
            fi
        else
            log INFO "Database $dbname already exists, skipping creation"
            return 0
        fi
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would create database $dbname"
        return 0
    fi

    # Create database
    PGPASSWORD="${POSTGRES_PASSWORD:-}" createdb -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" \
        -E UTF8 -O "$POSTGRES_USER" "$dbname"

    log SUCCESS "Created database: $dbname"

    # Create extensions
    log INFO "Creating PostgreSQL extensions..."

    PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$dbname" << EOF
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
EOF

    log SUCCESS "Extensions created"
}

run_migrations() {
    local dbname="$1"

    log INFO "Running migrations for $dbname..."

    local backend_dir="$PROJECT_ROOT/components/backend"

    # Check for Elixir migrations
    if [[ -d "$backend_dir" ]] && [[ -f "$backend_dir/mix.exs" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log DEBUG "DRY-RUN: Would run Elixir migrations"
            return 0
        fi

        if command -v mix &> /dev/null; then
            log INFO "Running Elixir migrations..."

            (
                cd "$backend_dir"
                MIX_ENV=prod DATABASE_URL="ecto://$POSTGRES_USER:${POSTGRES_PASSWORD:-}@$POSTGRES_HOST:$POSTGRES_PORT/$dbname" \
                    mix ecto.migrate
            )

            log SUCCESS "Elixir migrations completed"
        else
            log WARN "mix not found, skipping Elixir migrations"
        fi
    fi

    # Check for SQL migration files
    local migrations_dir="$PROJECT_ROOT/migrations"
    if [[ -d "$migrations_dir" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log DEBUG "DRY-RUN: Would run SQL migrations from $migrations_dir"
            return 0
        fi

        log INFO "Running SQL migrations..."

        for migration in "$migrations_dir"/*.sql; do
            if [[ -f "$migration" ]]; then
                log INFO "Applying $(basename "$migration")..."
                PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" \
                    -U "$POSTGRES_USER" -d "$dbname" -f "$migration"
            fi
        done

        log SUCCESS "SQL migrations completed"
    fi
}

seed_database() {
    local dbname="$1"

    log INFO "Seeding test data for $dbname..."

    local backend_dir="$PROJECT_ROOT/components/backend"

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would seed test data"
        return 0
    fi

    # Check for Elixir seed script
    if [[ -f "$backend_dir/priv/repo/seeds.exs" ]]; then
        if command -v mix &> /dev/null; then
            log INFO "Running Elixir seed script..."

            (
                cd "$backend_dir"
                MIX_ENV=prod DATABASE_URL="ecto://$POSTGRES_USER:${POSTGRES_PASSWORD:-}@$POSTGRES_HOST:$POSTGRES_PORT/$dbname" \
                    mix run priv/repo/seeds.exs
            )

            log SUCCESS "Seed data loaded"
        else
            log WARN "mix not found, skipping seed data"
        fi
    fi

    # Check for SQL seed file
    local seed_file="$PROJECT_ROOT/seeds/seed.sql"
    if [[ -f "$seed_file" ]]; then
        log INFO "Running SQL seed script..."
        PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" \
            -U "$POSTGRES_USER" -d "$dbname" -f "$seed_file"

        log SUCCESS "SQL seed data loaded"
    fi
}

create_event_store() {
    log INFO "Creating LMDB event store..."

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would create event store at $EVENT_STORE_PATH"
        return 0
    fi

    # Create event store directory
    if [[ -d "$EVENT_STORE_PATH" ]]; then
        if [[ "$FORCE_RECREATE" == true ]]; then
            log WARN "Event store exists, recreating..."
            rm -rf "$EVENT_STORE_PATH"
        else
            log INFO "Event store already exists at $EVENT_STORE_PATH"
            return 0
        fi
    fi

    mkdir -p "$EVENT_STORE_PATH"
    log SUCCESS "Created event store directory: $EVENT_STORE_PATH"

    # Check if we have a Rust binary to initialize LMDB
    local backend_bin="$PROJECT_ROOT/target/release/backend"

    if [[ -f "$backend_bin" ]]; then
        log INFO "Initializing LMDB database..."
        "$backend_bin" init-eventstore --path "$EVENT_STORE_PATH" --size "$EVENT_STORE_SIZE" || true
        log SUCCESS "Event store initialized"
    else
        log INFO "Backend binary not found, event store will be initialized on first run"
    fi

    # Set permissions
    if [[ -n "${SUDO_USER:-}" ]]; then
        chown -R "$SUDO_USER:$SUDO_USER" "$EVENT_STORE_PATH"
        log DEBUG "Set ownership to $SUDO_USER"
    fi

    chmod -R 750 "$EVENT_STORE_PATH"
    log SUCCESS "Set event store permissions"
}

set_database_permissions() {
    local dbname="$1"

    log INFO "Setting database permissions..."

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would set database permissions"
        return 0
    fi

    PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$dbname" << EOF
-- Grant permissions to application user if different from postgres
DO \$\$
BEGIN
    IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'aws_app') THEN
        GRANT ALL PRIVILEGES ON DATABASE $dbname TO aws_app;
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO aws_app;
        GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO aws_app;
    END IF;
END
\$\$;
EOF

    log SUCCESS "Database permissions set"
}

verify_installation() {
    log INFO "Verifying database installation..."

    local all_ok=true

    # Check PostgreSQL database
    if database_exists "$POSTGRES_DB"; then
        log SUCCESS "Production database exists: $POSTGRES_DB"

        # Count tables
        local table_count
        table_count=$(PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" \
            -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';")

        log INFO "  Tables: $table_count"
    else
        log ERROR "Production database not found"
        all_ok=false
    fi

    # Check test database if requested
    if [[ "$CREATE_TEST_DB" == true ]]; then
        if database_exists "$POSTGRES_TEST_DB"; then
            log SUCCESS "Test database exists: $POSTGRES_TEST_DB"
        else
            log ERROR "Test database not found"
            all_ok=false
        fi
    fi

    # Check event store
    if [[ -d "$EVENT_STORE_PATH" ]]; then
        log SUCCESS "Event store exists: $EVENT_STORE_PATH"

        local size
        size=$(du -sh "$EVENT_STORE_PATH" 2>/dev/null | awk '{print $1}' || echo "unknown")
        log INFO "  Size: $size"
    else
        log ERROR "Event store not found"
        all_ok=false
    fi

    if [[ "$all_ok" == true ]]; then
        log SUCCESS "Database initialization verified successfully"
    else
        log ERROR "Some components failed verification"
        exit 1
    fi
}

print_summary() {
    echo ""
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo "${BOLD}${CYAN}  Database Initialization Complete${RESET}"
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo ""
    echo "  ${BOLD}PostgreSQL:${RESET}"
    echo "    Production DB: ${GREEN}$POSTGRES_DB${RESET}"
    [[ "$CREATE_TEST_DB" == true ]] && echo "    Test DB: ${GREEN}$POSTGRES_TEST_DB${RESET}"
    echo ""
    echo "  ${BOLD}Event Store:${RESET}"
    echo "    Path: ${GREEN}$EVENT_STORE_PATH${RESET}"
    echo ""
    echo "  ${BOLD}Connection:${RESET}"
    echo "    Host: $POSTGRES_HOST:$POSTGRES_PORT"
    echo "    User: $POSTGRES_USER"
    echo ""
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo ""
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose)
                VERBOSE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --seed)
                SEED_DATA=true
                shift
                ;;
            --test)
                CREATE_TEST_DB=true
                shift
                ;;
            --force)
                FORCE_RECREATE=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage
                ;;
        esac
    done

    # Create log directory if it doesn't exist
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || true
    fi

    log INFO "Starting database initialization..."
    [[ "$DRY_RUN" == true ]] && log INFO "Running in DRY-RUN mode"

    # Check dependencies
    check_dependencies

    # Check PostgreSQL connection
    check_postgres_connection

    # Create production database
    create_database "$POSTGRES_DB"
    run_migrations "$POSTGRES_DB"
    set_database_permissions "$POSTGRES_DB"

    if [[ "$SEED_DATA" == true ]]; then
        seed_database "$POSTGRES_DB"
    fi

    # Create test database if requested
    if [[ "$CREATE_TEST_DB" == true ]]; then
        create_database "$POSTGRES_TEST_DB"
        run_migrations "$POSTGRES_TEST_DB"
        set_database_permissions "$POSTGRES_TEST_DB"

        if [[ "$SEED_DATA" == true ]]; then
            seed_database "$POSTGRES_TEST_DB"
        fi
    fi

    # Create LMDB event store
    create_event_store

    # Verify installation
    verify_installation

    # Print summary
    print_summary

    log SUCCESS "Database initialization completed successfully"
}

# ============================================================================
# Entry Point
# ============================================================================

main "$@"
