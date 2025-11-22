#!/bin/bash

# Academic Workflow Suite - Comprehensive Health Check Script
# This script performs health checks on all system components
# Exit codes: 0 = healthy, 1 = unhealthy, 2 = degraded

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL="${BACKEND_URL:-http://localhost:8080}"
AI_JAIL_URL="${AI_JAIL_URL:-http://localhost:8081}"
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_DB="${POSTGRES_DB:-academic_workflow_suite}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"

# Track overall health
OVERALL_HEALTH=0
DEGRADED_SERVICES=0
FAILED_SERVICES=0

# Logging
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check HTTP endpoint
check_http() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}

    log_info "Checking $name at $url..."

    if response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 "$url" 2>&1); then
        if [ "$response" = "$expected_status" ]; then
            log_info "$name is healthy (HTTP $response)"
            return 0
        else
            log_warn "$name returned unexpected status: HTTP $response (expected $expected_status)"
            ((DEGRADED_SERVICES++))
            return 2
        fi
    else
        log_error "$name is unreachable: $response"
        ((FAILED_SERVICES++))
        return 1
    fi
}

# Check PostgreSQL
check_postgres() {
    log_info "Checking PostgreSQL database..."

    if command -v psql &> /dev/null; then
        if PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" &> /dev/null; then
            log_info "PostgreSQL is healthy"

            # Check connection count
            conn_count=$(PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null | tr -d ' ')
            log_info "PostgreSQL active connections: $conn_count"

            # Check database size
            db_size=$(PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT pg_size_pretty(pg_database_size('$POSTGRES_DB'));" 2>/dev/null | tr -d ' ')
            log_info "PostgreSQL database size: $db_size"

            return 0
        else
            log_error "PostgreSQL connection failed"
            ((FAILED_SERVICES++))
            return 1
        fi
    else
        log_warn "psql not available, skipping detailed PostgreSQL check"
        ((DEGRADED_SERVICES++))
        return 2
    fi
}

# Check disk space
check_disk_space() {
    log_info "Checking disk space..."

    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

    if [ "$disk_usage" -lt 80 ]; then
        log_info "Disk usage is healthy: ${disk_usage}%"
        return 0
    elif [ "$disk_usage" -lt 90 ]; then
        log_warn "Disk usage is high: ${disk_usage}%"
        ((DEGRADED_SERVICES++))
        return 2
    else
        log_error "Disk usage is critical: ${disk_usage}%"
        ((FAILED_SERVICES++))
        return 1
    fi
}

# Check memory
check_memory() {
    log_info "Checking memory usage..."

    if command -v free &> /dev/null; then
        mem_usage=$(free | grep Mem | awk '{printf("%.0f", ($3/$2) * 100)}')

        if [ "$mem_usage" -lt 80 ]; then
            log_info "Memory usage is healthy: ${mem_usage}%"
            return 0
        elif [ "$mem_usage" -lt 90 ]; then
            log_warn "Memory usage is high: ${mem_usage}%"
            ((DEGRADED_SERVICES++))
            return 2
        else
            log_error "Memory usage is critical: ${mem_usage}%"
            ((FAILED_SERVICES++))
            return 1
        fi
    else
        log_warn "free command not available"
        return 2
    fi
}

# Check CPU load
check_cpu_load() {
    log_info "Checking CPU load..."

    if command -v uptime &> /dev/null; then
        load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
        cpu_count=$(nproc)
        load_threshold=$(echo "$cpu_count * 0.8" | bc)

        if (( $(echo "$load_avg < $load_threshold" | bc -l) )); then
            log_info "CPU load is healthy: $load_avg (CPUs: $cpu_count)"
            return 0
        else
            log_warn "CPU load is high: $load_avg (CPUs: $cpu_count)"
            ((DEGRADED_SERVICES++))
            return 2
        fi
    else
        log_warn "uptime command not available"
        return 2
    fi
}

# Check Docker containers (if Docker is available)
check_docker() {
    log_info "Checking Docker containers..."

    if command -v docker &> /dev/null; then
        # Check if Docker daemon is running
        if ! docker info &> /dev/null; then
            log_warn "Docker daemon is not running"
            ((DEGRADED_SERVICES++))
            return 2
        fi

        # Count running containers
        running=$(docker ps -q | wc -l)
        log_info "Running Docker containers: $running"

        # Check for unhealthy containers
        unhealthy=$(docker ps --filter health=unhealthy -q | wc -l)
        if [ "$unhealthy" -gt 0 ]; then
            log_warn "Found $unhealthy unhealthy Docker containers"
            docker ps --filter health=unhealthy --format "table {{.Names}}\t{{.Status}}"
            ((DEGRADED_SERVICES++))
            return 2
        fi

        log_info "All Docker containers are healthy"
        return 0
    else
        log_info "Docker not available, skipping container checks"
        return 0
    fi
}

# Check SSL certificates
check_certificates() {
    log_info "Checking SSL certificates..."

    if command -v openssl &> /dev/null; then
        # Extract domain from backend URL
        domain=$(echo "$BACKEND_URL" | sed -e 's|^[^/]*//||' -e 's|/.*$||' -e 's|:.*$||')

        if [[ "$BACKEND_URL" == https://* ]]; then
            expiry=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

            if [ -n "$expiry" ]; then
                expiry_epoch=$(date -d "$expiry" +%s)
                current_epoch=$(date +%s)
                days_left=$(( (expiry_epoch - current_epoch) / 86400 ))

                if [ "$days_left" -gt 30 ]; then
                    log_info "SSL certificate valid for $days_left days"
                    return 0
                elif [ "$days_left" -gt 7 ]; then
                    log_warn "SSL certificate expires in $days_left days"
                    ((DEGRADED_SERVICES++))
                    return 2
                else
                    log_error "SSL certificate expires in $days_left days - renewal urgent!"
                    ((FAILED_SERVICES++))
                    return 1
                fi
            else
                log_warn "Could not check SSL certificate"
                return 2
            fi
        else
            log_info "Not using HTTPS, skipping SSL check"
            return 0
        fi
    else
        log_warn "openssl not available"
        return 2
    fi
}

# Main health check
main() {
    echo "=========================================="
    echo "Academic Workflow Suite - Health Check"
    echo "Started at: $(date)"
    echo "=========================================="
    echo

    # Check all services
    check_http "Backend API" "$BACKEND_URL/health" || true
    check_http "AI Jail" "$AI_JAIL_URL/health" || true
    check_http "Grafana" "$GRAFANA_URL/api/health" || true
    check_http "Prometheus" "$PROMETHEUS_URL/-/healthy" || true
    check_postgres || true
    check_disk_space || true
    check_memory || true
    check_cpu_load || true
    check_docker || true
    check_certificates || true

    echo
    echo "=========================================="
    echo "Health Check Summary"
    echo "=========================================="
    echo "Failed services: $FAILED_SERVICES"
    echo "Degraded services: $DEGRADED_SERVICES"
    echo

    if [ "$FAILED_SERVICES" -gt 0 ]; then
        log_error "System is UNHEALTHY - $FAILED_SERVICES critical failures"
        exit 1
    elif [ "$DEGRADED_SERVICES" -gt 0 ]; then
        log_warn "System is DEGRADED - $DEGRADED_SERVICES warnings"
        exit 2
    else
        log_info "System is HEALTHY - All checks passed"
        exit 0
    fi
}

# Run main function
main "$@"
