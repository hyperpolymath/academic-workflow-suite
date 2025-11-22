#!/usr/bin/env bash
#
# backup.sh - Backup and restore system for Academic Workflow Suite
#
# Usage: ./backup.sh [backup|restore] [OPTIONS]
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="/var/log/aws"
LOG_FILE="$LOG_DIR/backup.log"

# Backup configuration
BACKUP_ROOT="${BACKUP_ROOT:-/var/backups/aws}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
COMPRESSION="${COMPRESSION:-zstd}"  # gzip, zstd, or none

# Database configuration
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_DB="${POSTGRES_DB:-aws_production}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"

# Backup components
BACKUP_EVENT_STORE=true
BACKUP_DATABASE=true
BACKUP_CONFIG=true
BACKUP_MODELS=false  # Models are large, disabled by default

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
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_DIR=""

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
${BOLD}Academic Workflow Suite - Backup & Restore${RESET}

Usage: $0 <command> [OPTIONS]

COMMANDS:
    backup          Create a new backup
    restore         Restore from a backup
    list            List available backups
    clean           Remove old backups (based on retention policy)

OPTIONS:
    --verbose       Enable verbose output
    --dry-run       Simulate operation without making changes
    --backup-dir    Specify backup directory (default: $BACKUP_ROOT)
    --no-database   Skip database backup/restore
    --no-events     Skip event store backup/restore
    --no-config     Skip config backup/restore
    --include-models Include AI models in backup
    --compression   Compression method: gzip, zstd, none (default: $COMPRESSION)
    -h, --help      Show this help message

BACKUP COMPONENTS:
    - Event store (LMDB)
    - PostgreSQL database
    - Configuration files
    - AI models (optional, use --include-models)

RESTORE OPTIONS:
    --from <path>   Restore from specific backup directory

EXAMPLES:
    $0 backup                          # Create full backup
    $0 backup --include-models         # Include AI models
    $0 restore --from /path/to/backup  # Restore from specific backup
    $0 list                            # List all backups
    $0 clean                           # Remove old backups

ENVIRONMENT VARIABLES:
    BACKUP_ROOT         Root directory for backups (default: /var/backups/aws)
    RETENTION_DAYS      Keep backups for N days (default: 7)
    COMPRESSION         Compression method (default: zstd)

EOF
    exit 0
}

check_dependencies() {
    local missing_deps=()

    # Check for compression tools
    if [[ "$COMPRESSION" == "zstd" ]] && ! command -v zstd &> /dev/null; then
        log WARN "zstd not found, falling back to gzip"
        COMPRESSION="gzip"
    fi

    if [[ "$COMPRESSION" == "gzip" ]] && ! command -v gzip &> /dev/null; then
        log ERROR "gzip not found"
        missing_deps+=("gzip")
    fi

    # Check for database tools if needed
    if [[ "$BACKUP_DATABASE" == true ]] && ! command -v pg_dump &> /dev/null; then
        log WARN "pg_dump not found, database backup will be skipped"
        BACKUP_DATABASE=false
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log ERROR "Missing required dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

compress_file() {
    local source="$1"
    local target="$2"

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would compress $source to $target"
        return 0
    fi

    log INFO "Compressing $source..."

    case "$COMPRESSION" in
        zstd)
            zstd -T0 -19 "$source" -o "$target" 2>&1 | while read -r line; do
                log DEBUG "$line"
            done
            ;;
        gzip)
            gzip -c "$source" > "$target"
            ;;
        none)
            cp "$source" "$target"
            ;;
        *)
            log ERROR "Unknown compression method: $COMPRESSION"
            return 1
            ;;
    esac

    log SUCCESS "Compressed to $target"
}

decompress_file() {
    local source="$1"
    local target="$2"

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would decompress $source to $target"
        return 0
    fi

    log INFO "Decompressing $source..."

    case "$source" in
        *.zst)
            zstd -d "$source" -o "$target"
            ;;
        *.gz)
            gunzip -c "$source" > "$target"
            ;;
        *)
            cp "$source" "$target"
            ;;
    esac

    log SUCCESS "Decompressed to $target"
}

get_compression_ext() {
    case "$COMPRESSION" in
        zstd) echo ".zst" ;;
        gzip) echo ".gz" ;;
        none) echo "" ;;
        *) echo "" ;;
    esac
}

backup_event_store() {
    log INFO "Backing up event store..."

    local event_store_path="$PROJECT_ROOT/events"

    if [[ ! -d "$event_store_path" ]]; then
        log WARN "Event store not found: $event_store_path"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would backup event store"
        return 0
    fi

    local backup_file="$BACKUP_DIR/event_store.tar$(get_compression_ext)"

    log DEBUG "Creating tar archive of event store..."
    tar -C "$PROJECT_ROOT" -cf - events | case "$COMPRESSION" in
        zstd) zstd -T0 -19 -o "$backup_file" ;;
        gzip) gzip > "$backup_file" ;;
        none) cat > "$backup_file.tar" ;;
    esac

    local size
    size=$(du -sh "$backup_file" 2>/dev/null | awk '{print $1}' || echo "unknown")
    log SUCCESS "Event store backed up ($size)"
}

restore_event_store() {
    local backup_file="$1"

    log INFO "Restoring event store from $backup_file..."

    if [[ ! -f "$backup_file" ]]; then
        log ERROR "Backup file not found: $backup_file"
        return 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would restore event store"
        return 0
    fi

    # Backup existing event store
    local event_store_path="$PROJECT_ROOT/events"
    if [[ -d "$event_store_path" ]]; then
        log INFO "Moving existing event store to events.old"
        mv "$event_store_path" "${event_store_path}.old"
    fi

    # Extract archive
    case "$backup_file" in
        *.zst)
            zstd -dc "$backup_file" | tar -C "$PROJECT_ROOT" -xf -
            ;;
        *.gz)
            gunzip -c "$backup_file" | tar -C "$PROJECT_ROOT" -xf -
            ;;
        *.tar)
            tar -C "$PROJECT_ROOT" -xf "$backup_file"
            ;;
        *)
            log ERROR "Unknown backup file format: $backup_file"
            return 1
            ;;
    esac

    log SUCCESS "Event store restored"
}

backup_database() {
    log INFO "Backing up PostgreSQL database..."

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would backup database"
        return 0
    fi

    local backup_file="$BACKUP_DIR/database.sql$(get_compression_ext)"

    log DEBUG "Running pg_dump..."

    case "$COMPRESSION" in
        zstd)
            PGPASSWORD="${POSTGRES_PASSWORD:-}" pg_dump -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
                --no-owner --no-acl | zstd -T0 -19 -o "$backup_file"
            ;;
        gzip)
            PGPASSWORD="${POSTGRES_PASSWORD:-}" pg_dump -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
                --no-owner --no-acl | gzip > "$backup_file"
            ;;
        none)
            PGPASSWORD="${POSTGRES_PASSWORD:-}" pg_dump -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
                --no-owner --no-acl > "$backup_file.sql"
            ;;
    esac

    local size
    size=$(du -sh "$backup_file" 2>/dev/null | awk '{print $1}' || echo "unknown")
    log SUCCESS "Database backed up ($size)"
}

restore_database() {
    local backup_file="$1"

    log INFO "Restoring database from $backup_file..."

    if [[ ! -f "$backup_file" ]]; then
        log ERROR "Backup file not found: $backup_file"
        return 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would restore database"
        return 0
    fi

    log WARN "This will overwrite the existing database. Continue? (yes/no)"
    if [[ -t 0 ]]; then
        read -r response
        if [[ "$response" != "yes" ]]; then
            log INFO "Database restore cancelled"
            return 0
        fi
    fi

    # Restore database
    case "$backup_file" in
        *.zst)
            zstd -dc "$backup_file" | PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB"
            ;;
        *.gz)
            gunzip -c "$backup_file" | PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB"
            ;;
        *.sql)
            PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$backup_file"
            ;;
        *)
            log ERROR "Unknown backup file format: $backup_file"
            return 1
            ;;
    esac

    log SUCCESS "Database restored"
}

backup_config() {
    log INFO "Backing up configuration files..."

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would backup config files"
        return 0
    fi

    local config_dir="$PROJECT_ROOT/config"
    local backup_file="$BACKUP_DIR/config.tar$(get_compression_ext)"

    if [[ -d "$config_dir" ]]; then
        tar -C "$PROJECT_ROOT" -cf - config | case "$COMPRESSION" in
            zstd) zstd -T0 -19 -o "$backup_file" ;;
            gzip) gzip > "$backup_file" ;;
            none) cat > "$backup_file.tar" ;;
        esac

        log SUCCESS "Configuration backed up"
    else
        log WARN "Config directory not found: $config_dir"
    fi

    # Also backup .env files if they exist
    if [[ -f "$PROJECT_ROOT/.env" ]]; then
        cp "$PROJECT_ROOT/.env" "$BACKUP_DIR/.env.backup"
        log SUCCESS "Environment file backed up"
    fi
}

restore_config() {
    local backup_file="$1"

    log INFO "Restoring configuration from $backup_file..."

    if [[ ! -f "$backup_file" ]]; then
        log WARN "Config backup file not found: $backup_file"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would restore config"
        return 0
    fi

    # Extract archive
    case "$backup_file" in
        *.zst)
            zstd -dc "$backup_file" | tar -C "$PROJECT_ROOT" -xf -
            ;;
        *.gz)
            gunzip -c "$backup_file" | tar -C "$PROJECT_ROOT" -xf -
            ;;
        *.tar)
            tar -C "$PROJECT_ROOT" -xf "$backup_file"
            ;;
    esac

    log SUCCESS "Configuration restored"
}

backup_models() {
    log INFO "Backing up AI models..."

    local models_dir="$PROJECT_ROOT/models"

    if [[ ! -d "$models_dir" ]]; then
        log WARN "Models directory not found: $models_dir"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would backup models"
        return 0
    fi

    local backup_file="$BACKUP_DIR/models.tar$(get_compression_ext)"

    log WARN "Backing up models directory (this may take a while)..."

    tar -C "$PROJECT_ROOT" -cf - models | case "$COMPRESSION" in
        zstd) zstd -T0 -19 -o "$backup_file" ;;
        gzip) gzip > "$backup_file" ;;
        none) cat > "$backup_file.tar" ;;
    esac

    local size
    size=$(du -sh "$backup_file" 2>/dev/null | awk '{print $1}' || echo "unknown")
    log SUCCESS "Models backed up ($size)"
}

create_backup() {
    log INFO "Creating backup at $BACKUP_DIR..."

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would create backup directory"
    else
        mkdir -p "$BACKUP_DIR"
    fi

    # Create backup metadata
    if [[ "$DRY_RUN" == false ]]; then
        cat > "$BACKUP_DIR/backup.info" << EOF
Timestamp: $TIMESTAMP
Date: $(date)
Hostname: $(hostname)
User: $(whoami)
AWS Version: $(git -C "$PROJECT_ROOT" describe --tags 2>/dev/null || echo "unknown")
Components:
  - Event Store: $BACKUP_EVENT_STORE
  - Database: $BACKUP_DATABASE
  - Config: $BACKUP_CONFIG
  - Models: $BACKUP_MODELS
Compression: $COMPRESSION
EOF
    fi

    # Backup components
    [[ "$BACKUP_EVENT_STORE" == true ]] && backup_event_store
    [[ "$BACKUP_DATABASE" == true ]] && backup_database
    [[ "$BACKUP_CONFIG" == true ]] && backup_config
    [[ "$BACKUP_MODELS" == true ]] && backup_models

    # Calculate total backup size
    if [[ "$DRY_RUN" == false ]]; then
        local total_size
        total_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | awk '{print $1}' || echo "unknown")
        log SUCCESS "Backup completed: $BACKUP_DIR ($total_size)"
    else
        log INFO "DRY-RUN: Backup simulation completed"
    fi
}

perform_restore() {
    local restore_from="$1"

    if [[ ! -d "$restore_from" ]]; then
        log ERROR "Backup directory not found: $restore_from"
        exit 1
    fi

    log INFO "Restoring from: $restore_from"

    # Show backup info
    if [[ -f "$restore_from/backup.info" ]]; then
        log INFO "Backup information:"
        cat "$restore_from/backup.info" | while read -r line; do
            log INFO "  $line"
        done
    fi

    # Confirm restore
    if [[ "$DRY_RUN" == false ]]; then
        log WARN "This will restore data from backup. Continue? (yes/no)"
        if [[ -t 0 ]]; then
            read -r response
            if [[ "$response" != "yes" ]]; then
                log INFO "Restore cancelled"
                exit 0
            fi
        fi
    fi

    # Restore components
    [[ "$BACKUP_EVENT_STORE" == true ]] && restore_event_store "$restore_from/event_store.tar"*
    [[ "$BACKUP_DATABASE" == true ]] && restore_database "$restore_from/database.sql"*
    [[ "$BACKUP_CONFIG" == true ]] && restore_config "$restore_from/config.tar"*

    log SUCCESS "Restore completed"
}

list_backups() {
    log INFO "Available backups in $BACKUP_ROOT:"
    echo ""

    if [[ ! -d "$BACKUP_ROOT" ]]; then
        log WARN "Backup directory does not exist: $BACKUP_ROOT"
        return 0
    fi

    local count=0
    for backup_dir in "$BACKUP_ROOT"/backup_*; do
        if [[ -d "$backup_dir" ]]; then
            ((count++))
            local size
            size=$(du -sh "$backup_dir" 2>/dev/null | awk '{print $1}' || echo "unknown")
            local timestamp
            timestamp=$(basename "$backup_dir" | sed 's/backup_//')

            printf "  ${CYAN}%-20s${RESET} ${YELLOW}%-10s${RESET}\n" "$timestamp" "($size)"

            if [[ -f "$backup_dir/backup.info" ]] && [[ "$VERBOSE" == true ]]; then
                echo "    ${CYAN}└─${RESET} $(head -2 "$backup_dir/backup.info" | tail -1)"
            fi
        fi
    done

    if [[ $count -eq 0 ]]; then
        log INFO "No backups found"
    else
        echo ""
        log INFO "Total: $count backup(s)"
    fi
}

clean_old_backups() {
    log INFO "Cleaning backups older than $RETENTION_DAYS days..."

    if [[ ! -d "$BACKUP_ROOT" ]]; then
        log WARN "Backup directory does not exist: $BACKUP_ROOT"
        return 0
    fi

    local removed=0

    while IFS= read -r -d '' backup_dir; do
        local age_days
        age_days=$(( ($(date +%s) - $(stat -c %Y "$backup_dir")) / 86400 ))

        if [[ $age_days -gt $RETENTION_DAYS ]]; then
            log INFO "Removing old backup: $(basename "$backup_dir") (${age_days} days old)"

            if [[ "$DRY_RUN" == false ]]; then
                rm -rf "$backup_dir"
            fi

            ((removed++))
        fi
    done < <(find "$BACKUP_ROOT" -maxdepth 1 -type d -name "backup_*" -print0)

    if [[ $removed -eq 0 ]]; then
        log INFO "No old backups to remove"
    else
        log SUCCESS "Removed $removed old backup(s)"
    fi
}

main() {
    local command=""
    local restore_from=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            backup|restore|list|clean)
                command="$1"
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --backup-dir)
                BACKUP_ROOT="$2"
                shift 2
                ;;
            --from)
                restore_from="$2"
                shift 2
                ;;
            --no-database)
                BACKUP_DATABASE=false
                shift
                ;;
            --no-events)
                BACKUP_EVENT_STORE=false
                shift
                ;;
            --no-config)
                BACKUP_CONFIG=false
                shift
                ;;
            --include-models)
                BACKUP_MODELS=true
                shift
                ;;
            --compression)
                COMPRESSION="$2"
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

    if [[ -z "$command" ]]; then
        log ERROR "No command specified"
        usage
    fi

    # Create log directory if it doesn't exist
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || true
    fi

    check_dependencies

    case "$command" in
        backup)
            BACKUP_DIR="$BACKUP_ROOT/backup_$TIMESTAMP"
            create_backup
            clean_old_backups
            ;;
        restore)
            if [[ -z "$restore_from" ]]; then
                log ERROR "Please specify backup to restore with --from <path>"
                exit 1
            fi
            perform_restore "$restore_from"
            ;;
        list)
            list_backups
            ;;
        clean)
            clean_old_backups
            ;;
        *)
            log ERROR "Unknown command: $command"
            usage
            ;;
    esac
}

# ============================================================================
# Entry Point
# ============================================================================

main "$@"
