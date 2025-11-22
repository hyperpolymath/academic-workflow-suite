#!/usr/bin/env bash
# Stop Docker Compose services for Academic Workflow Suite

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Default environment
ENVIRONMENT="${1:-dev}"
REMOVE_VOLUMES="${2:-false}"

# Function to print colored messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to stop services
stop_services() {
    log_info "Stopping Academic Workflow Suite (${ENVIRONMENT} mode)..."

    cd "${PROJECT_ROOT}"

    local compose_files="-f docker-compose.yml"

    case "${ENVIRONMENT}" in
        dev|development)
            compose_files="${compose_files} -f docker-compose.dev.yml"
            ;;
        test|testing)
            compose_files="${compose_files} -f docker-compose.test.yml"
            ;;
        prod|production)
            compose_files="${compose_files} -f docker-compose.prod.yml"
            ;;
        *)
            log_error "Unknown environment: ${ENVIRONMENT}"
            log_info "Usage: $0 [dev|test|prod] [--volumes]"
            exit 1
            ;;
    esac

    if [ "${REMOVE_VOLUMES}" = "true" ] || [ "${REMOVE_VOLUMES}" = "--volumes" ]; then
        log_warn "Removing volumes (data will be deleted)..."
        docker-compose ${compose_files} down -v --remove-orphans
    else
        docker-compose ${compose_files} down --remove-orphans
    fi
}

# Function to clean up
cleanup() {
    log_info "Cleaning up dangling images and networks..."
    docker system prune -f
}

# Main execution
main() {
    log_info "Academic Workflow Suite - Docker Shutdown Script"
    echo ""

    # Check if volumes should be removed
    if [ "${REMOVE_VOLUMES}" = "--volumes" ] || [ "${REMOVE_VOLUMES}" = "-v" ]; then
        REMOVE_VOLUMES="true"
    fi

    stop_services
    cleanup

    log_info "Shutdown complete!"
}

main "$@"
