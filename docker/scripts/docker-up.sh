#!/usr/bin/env bash
# Start Docker Compose services for Academic Workflow Suite

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

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi

    log_info "Prerequisites check passed"
}

# Function to load environment variables
load_env() {
    local env_file="${PROJECT_ROOT}/.env.${ENVIRONMENT}"

    if [ -f "${env_file}" ]; then
        log_info "Loading environment from ${env_file}"
        set -a
        source "${env_file}"
        set +a
    else
        log_warn "Environment file ${env_file} not found. Using defaults."
    fi
}

# Function to start services
start_services() {
    log_info "Starting Academic Workflow Suite in ${ENVIRONMENT} mode..."

    cd "${PROJECT_ROOT}"

    case "${ENVIRONMENT}" in
        dev|development)
            log_info "Starting development environment..."
            docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
            ;;
        test|testing)
            log_info "Starting test environment..."
            docker-compose -f docker-compose.yml -f docker-compose.test.yml up --abort-on-container-exit
            ;;
        prod|production)
            log_info "Starting production environment..."
            docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
            ;;
        *)
            log_error "Unknown environment: ${ENVIRONMENT}"
            log_info "Usage: $0 [dev|test|prod]"
            exit 1
            ;;
    esac
}

# Function to wait for services
wait_for_services() {
    log_info "Waiting for services to be healthy..."

    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if docker-compose ps | grep -q "unhealthy"; then
            log_warn "Some services are still starting... (attempt $((attempt + 1))/${max_attempts})"
            sleep 5
            attempt=$((attempt + 1))
        else
            log_info "All services are healthy!"
            return 0
        fi
    done

    log_warn "Some services may not be fully healthy yet. Check 'docker-compose ps' for details."
}

# Function to display service URLs
display_urls() {
    log_info "Service URLs:"
    echo ""
    echo "  Core API:        http://localhost:8080"
    echo "  Backend API:     http://localhost:4000"
    echo "  Nginx:           http://localhost:80 (https://localhost:443)"
    echo "  Adminer:         http://localhost:8081"
    echo "  Prometheus:      http://localhost:9090"
    echo "  Grafana:         http://localhost:3000"
    echo ""
    log_info "Run 'docker-compose logs -f' to view logs"
    log_info "Run 'docker-compose ps' to view service status"
}

# Main execution
main() {
    log_info "Academic Workflow Suite - Docker Startup Script"
    echo ""

    check_prerequisites
    load_env
    start_services

    if [ "${ENVIRONMENT}" != "test" ]; then
        wait_for_services
        display_urls
    fi

    log_info "Startup complete!"
}

main "$@"
