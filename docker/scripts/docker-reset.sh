#!/usr/bin/env bash
# Reset all Docker data for Academic Workflow Suite

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

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

# Function to confirm reset
confirm_reset() {
    log_warn "This will delete ALL data including:"
    echo "  - All containers"
    echo "  - All volumes (databases, caches, etc.)"
    echo "  - All networks"
    echo "  - All images"
    echo ""
    read -p "Are you sure you want to continue? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Reset cancelled"
        exit 0
    fi
}

# Function to reset everything
reset_all() {
    cd "${PROJECT_ROOT}"

    log_info "Stopping all services..."
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml down -v --remove-orphans 2>/dev/null || true
    docker-compose -f docker-compose.yml -f docker-compose.test.yml down -v --remove-orphans 2>/dev/null || true
    docker-compose -f docker-compose.yml -f docker-compose.prod.yml down -v --remove-orphans 2>/dev/null || true

    log_info "Removing images..."
    docker images | grep "aws-" | awk '{print $3}' | xargs -r docker rmi -f || true

    log_info "Removing volumes..."
    docker volume ls | grep "academic-workflow-suite" | awk '{print $2}' | xargs -r docker volume rm || true

    log_info "Removing networks..."
    docker network ls | grep "academic-workflow-suite" | awk '{print $2}' | xargs -r docker network rm || true

    log_info "Cleaning up system..."
    docker system prune -af --volumes
}

# Main execution
main() {
    log_warn "Academic Workflow Suite - Docker Reset Script"
    log_warn "WARNING: This will delete ALL Docker data!"
    echo ""

    confirm_reset
    reset_all

    log_info "Reset complete! Run './docker/scripts/docker-up.sh' to start fresh."
}

main "$@"
