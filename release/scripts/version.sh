#!/bin/bash
# Version management script for Academic Workflow Suite
# Usage: ./version.sh [current|bump|set] [major|minor|patch|VERSION]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$RELEASE_DIR")"

VERSION_FILE="$PROJECT_ROOT/VERSION"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Get current version
get_current_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "0.1.0"
    fi
}

# Parse version into components
parse_version() {
    local version=$1

    # Remove 'v' prefix if present
    version=${version#v}

    # Split into components
    local major=$(echo "$version" | cut -d. -f1)
    local minor=$(echo "$version" | cut -d. -f2)
    local patch=$(echo "$version" | cut -d. -f3)

    echo "$major $minor $patch"
}

# Bump version
bump_version() {
    local bump_type=$1
    local current_version=$(get_current_version)

    read -r major minor patch <<< "$(parse_version "$current_version")"

    case $bump_type in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            log_error "Invalid bump type: $bump_type (must be major, minor, or patch)"
            exit 1
            ;;
    esac

    local new_version="${major}.${minor}.${patch}"
    echo "$new_version"
}

# Set version in VERSION file
set_version_file() {
    local version=$1
    echo "$version" > "$VERSION_FILE"
    log_success "Updated VERSION file to $version"
}

# Update version in Cargo.toml files
update_cargo_toml() {
    local version=$1

    while IFS= read -r -d '' file; do
        if grep -q '^version = ' "$file"; then
            sed -i "s/^version = \".*\"/version = \"$version\"/" "$file"
            log_success "Updated $file"
        fi
    done < <(find "$PROJECT_ROOT" -name "Cargo.toml" -type f -print0)
}

# Update version in package.json files
update_package_json() {
    local version=$1

    while IFS= read -r -d '' file; do
        if command -v jq &> /dev/null; then
            local temp_file=$(mktemp)
            jq ".version = \"$version\"" "$file" > "$temp_file"
            mv "$temp_file" "$file"
            log_success "Updated $file"
        else
            sed -i "s/\"version\": \".*\"/\"version\": \"$version\"/" "$file"
            log_success "Updated $file"
        fi
    done < <(find "$PROJECT_ROOT" -name "package.json" -type f -print0)
}

# Update version in mix.exs
update_mix_exs() {
    local version=$1

    while IFS= read -r -d '' file; do
        if grep -q 'version: ' "$file"; then
            sed -i "s/version: \".*\"/version: \"$version\"/" "$file"
            log_success "Updated $file"
        fi
    done < <(find "$PROJECT_ROOT" -name "mix.exs" -type f -print0)
}

# Update version in Python files
update_python_version() {
    local version=$1

    # Update setup.py
    if [ -f "$PROJECT_ROOT/setup.py" ]; then
        sed -i "s/version=['\"].*['\"]/version='$version'/" "$PROJECT_ROOT/setup.py"
        log_success "Updated setup.py"
    fi

    # Update __init__.py
    while IFS= read -r -d '' file; do
        if grep -q '__version__' "$file"; then
            sed -i "s/__version__ = ['\"].*['\"]/__version__ = '$version'/" "$file"
            log_success "Updated $file"
        fi
    done < <(find "$PROJECT_ROOT" -name "__init__.py" -type f -print0)
}

# Update version in documentation
update_documentation() {
    local version=$1

    # Update README.md
    if [ -f "$PROJECT_ROOT/README.md" ]; then
        # Update badge version if exists
        sed -i "s/version-[0-9.]*-/version-$version-/" "$PROJECT_ROOT/README.md" 2>/dev/null || true
        log_success "Updated README.md"
    fi

    # Update CLAUDE.md
    if [ -f "$PROJECT_ROOT/CLAUDE.md" ]; then
        sed -i "s/Last Updated.*/Last Updated**: $(date +%Y-%m-%d)/" "$PROJECT_ROOT/CLAUDE.md"
        log_success "Updated CLAUDE.md"
    fi
}

# Update all version references
update_all_versions() {
    local version=$1

    log_info "Updating version to $version in all files..."

    set_version_file "$version"
    update_cargo_toml "$version"
    update_package_json "$version"
    update_mix_exs "$version"
    update_python_version "$version"
    update_documentation "$version"

    log_success "All version references updated to $version"
}

# Validate version format
validate_version() {
    local version=$1

    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Invalid version format: $version (must be X.Y.Z)"
        exit 1
    fi
}

# Validate version consistency
validate_consistency() {
    log_info "Validating version consistency..."

    local version=$(get_current_version)
    local errors=0

    # Check Cargo.toml files
    while IFS= read -r -d '' file; do
        local cargo_version=$(grep '^version = ' "$file" | head -1 | sed 's/version = "\(.*\)"/\1/')
        if [ -n "$cargo_version" ] && [ "$cargo_version" != "$version" ]; then
            log_error "Version mismatch in $file: $cargo_version (expected $version)"
            errors=$((errors + 1))
        fi
    done < <(find "$PROJECT_ROOT" -name "Cargo.toml" -type f -print0)

    # Check package.json files
    while IFS= read -r -d '' file; do
        local npm_version=$(grep '"version":' "$file" | head -1 | sed 's/.*"version": "\(.*\)".*/\1/')
        if [ -n "$npm_version" ] && [ "$npm_version" != "$version" ]; then
            log_error "Version mismatch in $file: $npm_version (expected $version)"
            errors=$((errors + 1))
        fi
    done < <(find "$PROJECT_ROOT" -name "package.json" -type f -print0)

    if [ $errors -eq 0 ]; then
        log_success "Version consistency check passed"
        return 0
    else
        log_error "Found $errors version inconsistencies"
        return 1
    fi
}

# Show usage
show_usage() {
    cat << EOF
Version Management Script for Academic Workflow Suite

Usage: $0 COMMAND [OPTIONS]

Commands:
    current                 Display current version
    bump TYPE              Bump version (TYPE: major, minor, patch)
    set VERSION            Set specific version (format: X.Y.Z)
    validate               Validate version consistency across files

Examples:
    $0 current             # Show current version
    $0 bump minor          # Bump minor version (1.2.3 -> 1.3.0)
    $0 set 2.0.0           # Set version to 2.0.0
    $0 validate            # Check version consistency

EOF
}

# Main function
main() {
    case "${1:-}" in
        current)
            get_current_version
            ;;
        bump)
            if [ $# -lt 2 ]; then
                log_error "Missing bump type"
                show_usage
                exit 1
            fi
            new_version=$(bump_version "$2")
            update_all_versions "$new_version"
            echo "$new_version"
            ;;
        set)
            if [ $# -lt 2 ]; then
                log_error "Missing version"
                show_usage
                exit 1
            fi
            validate_version "$2"
            update_all_versions "$2"
            echo "$2"
            ;;
        validate)
            validate_consistency
            ;;
        -h|--help|help)
            show_usage
            ;;
        *)
            log_error "Unknown command: ${1:-}"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
