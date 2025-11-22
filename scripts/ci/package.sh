#!/bin/bash
# Package Academic Workflow Suite for distribution
# Usage: ./package.sh [deb|msi|dmg|all]

set -e
set -u
set -o pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PACKAGES_DIR="${ROOT_DIR}/packages"
VERSION="${VERSION:-0.1.0}"
PACKAGE_TYPE="${1:-all}"

# Component paths
CORE_BINARY="${ROOT_DIR}/components/core/target/release/academic-workflow-core"
AI_JAIL_BINARY="${ROOT_DIR}/components/ai-jail/target/release/ai-jail"
BACKEND_DIR="${ROOT_DIR}/components/backend/_build/prod"
OFFICE_ADDIN_DIR="${ROOT_DIR}/components/office-addin/dist"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Create packages directory
mkdir -p "$PACKAGES_DIR"

# Package Debian (.deb)
package_deb() {
    log_info "Creating Debian package..."

    local deb_dir="${PACKAGES_DIR}/deb"
    local package_name="academic-workflow-suite"
    local package_version="$VERSION"
    local architecture="amd64"

    # Create directory structure
    mkdir -p "${deb_dir}/DEBIAN"
    mkdir -p "${deb_dir}/usr/bin"
    mkdir -p "${deb_dir}/usr/lib/${package_name}"
    mkdir -p "${deb_dir}/usr/share/doc/${package_name}"
    mkdir -p "${deb_dir}/etc/${package_name}"

    # Copy binaries
    if [ -f "$CORE_BINARY" ]; then
        cp "$CORE_BINARY" "${deb_dir}/usr/bin/aws-core"
        chmod 755 "${deb_dir}/usr/bin/aws-core"
        log_info "Copied core binary"
    else
        log_warning "Core binary not found: $CORE_BINARY"
    fi

    if [ -f "$AI_JAIL_BINARY" ]; then
        cp "$AI_JAIL_BINARY" "${deb_dir}/usr/lib/${package_name}/ai-jail"
        chmod 755 "${deb_dir}/usr/lib/${package_name}/ai-jail"
        log_info "Copied AI jail binary"
    else
        log_warning "AI jail binary not found: $AI_JAIL_BINARY"
    fi

    # Copy documentation
    if [ -f "${ROOT_DIR}/README.md" ]; then
        cp "${ROOT_DIR}/README.md" "${deb_dir}/usr/share/doc/${package_name}/"
    fi

    if [ -f "${ROOT_DIR}/LICENSE" ]; then
        cp "${ROOT_DIR}/LICENSE" "${deb_dir}/usr/share/doc/${package_name}/"
    fi

    # Create control file
    cat > "${deb_dir}/DEBIAN/control" <<EOF
Package: ${package_name}
Version: ${package_version}
Section: utils
Priority: optional
Architecture: ${architecture}
Maintainer: Academic Workflow Suite Team <dev@example.com>
Description: Academic Workflow Suite - Tools for Academic Productivity
 The Academic Workflow Suite provides a comprehensive set of tools
 for managing academic workflows, including citation management,
 paper organization, and AI-assisted research tools.
 .
 This package includes the core application, AI jail for secure
 processing, and integration tools.
Depends: libc6 (>= 2.31)
Homepage: https://github.com/academic-workflow-suite
EOF

    # Create postinst script
    cat > "${deb_dir}/DEBIAN/postinst" <<'EOF'
#!/bin/bash
set -e

# Create symlinks
if [ ! -L /usr/bin/aws ]; then
    ln -s /usr/bin/aws-core /usr/bin/aws
fi

# Set up configuration directory
if [ ! -d /etc/academic-workflow-suite ]; then
    mkdir -p /etc/academic-workflow-suite
fi

echo "Academic Workflow Suite installed successfully!"
echo "Run 'aws --help' to get started."

exit 0
EOF

    chmod 755 "${deb_dir}/DEBIAN/postinst"

    # Create prerm script
    cat > "${deb_dir}/DEBIAN/prerm" <<'EOF'
#!/bin/bash
set -e

# Remove symlink
if [ -L /usr/bin/aws ]; then
    rm -f /usr/bin/aws
fi

exit 0
EOF

    chmod 755 "${deb_dir}/DEBIAN/prerm"

    # Build the package
    local deb_file="${PACKAGES_DIR}/${package_name}_${package_version}_${architecture}.deb"

    if command -v dpkg-deb &> /dev/null; then
        dpkg-deb --build "$deb_dir" "$deb_file"

        # Generate checksum
        sha256sum "$deb_file" > "${deb_file}.sha256"

        log_success "Debian package created: $deb_file"
        ls -lh "$deb_file"
    else
        log_error "dpkg-deb not found. Install dpkg-dev package."
        return 1
    fi

    # Cleanup
    rm -rf "$deb_dir"
}

# Package Windows MSI
package_msi() {
    log_info "Creating Windows MSI installer..."

    local msi_dir="${PACKAGES_DIR}/msi"
    local package_name="AcademicWorkflowSuite"
    local package_version="$VERSION"

    # Create directory structure
    mkdir -p "${msi_dir}/bin"
    mkdir -p "${msi_dir}/lib"

    # Copy binaries (would need Windows builds)
    log_warning "MSI packaging requires Windows binaries"
    log_info "Expected locations:"
    log_info "  - components/core/target/x86_64-pc-windows-msvc/release/academic-workflow-core.exe"
    log_info "  - components/ai-jail/target/x86_64-pc-windows-msvc/release/ai-jail.exe"

    # Create WiX source file
    cat > "${msi_dir}/product.wxs" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="*" Name="Academic Workflow Suite" Language="1033" Version="${package_version}"
           Manufacturer="Academic Workflow Suite Team" UpgradeCode="YOUR-GUID-HERE">
    <Package InstallerVersion="200" Compressed="yes" InstallScope="perMachine" />

    <MajorUpgrade DowngradeErrorMessage="A newer version is already installed." />
    <MediaTemplate EmbedCab="yes" />

    <Feature Id="ProductFeature" Title="Academic Workflow Suite" Level="1">
      <ComponentGroupRef Id="ProductComponents" />
    </Feature>

    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFilesFolder">
        <Directory Id="INSTALLFOLDER" Name="AcademicWorkflowSuite" />
      </Directory>
    </Directory>

    <ComponentGroup Id="ProductComponents" Directory="INSTALLFOLDER">
      <!-- Add components here -->
    </ComponentGroup>
  </Product>
</Wix>
EOF

    local msi_file="${PACKAGES_DIR}/${package_name}-${package_version}.msi"

    if command -v wixl &> /dev/null; then
        # wixl "${msi_dir}/product.wxs" -o "$msi_file"
        log_warning "WiX Light/wixl would be run here with actual binaries"

        # Create placeholder
        touch "$msi_file"
        sha256sum "$msi_file" > "${msi_file}.sha256"

        log_success "MSI package created (placeholder): $msi_file"
    else
        log_warning "wixl not found. MSI packaging skipped."
        log_info "Install msitools or WiX Toolset to build MSI packages."
    fi

    # Cleanup
    # rm -rf "$msi_dir"
}

# Package macOS DMG
package_dmg() {
    log_info "Creating macOS DMG..."

    local dmg_dir="${PACKAGES_DIR}/dmg"
    local package_name="AcademicWorkflowSuite"
    local package_version="$VERSION"

    mkdir -p "$dmg_dir"

    log_warning "DMG packaging requires macOS binaries"
    log_info "Expected locations:"
    log_info "  - components/core/target/x86_64-apple-darwin/release/academic-workflow-core"
    log_info "  - components/ai-jail/target/x86_64-apple-darwin/release/ai-jail"

    local dmg_file="${PACKAGES_DIR}/${package_name}-${package_version}.dmg"

    # On macOS, you would use hdiutil
    # hdiutil create -volname "Academic Workflow Suite" -srcfolder "$dmg_dir" -ov -format UDZO "$dmg_file"

    log_warning "DMG creation requires macOS and hdiutil"

    # Create placeholder
    touch "$dmg_file"
    sha256sum "$dmg_file" > "${dmg_file}.sha256" 2>/dev/null || true

    log_success "DMG package created (placeholder): $dmg_file"
}

# Package Office Add-in
package_office_addin() {
    log_info "Packaging Office add-in..."

    if [ -d "$OFFICE_ADDIN_DIR" ]; then
        cd "${ROOT_DIR}/components/office-addin"

        if [ -f "package.json" ]; then
            npm pack
            mv ./*.tgz "$PACKAGES_DIR/" || true
            log_success "Office add-in packaged"
        else
            log_warning "No package.json found for Office add-in"
        fi
    else
        log_warning "Office add-in dist directory not found: $OFFICE_ADDIN_DIR"
    fi
}

# Generate checksums for all packages
generate_checksums() {
    log_info "Generating checksums..."

    cd "$PACKAGES_DIR"

    if command -v sha256sum &> /dev/null; then
        find . -maxdepth 1 -type f \( -name "*.deb" -o -name "*.msi" -o -name "*.dmg" -o -name "*.tgz" \) \
            -exec sha256sum {} \; > SHA256SUMS

        log_success "Checksums generated: ${PACKAGES_DIR}/SHA256SUMS"
        cat SHA256SUMS
    else
        log_warning "sha256sum not available, skipping checksums"
    fi
}

# Main packaging function
main() {
    log_info "Academic Workflow Suite Packager"
    log_info "Version: $VERSION"
    log_info "Package type: $PACKAGE_TYPE"
    log_info "Packages directory: $PACKAGES_DIR"
    echo ""

    case "$PACKAGE_TYPE" in
        deb)
            package_deb
            ;;
        msi)
            package_msi
            ;;
        dmg)
            package_dmg
            ;;
        office-addin)
            package_office_addin
            ;;
        all)
            package_deb
            package_msi
            package_dmg
            package_office_addin
            generate_checksums
            ;;
        *)
            log_error "Unknown package type: $PACKAGE_TYPE"
            echo "Usage: $0 [deb|msi|dmg|office-addin|all]"
            exit 1
            ;;
    esac

    echo ""
    log_success "Packaging complete!"
    log_info "Packages created in: $PACKAGES_DIR"
    ls -lh "$PACKAGES_DIR"
}

# Run main
main
exit $?
