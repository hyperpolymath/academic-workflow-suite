#!/usr/bin/env bash
# View logs for Docker Compose services

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Default service
SERVICE="${1:-}"
FOLLOW="${2:--f}"

# Function to print colored messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Function to show logs
show_logs() {
    cd "${PROJECT_ROOT}"

    if [ -z "${SERVICE}" ]; then
        log_info "Showing logs for all services..."
        docker-compose logs ${FOLLOW}
    else
        log_info "Showing logs for ${SERVICE}..."
        docker-compose logs ${FOLLOW} "${SERVICE}"
    fi
}

# Main execution
main() {
    log_info "Academic Workflow Suite - Docker Logs Viewer"
    echo ""

    show_logs
}

main "$@"
