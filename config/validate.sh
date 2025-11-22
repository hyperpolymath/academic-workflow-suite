#!/bin/bash

# CUE Configuration Validation Script
# This script validates and exports configuration files for the Academic Workflow Suite

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}"
ENVIRONMENTS_DIR="${CONFIG_DIR}/environments"
OUTPUT_DIR="${CONFIG_DIR}/output"

# Supported environments
ENVIRONMENTS=("production" "staging" "development" "test")

# Output formats
FORMATS=("json" "yaml")

# Print colored message
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if CUE is installed
check_cue_installed() {
    if ! command -v cue &> /dev/null; then
        print_error "CUE is not installed. Please install it from https://cuelang.org/docs/install/"
        echo ""
        echo "Installation instructions:"
        echo "  macOS:   brew install cue-lang/tap/cue"
        echo "  Linux:   go install cuelang.org/go/cmd/cue@latest"
        echo "  Docker:  docker run -it cuelang/cue:latest"
        exit 1
    fi

    print_success "CUE is installed: $(cue version)"
}

# Validate a specific environment configuration
validate_environment() {
    local env="$1"
    local env_file="${ENVIRONMENTS_DIR}/${env}.cue"

    print_info "Validating ${env} environment..."

    if [[ ! -f "${env_file}" ]]; then
        print_error "Environment file not found: ${env_file}"
        return 1
    fi

    # Validate the configuration
    if cue vet "${env_file}" "${CONFIG_DIR}/schema.cue" "${CONFIG_DIR}/validation.cue" 2>&1; then
        print_success "${env} environment configuration is valid"
        return 0
    else
        print_error "${env} environment configuration is invalid"
        return 1
    fi
}

# Export configuration to a specific format
export_config() {
    local env="$1"
    local format="$2"
    local env_file="${ENVIRONMENTS_DIR}/${env}.cue"
    local output_file="${OUTPUT_DIR}/${env}.${format}"

    print_info "Exporting ${env} configuration to ${format}..."

    # Create output directory if it doesn't exist
    mkdir -p "${OUTPUT_DIR}"

    # Export based on format
    case "${format}" in
        json)
            if cue export "${env_file}" --out json > "${output_file}" 2>&1; then
                print_success "Exported to ${output_file}"
                return 0
            else
                print_error "Failed to export to ${format}"
                return 1
            fi
            ;;
        yaml)
            if cue export "${env_file}" --out yaml > "${output_file}" 2>&1; then
                print_success "Exported to ${output_file}"
                return 0
            else
                print_error "Failed to export to ${format}"
                return 1
            fi
            ;;
        *)
            print_error "Unsupported format: ${format}"
            return 1
            ;;
    esac
}

# Validate all environments
validate_all() {
    local failed=0

    print_info "Validating all environments..."
    echo ""

    for env in "${ENVIRONMENTS[@]}"; do
        if ! validate_environment "${env}"; then
            failed=$((failed + 1))
        fi
        echo ""
    done

    if [[ ${failed} -eq 0 ]]; then
        print_success "All environment configurations are valid!"
        return 0
    else
        print_error "${failed} environment(s) failed validation"
        return 1
    fi
}

# Export all configurations
export_all() {
    local format="${1:-json}"
    local failed=0

    print_info "Exporting all configurations to ${format}..."
    echo ""

    for env in "${ENVIRONMENTS[@]}"; do
        if ! export_config "${env}" "${format}"; then
            failed=$((failed + 1))
        fi
    done

    echo ""
    if [[ ${failed} -eq 0 ]]; then
        print_success "All configurations exported successfully!"
        return 0
    else
        print_error "${failed} configuration(s) failed to export"
        return 1
    fi
}

# Check for schema violations
check_violations() {
    local env="$1"
    local env_file="${ENVIRONMENTS_DIR}/${env}.cue"

    print_info "Checking for schema violations in ${env} environment..."

    if cue vet "${env_file}" "${CONFIG_DIR}/schema.cue" "${CONFIG_DIR}/validation.cue" -c 2>&1; then
        print_success "No schema violations found"
        return 0
    else
        print_error "Schema violations detected"
        return 1
    fi
}

# Show configuration for an environment
show_config() {
    local env="$1"
    local format="${2:-json}"
    local env_file="${ENVIRONMENTS_DIR}/${env}.cue"

    print_info "Showing ${env} configuration in ${format} format..."
    echo ""

    case "${format}" in
        json)
            cue export "${env_file}" --out json
            ;;
        yaml)
            cue export "${env_file}" --out yaml
            ;;
        cue)
            cue eval "${env_file}"
            ;;
        *)
            print_error "Unsupported format: ${format}"
            return 1
            ;;
    esac
}

# Diff two environment configurations
diff_configs() {
    local env1="$1"
    local env2="$2"
    local format="${3:-json}"

    print_info "Comparing ${env1} and ${env2} configurations..."
    echo ""

    local temp1="/tmp/cue_${env1}.${format}"
    local temp2="/tmp/cue_${env2}.${format}"

    cue export "${ENVIRONMENTS_DIR}/${env1}.cue" --out "${format}" > "${temp1}"
    cue export "${ENVIRONMENTS_DIR}/${env2}.cue" --out "${format}" > "${temp2}"

    if command -v diff &> /dev/null; then
        diff -u "${temp1}" "${temp2}" || true
    else
        print_warning "diff command not found, showing both files"
        echo "=== ${env1} ==="
        cat "${temp1}"
        echo ""
        echo "=== ${env2} ==="
        cat "${temp2}"
    fi

    rm -f "${temp1}" "${temp2}"
}

# Clean output directory
clean() {
    print_info "Cleaning output directory..."
    rm -rf "${OUTPUT_DIR}"
    print_success "Output directory cleaned"
}

# Display usage information
usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

CUE Configuration Validation and Export Script for Academic Workflow Suite

COMMANDS:
    validate [ENV]          Validate configuration for a specific environment or all
    export [ENV] [FORMAT]   Export configuration to JSON or YAML
    show [ENV] [FORMAT]     Display configuration (formats: json, yaml, cue)
    diff ENV1 ENV2 [FORMAT] Compare two environment configurations
    check [ENV]             Check for schema violations
    clean                   Clean output directory
    help                    Show this help message

ENVIRONMENTS:
    production              Production environment
    staging                 Staging environment
    development             Development environment
    test                    Test environment
    all                     All environments (default for validate/export)

FORMATS:
    json                    JSON format (default)
    yaml                    YAML format
    cue                     CUE format (show only)

EXAMPLES:
    $0 validate                         # Validate all environments
    $0 validate production              # Validate production environment
    $0 export production json           # Export production config to JSON
    $0 export all yaml                  # Export all configs to YAML
    $0 show development yaml            # Show development config in YAML
    $0 diff production staging          # Compare production and staging
    $0 check production                 # Check production for violations
    $0 clean                            # Clean output directory

EOF
}

# Main script logic
main() {
    # Check if CUE is installed
    check_cue_installed
    echo ""

    # Parse command
    local command="${1:-validate}"

    case "${command}" in
        validate)
            local env="${2:-all}"
            if [[ "${env}" == "all" ]]; then
                validate_all
            else
                validate_environment "${env}"
            fi
            ;;
        export)
            local env="${2:-all}"
            local format="${3:-json}"
            if [[ "${env}" == "all" ]]; then
                export_all "${format}"
            else
                export_config "${env}" "${format}"
            fi
            ;;
        show)
            local env="${2:-}"
            local format="${3:-json}"
            if [[ -z "${env}" ]]; then
                print_error "Environment is required for 'show' command"
                echo ""
                usage
                exit 1
            fi
            show_config "${env}" "${format}"
            ;;
        diff)
            local env1="${2:-}"
            local env2="${3:-}"
            local format="${4:-json}"
            if [[ -z "${env1}" ]] || [[ -z "${env2}" ]]; then
                print_error "Two environments are required for 'diff' command"
                echo ""
                usage
                exit 1
            fi
            diff_configs "${env1}" "${env2}" "${format}"
            ;;
        check)
            local env="${2:-all}"
            if [[ "${env}" == "all" ]]; then
                for e in "${ENVIRONMENTS[@]}"; do
                    check_violations "${e}"
                    echo ""
                done
            else
                check_violations "${env}"
            fi
            ;;
        clean)
            clean
            ;;
        help|--help|-h)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown command: ${command}"
            echo ""
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
