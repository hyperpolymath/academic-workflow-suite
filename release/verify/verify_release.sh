#!/bin/bash
# Verify release artifacts for Academic Workflow Suite
# Usage: ./verify_release.sh VERSION

set -euo pipefail

VERSION=${1:-}
if [ -z "$VERSION" ]; then
    echo "Usage: $0 VERSION"
    echo "Example: $0 1.0.0"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_DIR="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$RELEASE_DIR/dist"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    WARN_COUNT=$((WARN_COUNT + 1))
}

# Check if distribution directory exists
check_dist_dir() {
    log_info "Checking distribution directory..."

    if [ ! -d "$DIST_DIR" ]; then
        log_error "Distribution directory not found: $DIST_DIR"
        return 1
    fi

    log_success "Distribution directory exists"
}

# Check for required packages
check_packages() {
    log_info "Checking for required packages..."

    local required_files=(
        "academic-workflow-suite-${VERSION}.tar.gz"
        "academic-workflow-suite-${VERSION}.zip"
        "SHA256SUMS"
    )

    for file in "${required_files[@]}"; do
        if [ -f "$DIST_DIR/$file" ]; then
            log_success "Found: $file"
        else
            log_warning "Missing: $file"
        fi
    done

    # Check for platform-specific packages
    if [ -f "$DIST_DIR/academic-workflow-suite_${VERSION}_amd64.deb" ]; then
        log_success "Found: Debian package"
    else
        log_warning "Missing: Debian package"
    fi

    if ls "$DIST_DIR"/academic-workflow-suite-${VERSION}*.rpm 1> /dev/null 2>&1; then
        log_success "Found: RPM package"
    else
        log_warning "Missing: RPM package"
    fi
}

# Verify checksums
verify_checksums() {
    log_info "Verifying checksums..."

    if [ ! -f "$DIST_DIR/SHA256SUMS" ]; then
        log_error "SHA256SUMS file not found"
        return 1
    fi

    local original_dir=$(pwd)
    cd "$DIST_DIR"

    if sha256sum -c SHA256SUMS 2>&1 | grep -q "FAILED"; then
        log_error "Checksum verification failed"
        sha256sum -c SHA256SUMS
        cd "$original_dir"
        return 1
    else
        log_success "All checksums verified"
    fi

    cd "$original_dir"
}

# Verify GPG signatures
verify_signatures() {
    log_info "Verifying GPG signatures..."

    local has_signatures=false

    for sig_file in "$DIST_DIR"/*.asc; do
        if [ -f "$sig_file" ]; then
            has_signatures=true
            local file="${sig_file%.asc}"

            if gpg --verify "$sig_file" "$file" 2>/dev/null; then
                log_success "Valid signature: $(basename "$sig_file")"
            else
                log_warning "Could not verify signature: $(basename "$sig_file")"
            fi
        fi
    done

    if [ "$has_signatures" = false ]; then
        log_warning "No GPG signatures found"
    fi
}

# Check archive contents
check_archive_contents() {
    log_info "Checking archive contents..."

    local tarball="$DIST_DIR/academic-workflow-suite-${VERSION}.tar.gz"

    if [ ! -f "$tarball" ]; then
        log_error "Tarball not found: $tarball"
        return 1
    fi

    # Extract to temp directory
    local temp_dir=$(mktemp -d)
    tar -xzf "$tarball" -C "$temp_dir"

    # Check for essential files
    local essential_files=(
        "README.md"
        "LICENSE"
    )

    local found_all=true
    for file in "${essential_files[@]}"; do
        if find "$temp_dir" -name "$file" | grep -q .; then
            log_success "Found in archive: $file"
        else
            log_warning "Missing in archive: $file"
            found_all=false
        fi
    done

    rm -rf "$temp_dir"

    if [ "$found_all" = true ]; then
        log_success "Archive contents verified"
    fi
}

# Check binary architecture
check_binary_arch() {
    log_info "Checking binary architecture..."

    # Extract binary from tarball
    local tarball="$DIST_DIR/academic-workflow-suite-${VERSION}.tar.gz"
    if [ ! -f "$tarball" ]; then
        log_warning "Cannot check binary: tarball not found"
        return
    fi

    local temp_dir=$(mktemp -d)
    tar -xzf "$tarball" -C "$temp_dir"

    # Find the binary
    local binary=$(find "$temp_dir" -type f -name "aws" | head -1)

    if [ -z "$binary" ]; then
        log_warning "Binary 'aws' not found in archive"
        rm -rf "$temp_dir"
        return
    fi

    # Check if it's executable
    if [ -x "$binary" ]; then
        log_success "Binary is executable"
    else
        log_error "Binary is not executable"
    fi

    # Check architecture
    if command -v file &> /dev/null; then
        local file_info=$(file "$binary")
        log_info "Binary info: $file_info"

        if echo "$file_info" | grep -q "x86-64\|x86_64\|amd64"; then
            log_success "Binary is x86_64"
        elif echo "$file_info" | grep -q "ARM\|aarch64"; then
            log_success "Binary is ARM/aarch64"
        else
            log_warning "Unknown architecture"
        fi
    fi

    rm -rf "$temp_dir"
}

# Check package integrity
check_package_integrity() {
    log_info "Checking package integrity..."

    # Check .deb package
    local deb_file="$DIST_DIR/academic-workflow-suite_${VERSION}_amd64.deb"
    if [ -f "$deb_file" ]; then
        if command -v dpkg &> /dev/null; then
            if dpkg-deb --info "$deb_file" &> /dev/null; then
                log_success "Debian package is valid"

                # Check package contents
                if dpkg-deb -c "$deb_file" | grep -q "usr/bin/aws"; then
                    log_success "Debian package contains binary"
                else
                    log_error "Debian package missing binary"
                fi
            else
                log_error "Debian package is corrupted"
            fi
        else
            log_warning "dpkg not available, skipping .deb validation"
        fi
    fi

    # Check .rpm package
    local rpm_file=$(ls "$DIST_DIR"/academic-workflow-suite-${VERSION}*.rpm 2>/dev/null | head -1)
    if [ -f "$rpm_file" ]; then
        if command -v rpm &> /dev/null; then
            if rpm -qpl "$rpm_file" &> /dev/null; then
                log_success "RPM package is valid"

                # Check package contents
                if rpm -qpl "$rpm_file" | grep -q "bin/aws"; then
                    log_success "RPM package contains binary"
                else
                    log_error "RPM package missing binary"
                fi
            else
                log_error "RPM package is corrupted"
            fi
        else
            log_warning "rpm not available, skipping .rpm validation"
        fi
    fi
}

# Check file sizes
check_file_sizes() {
    log_info "Checking file sizes..."

    # Check if files are not empty and have reasonable sizes
    for file in "$DIST_DIR"/*; do
        if [ -f "$file" ]; then
            local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
            local filename=$(basename "$file")

            if [ "$size" -eq 0 ]; then
                log_error "File is empty: $filename"
            elif [ "$size" -lt 1000 ] && [[ ! "$filename" =~ \.(asc|txt|md)$ ]]; then
                log_warning "File suspiciously small: $filename (${size} bytes)"
            else
                # Convert to human-readable
                local size_hr
                if [ "$size" -gt 1048576 ]; then
                    size_hr="$(($size / 1048576)) MB"
                elif [ "$size" -gt 1024 ]; then
                    size_hr="$(($size / 1024)) KB"
                else
                    size_hr="${size} bytes"
                fi
                log_success "$filename: $size_hr"
            fi
        fi
    done
}

# Check version consistency
check_version_consistency() {
    log_info "Checking version consistency..."

    local version_file="$RELEASE_DIR/../VERSION"

    if [ -f "$version_file" ]; then
        local file_version=$(cat "$version_file")
        if [ "$file_version" = "$VERSION" ]; then
            log_success "VERSION file matches: $VERSION"
        else
            log_error "VERSION file mismatch: expected $VERSION, got $file_version"
        fi
    else
        log_warning "VERSION file not found"
    fi
}

# Generate report
generate_report() {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  Verification Report - v$VERSION"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    echo -e "${GREEN}PASSED:${NC}  $PASS_COUNT checks"
    echo -e "${YELLOW}WARNINGS:${NC} $WARN_COUNT checks"
    echo -e "${RED}FAILED:${NC}  $FAIL_COUNT checks"
    echo ""

    if [ $FAIL_COUNT -eq 0 ]; then
        echo -e "${GREEN}✓ All critical checks passed!${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}✗ Some checks failed. Please review the issues above.${NC}"
        echo ""
        return 1
    fi
}

# Main verification flow
main() {
    echo "═══════════════════════════════════════════════════════"
    echo "  Academic Workflow Suite - Release Verification"
    echo "  Version: $VERSION"
    echo "═══════════════════════════════════════════════════════"
    echo ""

    check_dist_dir
    check_packages
    verify_checksums
    verify_signatures
    check_archive_contents
    check_binary_arch
    check_package_integrity
    check_file_sizes
    check_version_consistency

    generate_report
}

main
