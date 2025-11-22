#!/usr/bin/env bash
#
# update.sh - Update system for Academic Workflow Suite
#
# Usage: ./update.sh [OPTIONS]
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="/var/log/aws"
LOG_FILE="$LOG_DIR/update.log"

# Git configuration
GIT_BRANCH="${GIT_BRANCH:-main}"
GIT_REMOTE="${GIT_REMOTE:-origin}"

# Build configuration
RUST_BUILD_MODE="${RUST_BUILD_MODE:-release}"

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
SKIP_BACKUP=false
SKIP_MIGRATIONS=false
SKIP_RESTART=false
AUTO_RESTART=false
FORCE=false

CURRENT_VERSION=""
NEW_VERSION=""
CHANGED_COMPONENTS=()

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
${BOLD}Academic Workflow Suite - Update System${RESET}

Usage: $0 [OPTIONS]

OPTIONS:
    --verbose           Enable verbose output
    --dry-run           Simulate update without making changes
    --skip-backup       Skip pre-update backup
    --skip-migrations   Skip database migrations
    --skip-restart      Skip service restart
    --auto-restart      Automatically restart services without prompting
    --force             Force update even if no changes detected
    --branch <name>     Update from specific branch (default: main)
    -h, --help          Show this help message

DESCRIPTION:
    Updates AWS to the latest version:
    - Creates backup before update
    - Pulls latest code from repository
    - Detects changed components
    - Rebuilds only changed components
    - Runs database migrations
    - Restarts services
    - Verifies update success

UPDATE PROCESS:
    1. Check for updates
    2. Create backup
    3. Pull latest code
    4. Rebuild changed components
    5. Run migrations
    6. Restart services
    7. Verify health

EXAMPLES:
    $0                      # Standard update
    $0 --auto-restart       # Update with automatic restart
    $0 --skip-backup        # Update without backup
    $0 --branch develop     # Update from develop branch
    $0 --dry-run            # Preview update

EOF
    exit 0
}

print_header() {
    local title="$1"
    echo ""
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo "${BOLD}${CYAN}  $title${RESET}"
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo ""
}

check_git_repo() {
    log INFO "Checking git repository..."

    if [[ ! -d "$PROJECT_ROOT/.git" ]]; then
        log ERROR "Not a git repository: $PROJECT_ROOT"
        exit 1
    fi

    # Check for uncommitted changes
    if ! git -C "$PROJECT_ROOT" diff --quiet || ! git -C "$PROJECT_ROOT" diff --cached --quiet; then
        log WARN "You have uncommitted changes"

        if [[ "$FORCE" == false ]]; then
            log ERROR "Please commit or stash your changes before updating"
            log INFO "Use --force to update anyway (not recommended)"
            exit 1
        else
            log WARN "Proceeding with update despite uncommitted changes"
        fi
    fi

    log SUCCESS "Git repository check passed"
}

get_current_version() {
    CURRENT_VERSION=$(git -C "$PROJECT_ROOT" describe --tags 2>/dev/null || git -C "$PROJECT_ROOT" rev-parse --short HEAD)
    log INFO "Current version: $CURRENT_VERSION"
}

check_for_updates() {
    print_header "Checking for Updates"

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would check for updates"
        return 0
    fi

    log INFO "Fetching latest changes from $GIT_REMOTE/$GIT_BRANCH..."

    git -C "$PROJECT_ROOT" fetch "$GIT_REMOTE" "$GIT_BRANCH"

    local local_commit
    local_commit=$(git -C "$PROJECT_ROOT" rev-parse HEAD)

    local remote_commit
    remote_commit=$(git -C "$PROJECT_ROOT" rev-parse "$GIT_REMOTE/$GIT_BRANCH")

    if [[ "$local_commit" == "$remote_commit" ]]; then
        log INFO "Already up to date"

        if [[ "$FORCE" == false ]]; then
            log INFO "No updates available"
            exit 0
        else
            log WARN "Forcing update even though no changes detected"
        fi
    else
        local commits_behind
        commits_behind=$(git -C "$PROJECT_ROOT" rev-list --count HEAD.."$GIT_REMOTE/$GIT_BRANCH")

        log INFO "Updates available: $commits_behind commit(s) behind"

        # Show commit log
        if [[ "$VERBOSE" == true ]]; then
            log INFO "Recent commits:"
            git -C "$PROJECT_ROOT" log --oneline HEAD.."$GIT_REMOTE/$GIT_BRANCH" | while read -r line; do
                log INFO "  $line"
            done
        fi
    fi
}

create_backup() {
    print_header "Creating Backup"

    if [[ "$SKIP_BACKUP" == true ]]; then
        log INFO "Skipping backup (--skip-backup specified)"
        return 0
    fi

    local backup_script="$SCRIPT_DIR/backup.sh"

    if [[ ! -f "$backup_script" ]]; then
        log WARN "Backup script not found, skipping backup"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would create backup"
        return 0
    fi

    log INFO "Creating pre-update backup..."

    if bash "$backup_script" backup --no-models; then
        log SUCCESS "Backup created successfully"
    else
        log ERROR "Backup failed"

        if [[ "$FORCE" == false ]]; then
            log ERROR "Update aborted. Use --skip-backup to proceed without backup."
            exit 1
        else
            log WARN "Continuing despite backup failure"
        fi
    fi
}

detect_changed_components() {
    log INFO "Detecting changed components..."

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would detect changed components"
        return 0
    fi

    # Get changed files
    local changed_files
    changed_files=$(git -C "$PROJECT_ROOT" diff --name-only HEAD "$GIT_REMOTE/$GIT_BRANCH")

    log DEBUG "Changed files:"
    echo "$changed_files" | while read -r file; do
        log DEBUG "  $file"
    done

    # Detect which components changed
    if echo "$changed_files" | grep -q "^components/backend/"; then
        CHANGED_COMPONENTS+=("backend")
        log INFO "Backend component changed"
    fi

    if echo "$changed_files" | grep -q "^components/ai-jail/"; then
        CHANGED_COMPONENTS+=("ai-jail")
        log INFO "AI jail component changed"
    fi

    if echo "$changed_files" | grep -q "^components/office-addin/"; then
        CHANGED_COMPONENTS+=("office-addin")
        log INFO "Office add-in component changed"
    fi

    # Check for migration files
    if echo "$changed_files" | grep -q "migrations/\|priv/repo/migrations/"; then
        CHANGED_COMPONENTS+=("migrations")
        log INFO "Database migrations changed"
    fi

    if [[ ${#CHANGED_COMPONENTS[@]} -eq 0 ]]; then
        log INFO "No component changes detected"

        if [[ "$FORCE" == true ]]; then
            log WARN "Forcing rebuild of all components"
            CHANGED_COMPONENTS=("backend" "ai-jail" "office-addin")
        fi
    fi
}

pull_latest_code() {
    print_header "Pulling Latest Code"

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would pull latest code"
        return 0
    fi

    log INFO "Pulling from $GIT_REMOTE/$GIT_BRANCH..."

    git -C "$PROJECT_ROOT" pull "$GIT_REMOTE" "$GIT_BRANCH"

    NEW_VERSION=$(git -C "$PROJECT_ROOT" describe --tags 2>/dev/null || git -C "$PROJECT_ROOT" rev-parse --short HEAD)

    log SUCCESS "Updated to version: $NEW_VERSION"
}

rebuild_backend() {
    log INFO "Rebuilding backend component..."

    local backend_dir="$PROJECT_ROOT/components/backend"

    if [[ ! -d "$backend_dir" ]]; then
        log WARN "Backend directory not found"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would rebuild backend"
        return 0
    fi

    # Build Rust backend
    if [[ -f "$backend_dir/Cargo.toml" ]]; then
        log INFO "Building Rust backend..."

        (
            cd "$backend_dir"
            if [[ "$RUST_BUILD_MODE" == "release" ]]; then
                cargo build --release
            else
                cargo build
            fi
        )

        log SUCCESS "Backend rebuilt"
    fi

    # Build Elixir backend
    if [[ -f "$backend_dir/mix.exs" ]]; then
        log INFO "Compiling Elixir backend..."

        (
            cd "$backend_dir"
            mix deps.get
            MIX_ENV=prod mix compile
        )

        log SUCCESS "Elixir backend compiled"
    fi
}

rebuild_ai_jail() {
    log INFO "Rebuilding AI jail component..."

    local ai_jail_dir="$PROJECT_ROOT/components/ai-jail"

    if [[ ! -d "$ai_jail_dir" ]]; then
        log WARN "AI jail directory not found"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would rebuild AI jail"
        return 0
    fi

    (
        cd "$ai_jail_dir"
        if [[ "$RUST_BUILD_MODE" == "release" ]]; then
            cargo build --release
        else
            cargo build
        fi
    )

    log SUCCESS "AI jail rebuilt"
}

rebuild_office_addin() {
    log INFO "Rebuilding office add-in component..."

    local office_addin_dir="$PROJECT_ROOT/components/office-addin"

    if [[ ! -d "$office_addin_dir" ]]; then
        log WARN "Office add-in directory not found"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would rebuild office add-in"
        return 0
    fi

    (
        cd "$office_addin_dir"
        npm install
        npm run build
    )

    log SUCCESS "Office add-in rebuilt"
}

rebuild_components() {
    print_header "Rebuilding Components"

    if [[ ${#CHANGED_COMPONENTS[@]} -eq 0 ]]; then
        log INFO "No components to rebuild"
        return 0
    fi

    for component in "${CHANGED_COMPONENTS[@]}"; do
        case "$component" in
            backend)
                rebuild_backend
                ;;
            ai-jail)
                rebuild_ai_jail
                ;;
            office-addin)
                rebuild_office_addin
                ;;
            migrations)
                # Migrations are handled separately
                :
                ;;
            *)
                log WARN "Unknown component: $component"
                ;;
        esac
    done

    log SUCCESS "All components rebuilt"
}

run_migrations() {
    print_header "Running Database Migrations"

    if [[ "$SKIP_MIGRATIONS" == true ]]; then
        log INFO "Skipping migrations (--skip-migrations specified)"
        return 0
    fi

    # Check if migrations changed
    if [[ ! " ${CHANGED_COMPONENTS[*]} " =~ " migrations " ]]; then
        log INFO "No migration changes detected, skipping"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would run migrations"
        return 0
    fi

    local backend_dir="$PROJECT_ROOT/components/backend"

    # Run Elixir migrations
    if [[ -f "$backend_dir/mix.exs" ]]; then
        log INFO "Running Elixir migrations..."

        (
            cd "$backend_dir"
            MIX_ENV=prod mix ecto.migrate
        )

        log SUCCESS "Migrations completed"
    fi

    # Run SQL migrations if present
    local migrations_dir="$PROJECT_ROOT/migrations"
    if [[ -d "$migrations_dir" ]]; then
        log INFO "Running SQL migrations..."

        for migration in "$migrations_dir"/*.sql; do
            if [[ -f "$migration" ]] && [[ "$migration" -nt "$PROJECT_ROOT/.last_migration" ]]; then
                log INFO "Applying $(basename "$migration")..."

                if command -v psql &> /dev/null; then
                    PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h localhost -U "${POSTGRES_USER:-postgres}" \
                        -d "${POSTGRES_DB:-aws_production}" -f "$migration"
                fi
            fi
        done

        touch "$PROJECT_ROOT/.last_migration"
        log SUCCESS "SQL migrations completed"
    fi
}

restart_services() {
    print_header "Restarting Services"

    if [[ "$SKIP_RESTART" == true ]]; then
        log INFO "Skipping service restart (--skip-restart specified)"
        return 0
    fi

    local services=()

    # Determine which services need restart based on changed components
    if [[ " ${CHANGED_COMPONENTS[*]} " =~ " backend " ]] || [[ " ${CHANGED_COMPONENTS[*]} " =~ " migrations " ]]; then
        services+=("aws-backend")
    fi

    if [[ " ${CHANGED_COMPONENTS[*]} " =~ " ai-jail " ]]; then
        services+=("aws-ai-jail")
    fi

    if [[ ${#services[@]} -eq 0 ]]; then
        log INFO "No services need restart"
        return 0
    fi

    # Confirm restart unless auto-restart enabled
    if [[ "$AUTO_RESTART" == false ]] && [[ "$DRY_RUN" == false ]]; then
        log WARN "The following services need to be restarted: ${services[*]}"
        read -rp "Restart services now? (yes/no): " response

        if [[ "$response" != "yes" ]]; then
            log INFO "Skipping service restart"
            log WARN "Remember to manually restart services: ${services[*]}"
            return 0
        fi
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would restart services: ${services[*]}"
        return 0
    fi

    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            log INFO "Restarting $service..."
            sudo systemctl restart "$service"
            log SUCCESS "$service restarted"
        else
            log WARN "$service is not running, starting..."
            sudo systemctl start "$service"
            log SUCCESS "$service started"
        fi
    done

    # Wait for services to stabilize
    sleep 2

    log SUCCESS "Services restarted"
}

verify_update() {
    print_header "Verifying Update"

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would verify update"
        return 0
    fi

    local health_script="$SCRIPT_DIR/health-check.sh"

    if [[ -f "$health_script" ]]; then
        log INFO "Running health check..."

        if bash "$health_script" --verbose; then
            log SUCCESS "Health check passed"
        else
            log ERROR "Health check failed"
            log ERROR "Update may have issues, please check logs"
            return 1
        fi
    else
        log WARN "Health check script not found, skipping verification"
    fi

    log SUCCESS "Update verified successfully"
}

print_summary() {
    echo ""
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo "${BOLD}${CYAN}  Update Complete${RESET}"
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo ""
    echo "  ${BOLD}Version Update:${RESET}"
    echo "    Previous: ${YELLOW}$CURRENT_VERSION${RESET}"
    echo "    Current:  ${GREEN}$NEW_VERSION${RESET}"
    echo ""

    if [[ ${#CHANGED_COMPONENTS[@]} -gt 0 ]]; then
        echo "  ${BOLD}Updated Components:${RESET}"
        for component in "${CHANGED_COMPONENTS[@]}"; do
            echo "    ${GREEN}- $component${RESET}"
        done
        echo ""
    fi

    echo "  ${BOLD}Services:${RESET}"
    for service in "aws-backend" "aws-ai-jail"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo "    ${GREEN}✓ $service (running)${RESET}"
        else
            echo "    ${RED}✗ $service (not running)${RESET}"
        fi
    done

    echo ""
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo ""
    echo "${GREEN}Update completed successfully!${RESET}"
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
            --skip-backup)
                SKIP_BACKUP=true
                shift
                ;;
            --skip-migrations)
                SKIP_MIGRATIONS=true
                shift
                ;;
            --skip-restart)
                SKIP_RESTART=true
                shift
                ;;
            --auto-restart)
                AUTO_RESTART=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --branch)
                GIT_BRANCH="$2"
                shift 2
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

    print_header "Academic Workflow Suite - Update"

    log INFO "Starting update process..."
    [[ "$DRY_RUN" == true ]] && log INFO "Running in DRY-RUN mode"

    # Perform update
    check_git_repo
    get_current_version
    check_for_updates
    create_backup
    detect_changed_components
    pull_latest_code
    rebuild_components
    run_migrations
    restart_services
    verify_update

    # Print summary
    print_summary

    log SUCCESS "Update completed successfully"
}

# ============================================================================
# Entry Point
# ============================================================================

main "$@"
