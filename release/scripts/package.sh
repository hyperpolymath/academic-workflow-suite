#!/bin/bash
# Package script for Academic Workflow Suite
# Usage: ./package.sh [--all|--deb|--rpm|--macos|--windows] [options]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$RELEASE_DIR")"
PACKAGING_DIR="$RELEASE_DIR/packaging"
DIST_DIR="$RELEASE_DIR/dist"

# Get version
VERSION=$("$SCRIPT_DIR/version.sh" current)

# Platform selection
BUILD_DEB=false
BUILD_RPM=false
BUILD_MACOS=false
BUILD_WINDOWS=false
BUILD_ARCHIVE=true
SIGN_PACKAGES=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            BUILD_DEB=true
            BUILD_RPM=true
            BUILD_MACOS=true
            BUILD_WINDOWS=true
            shift
            ;;
        --deb)
            BUILD_DEB=true
            shift
            ;;
        --rpm)
            BUILD_RPM=true
            shift
            ;;
        --macos)
            BUILD_MACOS=true
            shift
            ;;
        --windows)
            BUILD_WINDOWS=true
            shift
            ;;
        --sign)
            SIGN_PACKAGES=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --all       Build all package types"
            echo "  --deb       Build Debian/Ubuntu packages"
            echo "  --rpm       Build RPM packages"
            echo "  --macos     Build macOS packages"
            echo "  --windows   Build Windows installer"
            echo "  --sign      Sign packages with GPG"
            echo "  -h, --help  Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Prepare distribution directory
prepare_dist() {
    log_info "Preparing distribution directory..."
    mkdir -p "$DIST_DIR"
    rm -rf "$DIST_DIR"/*
    log_success "Distribution directory ready"
}

# Create source archive
create_source_archive() {
    log_info "Creating source archives..."

    local archive_name="academic-workflow-suite-${VERSION}"
    local temp_dir=$(mktemp -d)

    # Copy source files
    git archive --format=tar --prefix="${archive_name}/" HEAD | tar -x -C "$temp_dir"

    # Create tar.gz
    tar -czf "$DIST_DIR/${archive_name}.tar.gz" -C "$temp_dir" "${archive_name}"

    # Create zip
    (cd "$temp_dir" && zip -r "$DIST_DIR/${archive_name}.zip" "${archive_name}")

    rm -rf "$temp_dir"

    log_success "Source archives created"
}

# Build Debian package
build_deb() {
    if [ "$BUILD_DEB" = false ]; then
        return
    fi

    log_info "Building Debian package..."

    local build_dir=$(mktemp -d)
    local pkg_name="academic-workflow-suite"
    local pkg_dir="${build_dir}/${pkg_name}_${VERSION}"

    # Create package structure
    mkdir -p "${pkg_dir}/DEBIAN"
    mkdir -p "${pkg_dir}/usr/bin"
    mkdir -p "${pkg_dir}/usr/share/doc/${pkg_name}"
    mkdir -p "${pkg_dir}/usr/share/man/man1"

    # Copy control files
    cp "$PACKAGING_DIR/debian/control" "${pkg_dir}/DEBIAN/"
    cp "$PACKAGING_DIR/debian/postinst" "${pkg_dir}/DEBIAN/" 2>/dev/null || true
    cp "$PACKAGING_DIR/debian/prerm" "${pkg_dir}/DEBIAN/" 2>/dev/null || true
    cp "$PACKAGING_DIR/debian/postrm" "${pkg_dir}/DEBIAN/" 2>/dev/null || true

    # Set permissions
    chmod 755 "${pkg_dir}/DEBIAN/postinst" 2>/dev/null || true
    chmod 755 "${pkg_dir}/DEBIAN/prerm" 2>/dev/null || true
    chmod 755 "${pkg_dir}/DEBIAN/postrm" 2>/dev/null || true

    # Update version in control file
    sed -i "s/{{VERSION}}/${VERSION}/g" "${pkg_dir}/DEBIAN/control"

    # Copy binaries
    if [ -f "$PROJECT_ROOT/target/release/aws" ]; then
        cp "$PROJECT_ROOT/target/release/aws" "${pkg_dir}/usr/bin/"
    fi

    # Copy documentation
    cp "$PROJECT_ROOT/README.md" "${pkg_dir}/usr/share/doc/${pkg_name}/" 2>/dev/null || true
    cp "$PROJECT_ROOT/LICENSE" "${pkg_dir}/usr/share/doc/${pkg_name}/" 2>/dev/null || true

    # Build package
    dpkg-deb --build "$pkg_dir" "$DIST_DIR/${pkg_name}_${VERSION}_amd64.deb"

    rm -rf "$build_dir"

    log_success "Debian package created"
}

# Build RPM package
build_rpm() {
    if [ "$BUILD_RPM" = false ]; then
        return
    fi

    log_info "Building RPM package..."

    if ! command -v rpmbuild &> /dev/null; then
        log_warning "rpmbuild not found, skipping RPM package"
        return
    fi

    local rpm_root="$HOME/rpmbuild"
    mkdir -p "$rpm_root"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

    # Create source tarball
    local archive_name="academic-workflow-suite-${VERSION}.tar.gz"
    cp "$DIST_DIR/academic-workflow-suite-${VERSION}.tar.gz" "$rpm_root/SOURCES/" 2>/dev/null || \
        tar -czf "$rpm_root/SOURCES/${archive_name}" -C "$PROJECT_ROOT" .

    # Copy and update spec file
    local spec_file="$rpm_root/SPECS/aws.spec"
    cp "$PACKAGING_DIR/rpm/aws.spec" "$spec_file"
    sed -i "s/{{VERSION}}/${VERSION}/g" "$spec_file"

    # Build RPM
    rpmbuild -ba "$spec_file"

    # Copy RPM to dist
    cp "$rpm_root/RPMS/x86_64/academic-workflow-suite-${VERSION}"*.rpm "$DIST_DIR/" 2>/dev/null || true

    log_success "RPM package created"
}

# Build macOS package
build_macos() {
    if [ "$BUILD_MACOS" = false ]; then
        return
    fi

    log_info "Building macOS package..."

    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_warning "Not on macOS, skipping macOS package"
        return
    fi

    local pkg_name="academic-workflow-suite"
    local build_dir=$(mktemp -d)
    local root_dir="${build_dir}/root"
    local scripts_dir="${build_dir}/scripts"

    # Create directory structure
    mkdir -p "${root_dir}/usr/local/bin"
    mkdir -p "$scripts_dir"

    # Copy binaries
    if [ -f "$PROJECT_ROOT/target/release/aws" ]; then
        cp "$PROJECT_ROOT/target/release/aws" "${root_dir}/usr/local/bin/"
    fi

    # Copy scripts
    cp "$PACKAGING_DIR/macos/scripts/postinstall" "$scripts_dir/" 2>/dev/null || true

    # Build package
    pkgbuild --root "$root_dir" \
             --scripts "$scripts_dir" \
             --identifier "com.academicworkflow.suite" \
             --version "$VERSION" \
             "${build_dir}/${pkg_name}.pkg"

    # Create distribution package if Distribution.xml exists
    if [ -f "$PACKAGING_DIR/macos/Distribution.xml" ]; then
        sed "s/{{VERSION}}/${VERSION}/g" "$PACKAGING_DIR/macos/Distribution.xml" > "${build_dir}/Distribution.xml"

        productbuild --distribution "${build_dir}/Distribution.xml" \
                     --package-path "$build_dir" \
                     "$DIST_DIR/${pkg_name}-${VERSION}.pkg"
    else
        cp "${build_dir}/${pkg_name}.pkg" "$DIST_DIR/${pkg_name}-${VERSION}.pkg"
    fi

    rm -rf "$build_dir"

    log_success "macOS package created"
}

# Build Windows installer
build_windows() {
    if [ "$BUILD_WINDOWS" = false ]; then
        return
    fi

    log_info "Building Windows installer..."

    if ! command -v wix &> /dev/null && ! command -v candle &> /dev/null; then
        log_warning "WiX Toolset not found, skipping Windows installer"
        return
    fi

    local build_dir=$(mktemp -d)

    # Copy WiX files
    cp "$PACKAGING_DIR/windows/installer.wxs" "$build_dir/"
    sed -i "s/{{VERSION}}/${VERSION}/g" "$build_dir/installer.wxs"

    # Compile
    candle "$build_dir/installer.wxs" -out "$build_dir/installer.wixobj"

    # Link
    light "$build_dir/installer.wixobj" -out "$DIST_DIR/academic-workflow-suite-${VERSION}.msi"

    rm -rf "$build_dir"

    log_success "Windows installer created"
}

# Generate checksums
generate_checksums() {
    log_info "Generating SHA256 checksums..."

    local checksum_file="$DIST_DIR/SHA256SUMS"

    (cd "$DIST_DIR" && sha256sum * > SHA256SUMS.tmp)
    mv "$DIST_DIR/SHA256SUMS.tmp" "$checksum_file"

    log_success "Checksums generated: $checksum_file"
}

# Sign packages
sign_packages() {
    if [ "$SIGN_PACKAGES" = false ]; then
        return
    fi

    log_info "Signing packages with GPG..."

    for file in "$DIST_DIR"/*.{deb,rpm,pkg,msi,tar.gz,zip} "$DIST_DIR/SHA256SUMS"; do
        if [ -f "$file" ]; then
            gpg --detach-sign --armor "$file"
            log_success "Signed: $(basename "$file")"
        fi
    done

    log_success "All packages signed"
}

# Verify packages
verify_packages() {
    log_info "Verifying packages..."

    # Verify checksums
    (cd "$DIST_DIR" && sha256sum -c SHA256SUMS)

    # List all packages
    log_info "Generated packages:"
    ls -lh "$DIST_DIR"

    log_success "Package verification complete"
}

# Main function
main() {
    echo "═══════════════════════════════════════════════════════"
    echo "  Academic Workflow Suite - Packaging Script"
    echo "  Version: $VERSION"
    echo "═══════════════════════════════════════════════════════"
    echo ""

    prepare_dist

    create_source_archive

    build_deb

    build_rpm

    build_macos

    build_windows

    generate_checksums

    sign_packages

    verify_packages

    echo ""
    echo "═══════════════════════════════════════════════════════"
    log_success "Packaging completed!"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    echo "Packages are available in: $DIST_DIR"
}

main
