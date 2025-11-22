#!/bin/bash
# Main release script for Academic Workflow Suite
# Usage: ./release.sh [major|minor|patch] [--dry-run]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$RELEASE_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DRY_RUN=false
SKIP_TESTS=false
SKIP_BUILD=false
SKIP_PACKAGE=false
SKIP_UPLOAD=false
VERSION_TYPE="patch"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        major|minor|patch)
            VERSION_TYPE="$1"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-package)
            SKIP_PACKAGE=true
            shift
            ;;
        --skip-upload)
            SKIP_UPLOAD=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [major|minor|patch] [options]"
            echo ""
            echo "Options:"
            echo "  --dry-run       Simulate release without making changes"
            echo "  --skip-tests    Skip test suite"
            echo "  --skip-build    Skip build process"
            echo "  --skip-package  Skip packaging"
            echo "  --skip-upload   Skip artifact upload"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

run_command() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $*"
    else
        "$@"
    fi
}

# Pre-release checks
pre_release_checks() {
    log_info "Running pre-release checks..."

    # Check if git is clean
    if ! git diff-index --quiet HEAD --; then
        log_error "Git working directory is not clean. Commit or stash changes first."
        exit 1
    fi

    # Check if on main branch
    CURRENT_BRANCH=$(git branch --show-current)
    if [[ "$CURRENT_BRANCH" != "main" ]] && [[ "$CURRENT_BRANCH" != "master" ]]; then
        log_warning "Not on main/master branch (current: $CURRENT_BRANCH)"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Check if all required tools are installed
    local required_tools=("git" "jq" "sha256sum" "gpg")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "Required tool '$tool' not found"
            exit 1
        fi
    done

    log_success "Pre-release checks passed"
}

# Bump version
bump_version() {
    log_info "Bumping version ($VERSION_TYPE)..."

    if [ "$DRY_RUN" = false ]; then
        "$SCRIPT_DIR/version.sh" bump "$VERSION_TYPE"
        NEW_VERSION=$("$SCRIPT_DIR/version.sh" current)
    else
        NEW_VERSION="0.0.0-dryrun"
    fi

    log_success "Version bumped to $NEW_VERSION"
    echo "$NEW_VERSION"
}

# Generate changelog
generate_changelog() {
    local version=$1
    log_info "Generating changelog for version $version..."

    local changelog_file="$PROJECT_ROOT/CHANGELOG.md"
    local temp_changelog=$(mktemp)

    # Get the previous tag
    local prev_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

    # Generate changelog entry
    echo "## [$version] - $(date +%Y-%m-%d)" > "$temp_changelog"
    echo "" >> "$temp_changelog"

    # Group commits by type
    if [ -n "$prev_tag" ]; then
        echo "### Added" >> "$temp_changelog"
        git log "$prev_tag..HEAD" --pretty=format:"- %s" --grep="^feat" >> "$temp_changelog" || true
        echo "" >> "$temp_changelog"

        echo "### Fixed" >> "$temp_changelog"
        git log "$prev_tag..HEAD" --pretty=format:"- %s" --grep="^fix" >> "$temp_changelog" || true
        echo "" >> "$temp_changelog"

        echo "### Changed" >> "$temp_changelog"
        git log "$prev_tag..HEAD" --pretty=format:"- %s" --grep="^chore\|^refactor" >> "$temp_changelog" || true
        echo "" >> "$temp_changelog"
    else
        echo "### Initial Release" >> "$temp_changelog"
        git log --pretty=format:"- %s" >> "$temp_changelog"
        echo "" >> "$temp_changelog"
    fi

    # Prepend to existing changelog
    if [ -f "$changelog_file" ]; then
        cat "$changelog_file" >> "$temp_changelog"
    fi

    run_command mv "$temp_changelog" "$changelog_file"

    log_success "Changelog generated"
}

# Run tests
run_tests() {
    if [ "$SKIP_TESTS" = true ]; then
        log_warning "Skipping tests"
        return
    fi

    log_info "Running test suite..."

    # Run different test suites based on project components
    if [ -f "$PROJECT_ROOT/Cargo.toml" ]; then
        run_command cargo test --all
    fi

    if [ -f "$PROJECT_ROOT/package.json" ]; then
        run_command npm test
    fi

    if [ -f "$PROJECT_ROOT/mix.exs" ]; then
        run_command mix test
    fi

    log_success "All tests passed"
}

# Build project
build_project() {
    if [ "$SKIP_BUILD" = true ]; then
        log_warning "Skipping build"
        return
    fi

    log_info "Building project..."

    # Build Rust components
    if [ -f "$PROJECT_ROOT/Cargo.toml" ]; then
        run_command cargo build --release
    fi

    # Build Node.js components
    if [ -f "$PROJECT_ROOT/package.json" ]; then
        run_command npm run build
    fi

    # Build Elixir components
    if [ -f "$PROJECT_ROOT/mix.exs" ]; then
        run_command mix compile
        run_command mix release
    fi

    log_success "Build completed"
}

# Package for all platforms
package_all() {
    if [ "$SKIP_PACKAGE" = true ]; then
        log_warning "Skipping packaging"
        return
    fi

    log_info "Packaging for all platforms..."

    run_command "$SCRIPT_DIR/package.sh" --all

    log_success "Packaging completed"
}

# Create git tag
create_tag() {
    local version=$1
    log_info "Creating git tag v$version..."

    run_command git add -A
    run_command git commit -m "Release v$version"
    run_command git tag -a "v$version" -m "Release v$version"

    log_success "Tag created: v$version"
}

# Generate release notes
generate_release_notes() {
    local version=$1
    log_info "Generating release notes..."

    local template="$RELEASE_DIR/templates/RELEASE_NOTES.md.tmpl"
    local output="$RELEASE_DIR/release-notes-$version.md"

    if [ -f "$template" ]; then
        sed "s/{{VERSION}}/$version/g; s/{{DATE}}/$(date +%Y-%m-%d)/g" "$template" > "$output"

        # Append changelog section
        echo "" >> "$output"
        echo "## Changelog" >> "$output"
        sed -n "/## \[$version\]/,/## \[/p" "$PROJECT_ROOT/CHANGELOG.md" | head -n -1 >> "$output"
    else
        echo "# Release Notes - v$version" > "$output"
        echo "" >> "$output"
        echo "Released on $(date +%Y-%m-%d)" >> "$output"
    fi

    log_success "Release notes generated: $output"
}

# Create GitHub release
create_github_release() {
    local version=$1

    if [ "$SKIP_UPLOAD" = true ]; then
        log_warning "Skipping GitHub release creation"
        return
    fi

    log_info "Creating GitHub release..."

    if ! command -v gh &> /dev/null; then
        log_warning "GitHub CLI (gh) not found, skipping GitHub release"
        return
    fi

    local release_notes="$RELEASE_DIR/release-notes-$version.md"

    if [ "$DRY_RUN" = false ]; then
        gh release create "v$version" \
            --title "Release v$version" \
            --notes-file "$release_notes" \
            "$RELEASE_DIR"/dist/*
    else
        log_info "Would create GitHub release v$version with artifacts from $RELEASE_DIR/dist/"
    fi

    log_success "GitHub release created"
}

# Push to remote
push_release() {
    local version=$1
    log_info "Pushing release to remote..."

    run_command git push origin main
    run_command git push origin "v$version"

    log_success "Release pushed to remote"
}

# Main release flow
main() {
    echo "═══════════════════════════════════════════════════════"
    echo "  Academic Workflow Suite - Release Script"
    echo "═══════════════════════════════════════════════════════"
    echo ""

    pre_release_checks

    NEW_VERSION=$(bump_version)

    generate_changelog "$NEW_VERSION"

    run_tests

    build_project

    package_all

    create_tag "$NEW_VERSION"

    generate_release_notes "$NEW_VERSION"

    if [ "$DRY_RUN" = false ]; then
        push_release "$NEW_VERSION"
        create_github_release "$NEW_VERSION"
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════"
    log_success "Release v$NEW_VERSION completed successfully!"
    echo "═══════════════════════════════════════════════════════"
    echo ""

    if [ "$DRY_RUN" = true ]; then
        log_warning "This was a dry run. No changes were made."
    else
        echo "Next steps:"
        echo "  1. Verify the release on GitHub"
        echo "  2. Update documentation"
        echo "  3. Announce the release"
    fi
}

# Run main function
main
