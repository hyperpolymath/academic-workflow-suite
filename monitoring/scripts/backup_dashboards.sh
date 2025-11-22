#!/bin/bash

# Academic Workflow Suite - Grafana Dashboard Backup Script
# Backs up all Grafana dashboards to JSON files

set -euo pipefail

# Configuration
GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
GRAFANA_API_KEY="${GRAFANA_API_KEY:-}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-admin}"
BACKUP_DIR="${BACKUP_DIR:-./dashboard-backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup directory
create_backup_dir() {
    local backup_path="$BACKUP_DIR/$TIMESTAMP"
    mkdir -p "$backup_path"
    echo "$backup_path"
}

# Get all dashboard UIDs
get_dashboard_uids() {
    local auth_header
    if [ -n "$GRAFANA_API_KEY" ]; then
        auth_header="Authorization: Bearer $GRAFANA_API_KEY"
    else
        auth_header="Authorization: Basic $(echo -n "$GRAFANA_USER:$GRAFANA_PASSWORD" | base64)"
    fi

    curl -s -H "$auth_header" "$GRAFANA_URL/api/search?type=dash-db" | \
        jq -r '.[] | .uid'
}

# Backup single dashboard
backup_dashboard() {
    local uid=$1
    local backup_path=$2
    local auth_header

    if [ -n "$GRAFANA_API_KEY" ]; then
        auth_header="Authorization: Bearer $GRAFANA_API_KEY"
    else
        auth_header="Authorization: Basic $(echo -n "$GRAFANA_USER:$GRAFANA_PASSWORD" | base64)"
    fi

    local dashboard_json=$(curl -s -H "$auth_header" "$GRAFANA_URL/api/dashboards/uid/$uid")
    local title=$(echo "$dashboard_json" | jq -r '.dashboard.title' | sed 's/ /_/g')

    if [ "$title" != "null" ]; then
        local filename="${backup_path}/${title}_${uid}.json"
        echo "$dashboard_json" | jq '.dashboard' > "$filename"
        log_info "Backed up: $title ($uid)"
        return 0
    else
        log_warn "Failed to backup dashboard: $uid"
        return 1
    fi
}

# Backup all dashboards
backup_all_dashboards() {
    log_info "Starting Grafana dashboard backup..."
    log_info "Grafana URL: $GRAFANA_URL"

    local backup_path=$(create_backup_dir)
    log_info "Backup directory: $backup_path"

    local uids=$(get_dashboard_uids)
    local count=0
    local failed=0

    while IFS= read -r uid; do
        if backup_dashboard "$uid" "$backup_path"; then
            ((count++))
        else
            ((failed++))
        fi
    done <<< "$uids"

    log_info "Backup complete: $count dashboards backed up, $failed failed"
    log_info "Backup location: $backup_path"

    # Create a manifest file
    cat > "$backup_path/manifest.json" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "grafana_url": "$GRAFANA_URL",
  "dashboard_count": $count,
  "failed_count": $failed,
  "backup_date": "$(date -Iseconds)"
}
EOF

    # Create tarball
    local tarball="$BACKUP_DIR/dashboards_$TIMESTAMP.tar.gz"
    tar -czf "$tarball" -C "$BACKUP_DIR" "$TIMESTAMP"
    log_info "Created tarball: $tarball"

    # Clean up old backups (keep last 10)
    log_info "Cleaning up old backups..."
    ls -t "$BACKUP_DIR"/*.tar.gz | tail -n +11 | xargs -r rm
    log_info "Cleanup complete"
}

# Restore dashboards from backup
restore_dashboards() {
    local restore_path=$1

    if [ ! -d "$restore_path" ]; then
        log_error "Backup directory not found: $restore_path"
        exit 1
    fi

    log_info "Restoring dashboards from: $restore_path"

    local auth_header
    if [ -n "$GRAFANA_API_KEY" ]; then
        auth_header="Authorization: Bearer $GRAFANA_API_KEY"
    else
        auth_header="Authorization: Basic $(echo -n "$GRAFANA_USER:$GRAFANA_PASSWORD" | base64)"
    fi

    local count=0
    local failed=0

    for file in "$restore_path"/*.json; do
        if [ "$file" = "$restore_path/manifest.json" ]; then
            continue
        fi

        local title=$(jq -r '.title' "$file")
        log_info "Restoring: $title"

        local payload=$(jq '{dashboard: ., overwrite: true}' "$file")

        if curl -s -X POST -H "$auth_header" -H "Content-Type: application/json" \
            -d "$payload" "$GRAFANA_URL/api/dashboards/db" | grep -q "success"; then
            ((count++))
        else
            log_warn "Failed to restore: $title"
            ((failed++))
        fi
    done

    log_info "Restore complete: $count dashboards restored, $failed failed"
}

# Main function
main() {
    case "${1:-backup}" in
        backup)
            backup_all_dashboards
            ;;
        restore)
            if [ -z "${2:-}" ]; then
                log_error "Please specify backup directory to restore from"
                echo "Usage: $0 restore <backup_directory>"
                exit 1
            fi
            restore_dashboards "$2"
            ;;
        *)
            echo "Usage: $0 {backup|restore <backup_directory>}"
            exit 1
            ;;
    esac
}

# Check dependencies
if ! command -v jq &> /dev/null; then
    log_error "jq is required but not installed"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    log_error "curl is required but not installed"
    exit 1
fi

main "$@"
