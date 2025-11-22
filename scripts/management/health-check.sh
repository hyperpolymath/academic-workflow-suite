#!/usr/bin/env bash
#
# health-check.sh - System health monitoring for Academic Workflow Suite
#
# Usage: ./health-check.sh [--json] [--verbose] [--dry-run]
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="/var/log/aws"
LOG_FILE="$LOG_DIR/health-check.log"

# Service configuration
BACKEND_PORT="${BACKEND_PORT:-4000}"
AI_JAIL_PORT="${AI_JAIL_PORT:-8080}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_DB="${POSTGRES_DB:-aws_production}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"

# Threshold configuration
DISK_WARN_THRESHOLD=80
DISK_CRIT_THRESHOLD=90
MEM_WARN_THRESHOLD=80
MEM_CRIT_THRESHOLD=90

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

OUTPUT_JSON=false
VERBOSE=false
DRY_RUN=false
EXIT_CODE=0
HEALTH_RESULTS=()

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
${BOLD}Academic Workflow Suite - Health Check${RESET}

Usage: $0 [OPTIONS]

OPTIONS:
    --json          Output results in JSON format
    --verbose       Enable verbose output
    --dry-run       Simulate checks without actual execution
    -h, --help      Show this help message

DESCRIPTION:
    Performs comprehensive health checks on all AWS components:
    - Service status (backend, AI jail)
    - Database connectivity
    - Disk space and memory usage
    - GPU availability
    - API endpoint health

EXIT CODES:
    0    All checks passed
    1    One or more checks failed
    2    Critical failure

EXAMPLES:
    $0                  # Run health check with terminal output
    $0 --json           # Output JSON report
    $0 --verbose        # Show detailed information

EOF
    exit 0
}

add_result() {
    local check_name="$1"
    local status="$2"
    local message="$3"
    local details="${4:-}"

    HEALTH_RESULTS+=("$check_name|$status|$message|$details")

    if [[ "$status" == "FAIL" ]] || [[ "$status" == "CRITICAL" ]]; then
        EXIT_CODE=1
    fi
}

check_service_port() {
    local service_name="$1"
    local port="$2"

    log INFO "Checking $service_name on port $port..."

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would check port $port"
        add_result "service_$service_name" "PASS" "$service_name is running" "port=$port"
        return 0
    fi

    if nc -z localhost "$port" 2>/dev/null || timeout 2 bash -c "echo > /dev/tcp/localhost/$port" 2>/dev/null; then
        log SUCCESS "$service_name is running on port $port"
        add_result "service_$service_name" "PASS" "$service_name is running" "port=$port"
        return 0
    else
        log ERROR "$service_name is not responding on port $port"
        add_result "service_$service_name" "FAIL" "$service_name is not running" "port=$port"
        return 1
    fi
}

check_database_connectivity() {
    log INFO "Checking PostgreSQL database connectivity..."

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would check database connectivity"
        add_result "database_connectivity" "PASS" "Database is accessible" ""
        return 0
    fi

    # Check if psql is available
    if ! command -v psql &> /dev/null; then
        log WARN "psql command not found, skipping database connectivity check"
        add_result "database_connectivity" "WARN" "psql not installed" ""
        return 0
    fi

    # Try to connect to database
    if PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" &> /dev/null; then
        log SUCCESS "Database connection successful"

        # Get database size
        local db_size
        db_size=$(PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT pg_size_pretty(pg_database_size('$POSTGRES_DB'));" 2>/dev/null | xargs || echo "unknown")

        add_result "database_connectivity" "PASS" "Database is accessible" "size=$db_size"
        return 0
    else
        log ERROR "Cannot connect to database"
        add_result "database_connectivity" "FAIL" "Database connection failed" ""
        return 1
    fi
}

check_disk_space() {
    log INFO "Checking disk space..."

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would check disk space"
        add_result "disk_space" "PASS" "Disk space sufficient" "usage=50%"
        return 0
    fi

    # Check main filesystem
    local usage
    usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

    local status="PASS"
    local message="Disk usage: ${usage}%"

    if [[ $usage -ge $DISK_CRIT_THRESHOLD ]]; then
        status="CRITICAL"
        log ERROR "Critical: Disk usage at ${usage}%"
    elif [[ $usage -ge $DISK_WARN_THRESHOLD ]]; then
        status="WARN"
        log WARN "Warning: Disk usage at ${usage}%"
    else
        log SUCCESS "Disk usage: ${usage}%"
    fi

    add_result "disk_space_root" "$status" "$message" "usage=${usage}%"

    # Check models directory if it exists
    if [[ -d "$PROJECT_ROOT/models" ]]; then
        local models_size
        models_size=$(du -sh "$PROJECT_ROOT/models" 2>/dev/null | awk '{print $1}' || echo "unknown")
        log INFO "Models directory size: $models_size"
        add_result "disk_space_models" "PASS" "Models directory size: $models_size" "size=$models_size"
    fi

    # Check events directory if it exists
    if [[ -d "$PROJECT_ROOT/events" ]]; then
        local events_size
        events_size=$(du -sh "$PROJECT_ROOT/events" 2>/dev/null | awk '{print $1}' || echo "unknown")
        log INFO "Events directory size: $events_size"
        add_result "disk_space_events" "PASS" "Events directory size: $events_size" "size=$events_size"
    fi

    return 0
}

check_memory_usage() {
    log INFO "Checking memory usage..."

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would check memory usage"
        add_result "memory_usage" "PASS" "Memory usage normal" "usage=45%"
        return 0
    fi

    # Get memory usage percentage
    local mem_total mem_available mem_used usage

    if [[ -f /proc/meminfo ]]; then
        mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        mem_used=$((mem_total - mem_available))
        usage=$((mem_used * 100 / mem_total))
    else
        log WARN "Cannot read /proc/meminfo"
        add_result "memory_usage" "WARN" "Memory info unavailable" ""
        return 0
    fi

    local status="PASS"
    local message="Memory usage: ${usage}%"

    if [[ $usage -ge $MEM_CRIT_THRESHOLD ]]; then
        status="CRITICAL"
        log ERROR "Critical: Memory usage at ${usage}%"
    elif [[ $usage -ge $MEM_WARN_THRESHOLD ]]; then
        status="WARN"
        log WARN "Warning: Memory usage at ${usage}%"
    else
        log SUCCESS "Memory usage: ${usage}%"
    fi

    add_result "memory_usage" "$status" "$message" "usage=${usage}%,total=$((mem_total/1024))MB,used=$((mem_used/1024))MB"

    return 0
}

check_gpu_availability() {
    log INFO "Checking GPU availability..."

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would check GPU availability"
        add_result "gpu_availability" "PASS" "GPU available" "count=1"
        return 0
    fi

    if ! command -v nvidia-smi &> /dev/null; then
        log INFO "nvidia-smi not found, no NVIDIA GPU available"
        add_result "gpu_availability" "PASS" "No GPU (optional)" "gpu=none"
        return 0
    fi

    if nvidia-smi &> /dev/null; then
        local gpu_count
        gpu_count=$(nvidia-smi --query-gpu=count --format=csv,noheader | head -1)
        local gpu_memory
        gpu_memory=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader | head -1)
        local gpu_utilization
        gpu_utilization=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader | head -1)

        log SUCCESS "GPU available: $gpu_count GPU(s), Memory: $gpu_memory, Utilization: $gpu_utilization"
        add_result "gpu_availability" "PASS" "GPU available" "count=$gpu_count,memory=$gpu_memory,utilization=$gpu_utilization"
    else
        log WARN "nvidia-smi command failed"
        add_result "gpu_availability" "WARN" "GPU check failed" ""
    fi

    return 0
}

check_api_endpoints() {
    log INFO "Checking API endpoint health..."

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would check API endpoints"
        add_result "api_backend_health" "PASS" "Backend API healthy" ""
        add_result "api_ai_jail_health" "PASS" "AI Jail API healthy" ""
        return 0
    fi

    # Check backend health endpoint
    if command -v curl &> /dev/null; then
        local backend_url="http://localhost:$BACKEND_PORT/health"
        if curl -sf "$backend_url" -o /dev/null -w "%{http_code}" | grep -q "200"; then
            log SUCCESS "Backend API health endpoint responded"
            add_result "api_backend_health" "PASS" "Backend API healthy" "url=$backend_url"
        else
            log WARN "Backend API health endpoint did not respond"
            add_result "api_backend_health" "WARN" "Backend API health check failed" "url=$backend_url"
        fi

        # Check AI jail health endpoint
        local ai_jail_url="http://localhost:$AI_JAIL_PORT/health"
        if curl -sf "$ai_jail_url" -o /dev/null -w "%{http_code}" | grep -q "200"; then
            log SUCCESS "AI Jail API health endpoint responded"
            add_result "api_ai_jail_health" "PASS" "AI Jail API healthy" "url=$ai_jail_url"
        else
            log WARN "AI Jail API health endpoint did not respond"
            add_result "api_ai_jail_health" "WARN" "AI Jail health check failed" "url=$ai_jail_url"
        fi
    else
        log WARN "curl not available, skipping API endpoint checks"
        add_result "api_endpoints" "WARN" "curl not available" ""
    fi

    return 0
}

check_event_store() {
    log INFO "Checking LMDB event store..."

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would check event store"
        add_result "event_store" "PASS" "Event store accessible" ""
        return 0
    fi

    local event_store_path="$PROJECT_ROOT/events"

    if [[ -d "$event_store_path" ]]; then
        if [[ -r "$event_store_path/data.mdb" ]]; then
            local size
            size=$(du -sh "$event_store_path/data.mdb" 2>/dev/null | awk '{print $1}' || echo "unknown")
            log SUCCESS "Event store accessible (size: $size)"
            add_result "event_store" "PASS" "Event store accessible" "path=$event_store_path,size=$size"
        else
            log WARN "Event store directory exists but data.mdb not found"
            add_result "event_store" "WARN" "Event store not initialized" "path=$event_store_path"
        fi
    else
        log WARN "Event store directory not found: $event_store_path"
        add_result "event_store" "WARN" "Event store directory missing" "path=$event_store_path"
    fi

    return 0
}

output_terminal_report() {
    echo ""
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo "${BOLD}${CYAN}  AWS Health Check Report${RESET}"
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo ""

    local pass_count=0
    local warn_count=0
    local fail_count=0
    local crit_count=0

    for result in "${HEALTH_RESULTS[@]}"; do
        IFS='|' read -r name status message details <<< "$result"

        local status_color=""
        local status_symbol=""

        case "$status" in
            PASS)
                status_color="$GREEN"
                status_symbol="✓"
                ((pass_count++))
                ;;
            WARN)
                status_color="$YELLOW"
                status_symbol="⚠"
                ((warn_count++))
                ;;
            FAIL)
                status_color="$RED"
                status_symbol="✗"
                ((fail_count++))
                ;;
            CRITICAL)
                status_color="$RED"
                status_symbol="✗✗"
                ((crit_count++))
                ;;
        esac

        printf "  ${status_color}${status_symbol}${RESET} %-30s ${status_color}%-10s${RESET} %s\n" "$name" "[$status]" "$message"

        if [[ -n "$details" ]] && [[ "$VERBOSE" == true ]]; then
            echo "    ${CYAN}└─ $details${RESET}"
        fi
    done

    echo ""
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo "  ${GREEN}Passed:${RESET} $pass_count  ${YELLOW}Warnings:${RESET} $warn_count  ${RED}Failed:${RESET} $fail_count  ${RED}Critical:${RESET} $crit_count"
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo ""

    if [[ $fail_count -gt 0 ]] || [[ $crit_count -gt 0 ]]; then
        echo "${RED}${BOLD}Health check failed!${RESET}"
        return 1
    elif [[ $warn_count -gt 0 ]]; then
        echo "${YELLOW}${BOLD}Health check completed with warnings${RESET}"
        return 0
    else
        echo "${GREEN}${BOLD}All health checks passed!${RESET}"
        return 0
    fi
}

output_json_report() {
    local timestamp
    timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    echo "{"
    echo "  \"timestamp\": \"$timestamp\","
    echo "  \"status\": \"$([ $EXIT_CODE -eq 0 ] && echo 'healthy' || echo 'unhealthy')\","
    echo "  \"checks\": ["

    local first=true
    for result in "${HEALTH_RESULTS[@]}"; do
        IFS='|' read -r name status message details <<< "$result"

        [[ "$first" == true ]] || echo ","
        first=false

        echo "    {"
        echo "      \"name\": \"$name\","
        echo "      \"status\": \"$status\","
        echo "      \"message\": \"$message\""
        [[ -n "$details" ]] && echo "      ,\"details\": \"$details\""
        echo -n "    }"
    done

    echo ""
    echo "  ]"
    echo "}"
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --json)
                OUTPUT_JSON=true
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
        if mkdir -p "$LOG_DIR" 2>/dev/null; then
            log DEBUG "Created log directory: $LOG_DIR"
        fi
    fi

    [[ "$OUTPUT_JSON" == false ]] && log INFO "Starting health check..."
    [[ "$DRY_RUN" == true ]] && log INFO "Running in DRY-RUN mode"

    # Run all health checks
    check_service_port "backend" "$BACKEND_PORT" || true
    check_service_port "ai_jail" "$AI_JAIL_PORT" || true
    check_database_connectivity || true
    check_disk_space || true
    check_memory_usage || true
    check_gpu_availability || true
    check_api_endpoints || true
    check_event_store || true

    # Output report
    if [[ "$OUTPUT_JSON" == true ]]; then
        output_json_report
    else
        output_terminal_report
    fi

    exit $EXIT_CODE
}

# ============================================================================
# Entry Point
# ============================================================================

main "$@"
