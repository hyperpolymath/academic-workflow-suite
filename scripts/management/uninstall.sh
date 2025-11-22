#!/usr/bin/env bash
#
# uninstall.sh - Clean uninstallation for Academic Workflow Suite
#
# Usage: ./uninstall.sh [OPTIONS]
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="/var/log/aws"
LOG_FILE="$LOG_DIR/uninstall.log"

# Installation paths
SYSTEMD_DIR="/etc/systemd/system"
INSTALL_DIR="${INSTALL_DIR:-/opt/aws}"
BIN_DIR="${BIN_DIR:-/usr/local/bin}"

# Database configuration
POSTGRES_DB="${POSTGRES_DB:-aws_production}"
POSTGRES_TEST_DB="${POSTGRES_TEST_DB:-aws_test}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"

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
KEEP_DATA=false
KEEP_CONFIG=false
FORCE=false
CONFIRMED=false

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
${BOLD}Academic Workflow Suite - Uninstallation${RESET}

Usage: $0 [OPTIONS]

OPTIONS:
    --verbose       Enable verbose output
    --dry-run       Simulate uninstallation without making changes
    --keep-data     Preserve databases and event store
    --keep-config   Preserve configuration files
    --force         Skip confirmation prompts
    -h, --help      Show this help message

DESCRIPTION:
    Performs complete uninstallation of AWS:
    - Stops all running services
    - Removes systemd units
    - Drops databases (unless --keep-data)
    - Removes installed files
    - Unregisters Office add-in
    - Removes log files

${YELLOW}WARNING:${RESET}
    This will permanently remove all AWS components.
    Use ${BOLD}--keep-data${RESET} to preserve databases and event store.
    Use ${BOLD}--keep-config${RESET} to preserve configuration files.

EXAMPLES:
    $0                      # Full uninstallation (with confirmation)
    $0 --keep-data          # Uninstall but keep data
    $0 --force              # Uninstall without confirmation
    $0 --dry-run            # Preview what would be removed

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

confirm_uninstall() {
    if [[ "$FORCE" == true ]] || [[ "$CONFIRMED" == true ]]; then
        return 0
    fi

    echo ""
    echo "${RED}${BOLD}WARNING: This will uninstall Academic Workflow Suite${RESET}"
    echo ""
    echo "The following will be removed:"
    echo "  - All systemd services"
    echo "  - Installed binaries and files"
    [[ "$KEEP_DATA" == false ]] && echo "  ${RED}- Databases and event store (ALL DATA)${RESET}"
    [[ "$KEEP_CONFIG" == false ]] && echo "  - Configuration files"
    echo "  - Log files"
    echo "  - Office add-in registration"
    echo ""

    if [[ "$KEEP_DATA" == true ]]; then
        echo "${GREEN}Data will be preserved${RESET}"
    fi

    if [[ "$KEEP_CONFIG" == true ]]; then
        echo "${GREEN}Configuration will be preserved${RESET}"
    fi

    echo ""
    read -rp "Are you sure you want to continue? (type 'yes' to confirm): " response

    if [[ "$response" != "yes" ]]; then
        log INFO "Uninstallation cancelled"
        exit 0
    fi

    CONFIRMED=true
}

stop_services() {
    print_header "Stopping Services"

    local services=(
        "aws-backend"
        "aws-ai-jail"
    )

    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            log INFO "Stopping $service..."

            if [[ "$DRY_RUN" == true ]]; then
                log DEBUG "DRY-RUN: Would stop $service"
            else
                sudo systemctl stop "$service" || log WARN "Failed to stop $service"
                log SUCCESS "$service stopped"
            fi
        else
            log DEBUG "$service not running"
        fi
    done

    log SUCCESS "Services stopped"
}

remove_systemd_units() {
    print_header "Removing Systemd Units"

    local services=(
        "aws-backend.service"
        "aws-ai-jail.service"
    )

    for service in "${services[@]}"; do
        local service_file="$SYSTEMD_DIR/$service"

        if [[ -f "$service_file" ]]; then
            log INFO "Removing $service..."

            if [[ "$DRY_RUN" == true ]]; then
                log DEBUG "DRY-RUN: Would remove $service_file"
            else
                # Disable service
                sudo systemctl disable "$service" 2>/dev/null || true

                # Remove service file
                sudo rm -f "$service_file"

                log SUCCESS "$service removed"
            fi
        else
            log DEBUG "$service not found"
        fi
    done

    # Reload systemd
    if [[ "$DRY_RUN" == false ]]; then
        sudo systemctl daemon-reload
        log SUCCESS "Systemd reloaded"
    fi
}

drop_databases() {
    print_header "Removing Databases"

    if [[ "$KEEP_DATA" == true ]]; then
        log INFO "Skipping database removal (--keep-data specified)"
        return 0
    fi

    if ! command -v dropdb &> /dev/null; then
        log WARN "dropdb command not found, skipping database removal"
        return 0
    fi

    local databases=(
        "$POSTGRES_DB"
        "$POSTGRES_TEST_DB"
    )

    for db in "${databases[@]}"; do
        # Check if database exists
        if PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h localhost -U "$POSTGRES_USER" -d postgres \
            -tAc "SELECT 1 FROM pg_database WHERE datname='$db'" 2>/dev/null | grep -q 1; then

            log WARN "Dropping database: $db"

            if [[ "$DRY_RUN" == true ]]; then
                log DEBUG "DRY-RUN: Would drop database $db"
            else
                # Terminate connections
                PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h localhost -U "$POSTGRES_USER" -d postgres << EOF 2>/dev/null || true
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = '$db'
  AND pid <> pg_backend_pid();
EOF

                # Drop database
                PGPASSWORD="${POSTGRES_PASSWORD:-}" dropdb -h localhost -U "$POSTGRES_USER" "$db" 2>/dev/null || {
                    log WARN "Failed to drop database $db"
                    continue
                }

                log SUCCESS "Database $db dropped"
            fi
        else
            log DEBUG "Database $db does not exist"
        fi
    done
}

remove_event_store() {
    print_header "Removing Event Store"

    if [[ "$KEEP_DATA" == true ]]; then
        log INFO "Skipping event store removal (--keep-data specified)"
        return 0
    fi

    local event_store_path="$PROJECT_ROOT/events"

    if [[ -d "$event_store_path" ]]; then
        log WARN "Removing event store: $event_store_path"

        if [[ "$DRY_RUN" == true ]]; then
            log DEBUG "DRY-RUN: Would remove $event_store_path"
        else
            rm -rf "$event_store_path"
            log SUCCESS "Event store removed"
        fi
    else
        log DEBUG "Event store not found"
    fi
}

remove_installed_files() {
    print_header "Removing Installed Files"

    # Remove installed binaries
    local binaries=(
        "aws-backend"
        "aws-ai-jail"
        "aws-cli"
    )

    for binary in "${binaries[@]}"; do
        local binary_path="$BIN_DIR/$binary"

        if [[ -f "$binary_path" ]] || [[ -L "$binary_path" ]]; then
            log INFO "Removing binary: $binary"

            if [[ "$DRY_RUN" == true ]]; then
                log DEBUG "DRY-RUN: Would remove $binary_path"
            else
                sudo rm -f "$binary_path"
                log SUCCESS "$binary removed"
            fi
        fi
    done

    # Remove installation directory
    if [[ -d "$INSTALL_DIR" ]]; then
        log INFO "Removing installation directory: $INSTALL_DIR"

        if [[ "$DRY_RUN" == true ]]; then
            log DEBUG "DRY-RUN: Would remove $INSTALL_DIR"
        else
            sudo rm -rf "$INSTALL_DIR"
            log SUCCESS "Installation directory removed"
        fi
    fi
}

remove_config_files() {
    print_header "Removing Configuration Files"

    if [[ "$KEEP_CONFIG" == true ]]; then
        log INFO "Skipping config removal (--keep-config specified)"
        return 0
    fi

    local config_locations=(
        "/etc/aws"
        "$HOME/.config/aws"
        "$PROJECT_ROOT/.env"
    )

    for config_path in "${config_locations[@]}"; do
        if [[ -e "$config_path" ]]; then
            log INFO "Removing: $config_path"

            if [[ "$DRY_RUN" == true ]]; then
                log DEBUG "DRY-RUN: Would remove $config_path"
            else
                if [[ "$config_path" == "/etc/aws" ]]; then
                    sudo rm -rf "$config_path"
                else
                    rm -rf "$config_path"
                fi
                log SUCCESS "Removed $config_path"
            fi
        fi
    done
}

unregister_office_addin() {
    print_header "Unregistering Office Add-in"

    # Check for Office add-in manifest
    local manifest_locations=(
        "$HOME/.office-addin/aws-addin.xml"
        "/opt/office-addins/aws-addin.xml"
    )

    for manifest in "${manifest_locations[@]}"; do
        if [[ -f "$manifest" ]]; then
            log INFO "Removing add-in manifest: $manifest"

            if [[ "$DRY_RUN" == true ]]; then
                log DEBUG "DRY-RUN: Would remove $manifest"
            else
                rm -f "$manifest"
                log SUCCESS "Manifest removed"
            fi
        fi
    done

    log INFO "Office add-in unregistered"
    log INFO "You may need to manually remove the add-in from Office"
}

remove_logs() {
    print_header "Removing Log Files"

    if [[ -d "$LOG_DIR" ]]; then
        log INFO "Removing logs: $LOG_DIR"

        if [[ "$DRY_RUN" == true ]]; then
            log DEBUG "DRY-RUN: Would remove $LOG_DIR"
        else
            # Create final log entry
            log INFO "Uninstallation completed"

            # Remove logs (use sudo if needed)
            if [[ -w "$LOG_DIR" ]]; then
                rm -rf "$LOG_DIR"
            else
                sudo rm -rf "$LOG_DIR"
            fi

            echo "${SUCCESS}Logs removed${RESET}"
        fi
    fi
}

remove_models() {
    print_header "Removing AI Models"

    if [[ "$KEEP_DATA" == true ]]; then
        log INFO "Skipping model removal (--keep-data specified)"
        return 0
    fi

    local models_dir="$PROJECT_ROOT/models"

    if [[ -d "$models_dir" ]]; then
        local size
        size=$(du -sh "$models_dir" 2>/dev/null | awk '{print $1}' || echo "unknown")

        log WARN "Removing AI models directory: $models_dir ($size)"

        if [[ "$DRY_RUN" == true ]]; then
            log DEBUG "DRY-RUN: Would remove $models_dir"
        else
            rm -rf "$models_dir"
            log SUCCESS "AI models removed"
        fi
    else
        log DEBUG "Models directory not found"
    fi
}

cleanup_cache() {
    print_header "Cleaning Up Cache"

    local cache_locations=(
        "$HOME/.cache/aws"
        "/tmp/aws-*"
    )

    for cache_path in "${cache_locations[@]}"; do
        if [[ "$cache_path" == *"*"* ]]; then
            # Glob pattern
            for item in $cache_path 2>/dev/null; do
                if [[ -e "$item" ]]; then
                    log INFO "Removing: $item"

                    if [[ "$DRY_RUN" == false ]]; then
                        rm -rf "$item"
                    fi
                fi
            done
        elif [[ -e "$cache_path" ]]; then
            log INFO "Removing: $cache_path"

            if [[ "$DRY_RUN" == true ]]; then
                log DEBUG "DRY-RUN: Would remove $cache_path"
            else
                rm -rf "$cache_path"
            fi
        fi
    done

    log SUCCESS "Cache cleaned"
}

print_summary() {
    echo ""
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo "${BOLD}${CYAN}  Uninstallation Complete${RESET}"
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo ""

    if [[ "$KEEP_DATA" == true ]]; then
        echo "  ${GREEN}Databases and event store preserved${RESET}"
        echo "  Location: $PROJECT_ROOT/events"
        echo ""
    fi

    if [[ "$KEEP_CONFIG" == true ]]; then
        echo "  ${GREEN}Configuration files preserved${RESET}"
        echo ""
    fi

    echo "  ${BOLD}Removed Components:${RESET}"
    echo "  - Systemd services"
    echo "  - Installed binaries"
    [[ "$KEEP_DATA" == false ]] && echo "  - Databases and event store"
    [[ "$KEEP_CONFIG" == false ]] && echo "  - Configuration files"
    echo "  - Log files"
    echo "  - Cache files"
    echo ""

    if [[ "$KEEP_DATA" == false ]]; then
        echo "  ${YELLOW}Note:${RESET} All data has been permanently deleted"
    else
        echo "  ${YELLOW}Note:${RESET} To remove preserved data later, run:"
        echo "         rm -rf $PROJECT_ROOT/events"
        echo "         dropdb $POSTGRES_DB"
    fi

    echo ""
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo ""
    echo "${GREEN}Thank you for using Academic Workflow Suite!${RESET}"
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
            --keep-data)
                KEEP_DATA=true
                shift
                ;;
            --keep-config)
                KEEP_CONFIG=true
                shift
                ;;
            --force)
                FORCE=true
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

    print_header "Academic Workflow Suite - Uninstallation"

    [[ "$DRY_RUN" == true ]] && log INFO "Running in DRY-RUN mode"

    # Confirm uninstallation
    confirm_uninstall

    log INFO "Starting uninstallation..."

    # Perform uninstallation
    stop_services
    remove_systemd_units
    drop_databases
    remove_event_store
    remove_models
    remove_installed_files
    remove_config_files
    unregister_office_addin
    cleanup_cache
    remove_logs

    # Print summary (only in non-dry-run)
    if [[ "$DRY_RUN" == false ]]; then
        print_summary
    else
        log INFO "DRY-RUN: No changes were made"
    fi
}

# ============================================================================
# Entry Point
# ============================================================================

main "$@"
