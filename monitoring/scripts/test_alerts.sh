#!/bin/bash

# Academic Workflow Suite - Alert Testing Script
# Tests Prometheus alerts and Alertmanager notifications

set -euo pipefail

# Configuration
PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"
ALERTMANAGER_URL="${ALERTMANAGER_URL:-http://localhost:9093}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

log_section() {
    echo -e "\n${BLUE}===== $1 =====${NC}\n"
}

# Check if Prometheus is accessible
check_prometheus() {
    log_section "Checking Prometheus"

    if curl -sf "$PROMETHEUS_URL/-/healthy" &> /dev/null; then
        log_info "Prometheus is healthy"
        return 0
    else
        log_error "Prometheus is not accessible at $PROMETHEUS_URL"
        return 1
    fi
}

# Check if Alertmanager is accessible
check_alertmanager() {
    log_section "Checking Alertmanager"

    if curl -sf "$ALERTMANAGER_URL/-/healthy" &> /dev/null; then
        log_info "Alertmanager is healthy"
        return 0
    else
        log_error "Alertmanager is not accessible at $ALERTMANAGER_URL"
        return 1
    fi
}

# Verify alert rules are loaded
verify_alert_rules() {
    log_section "Verifying Alert Rules"

    local rules=$(curl -s "$PROMETHEUS_URL/api/v1/rules" | jq -r '.data.groups[].rules[] | select(.type=="alerting") | .name' | wc -l)

    if [ "$rules" -gt 0 ]; then
        log_info "Found $rules alert rules loaded"
        log_info "Alert rules:"
        curl -s "$PROMETHEUS_URL/api/v1/rules" | jq -r '.data.groups[].rules[] | select(.type=="alerting") | "  - \(.name)"'
        return 0
    else
        log_error "No alert rules found"
        return 1
    fi
}

# Check currently firing alerts
check_firing_alerts() {
    log_section "Checking Firing Alerts"

    local alerts=$(curl -s "$PROMETHEUS_URL/api/v1/alerts" | jq -r '.data.alerts[] | select(.state=="firing") | .labels.alertname')

    if [ -n "$alerts" ]; then
        log_warn "Currently firing alerts:"
        while IFS= read -r alert; do
            log_warn "  - $alert"
        done <<< "$alerts"
    else
        log_info "No alerts currently firing"
    fi
}

# Send test alert to Alertmanager
send_test_alert() {
    log_section "Sending Test Alert"

    local alert_payload='[
      {
        "labels": {
          "alertname": "TestAlert",
          "severity": "warning",
          "instance": "test-instance",
          "job": "test-job"
        },
        "annotations": {
          "summary": "This is a test alert",
          "description": "Testing Alertmanager notification routing"
        },
        "startsAt": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'",
        "endsAt": "'$(date -u -d '+5 minutes' +%Y-%m-%dT%H:%M:%S.%3NZ)'"
      }
    ]'

    log_info "Sending test alert to Alertmanager..."

    if curl -s -X POST -H "Content-Type: application/json" \
        -d "$alert_payload" "$ALERTMANAGER_URL/api/v1/alerts" | grep -q "success"; then
        log_info "Test alert sent successfully"
        log_info "Check your notification channels (email, Slack, etc.)"
    else
        log_error "Failed to send test alert"
        return 1
    fi
}

# Check Alertmanager silences
check_silences() {
    log_section "Checking Alertmanager Silences"

    local silences=$(curl -s "$ALERTMANAGER_URL/api/v1/silences" | jq -r '.data[] | select(.status.state=="active")')

    if [ -n "$silences" ]; then
        log_warn "Active silences found:"
        echo "$silences" | jq -r '"  - \(.createdBy): \(.comment)"'
    else
        log_info "No active silences"
    fi
}

# Validate alert rules syntax
validate_alert_rules() {
    log_section "Validating Alert Rule Syntax"

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local monitoring_dir="$(dirname "$script_dir")"
    local alerts_dir="$monitoring_dir/prometheus/alerts"

    if [ ! -d "$alerts_dir" ]; then
        log_error "Alerts directory not found: $alerts_dir"
        return 1
    fi

    local failed=0
    for file in "$alerts_dir"/*.yml; do
        if [ -f "$file" ]; then
            log_info "Validating: $(basename "$file")"

            if command -v promtool &> /dev/null; then
                if promtool check rules "$file" &> /dev/null; then
                    log_info "  ✓ Valid"
                else
                    log_error "  ✗ Invalid syntax"
                    ((failed++))
                fi
            else
                log_warn "  ? promtool not available, skipping validation"
            fi
        fi
    done

    if [ $failed -eq 0 ]; then
        log_info "All alert rules are valid"
        return 0
    else
        log_error "$failed alert rule file(s) have syntax errors"
        return 1
    fi
}

# Test specific alert by temporarily triggering it
test_specific_alert() {
    local alert_name=$1

    log_section "Testing Specific Alert: $alert_name"

    case "$alert_name" in
        ServiceDown)
            log_info "To test ServiceDown alert, stop a service temporarily"
            log_info "Example: docker stop aws-backend"
            ;;
        HighMemoryUsage)
            log_info "To test HighMemoryUsage, run a memory-intensive process"
            ;;
        HighErrorRate)
            log_info "To test HighErrorRate, generate errors in the backend"
            ;;
        *)
            log_warn "No specific test procedure defined for: $alert_name"
            ;;
    esac
}

# List all available alerts
list_alerts() {
    log_section "Available Alerts"

    curl -s "$PROMETHEUS_URL/api/v1/rules" | \
        jq -r '.data.groups[] | .name as $group | .rules[] | select(.type=="alerting") |
        "\($group):\n  Name: \(.name)\n  Severity: \(.labels.severity // "N/A")\n  For: \(.duration // "0s")\n"'
}

# Check alert routing
check_alert_routing() {
    log_section "Checking Alert Routing Configuration"

    log_info "Fetching Alertmanager configuration..."

    local config=$(curl -s "$ALERTMANAGER_URL/api/v1/status" | jq -r '.data.config.original')

    if [ -n "$config" ]; then
        log_info "Alert routing tree:"
        echo "$config" | grep -A 20 "^route:" || log_warn "Could not extract routing configuration"
    else
        log_error "Failed to fetch Alertmanager configuration"
        return 1
    fi
}

# Main menu
show_menu() {
    echo
    echo "Academic Workflow Suite - Alert Testing"
    echo "========================================"
    echo "1. Run all checks"
    echo "2. Check Prometheus and Alertmanager health"
    echo "3. Verify alert rules are loaded"
    echo "4. Check currently firing alerts"
    echo "5. Send test alert"
    echo "6. Validate alert rule syntax"
    echo "7. List all available alerts"
    echo "8. Check alert routing"
    echo "9. Check silences"
    echo "0. Exit"
    echo
    read -p "Select option: " choice

    case $choice in
        1)
            check_prometheus
            check_alertmanager
            verify_alert_rules
            check_firing_alerts
            check_silences
            ;;
        2)
            check_prometheus
            check_alertmanager
            ;;
        3)
            verify_alert_rules
            ;;
        4)
            check_firing_alerts
            ;;
        5)
            send_test_alert
            ;;
        6)
            validate_alert_rules
            ;;
        7)
            list_alerts
            ;;
        8)
            check_alert_routing
            ;;
        9)
            check_silences
            ;;
        0)
            exit 0
            ;;
        *)
            log_error "Invalid option"
            ;;
    esac
}

# Main function
main() {
    if [ $# -eq 0 ]; then
        while true; do
            show_menu
            echo
            read -p "Press Enter to continue..."
        done
    else
        case "$1" in
            health)
                check_prometheus
                check_alertmanager
                ;;
            rules)
                verify_alert_rules
                ;;
            firing)
                check_firing_alerts
                ;;
            test)
                send_test_alert
                ;;
            validate)
                validate_alert_rules
                ;;
            list)
                list_alerts
                ;;
            routing)
                check_alert_routing
                ;;
            silences)
                check_silences
                ;;
            all)
                check_prometheus
                check_alertmanager
                verify_alert_rules
                check_firing_alerts
                check_silences
                ;;
            *)
                echo "Usage: $0 [health|rules|firing|test|validate|list|routing|silences|all]"
                exit 1
                ;;
        esac
    fi
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
