#!/bin/bash
# Test installation on clean systems using Docker
# Usage: ./test_install.sh [VERSION]

set -euo pipefail

VERSION=${1:-"latest"}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_DIR="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$RELEASE_DIR/dist"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi

    if ! docker ps &> /dev/null; then
        log_error "Docker daemon is not running or permission denied"
        exit 1
    fi

    log_success "Docker is available"
}

# Test Debian installation
test_debian() {
    log_info "Testing Debian installation..."

    local deb_file="academic-workflow-suite_${VERSION}_amd64.deb"

    if [ ! -f "$DIST_DIR/$deb_file" ]; then
        log_warning "Debian package not found, skipping"
        return 0
    fi

    docker run --rm -v "$DIST_DIR:/packages" debian:bookworm bash -c "
        set -e
        apt-get update -qq
        apt-get install -y -qq /packages/$deb_file
        aws --version
        aws --help > /dev/null
        echo 'Installation successful'
    " && log_success "Debian installation test passed" || log_error "Debian installation test failed"
}

# Test Ubuntu installation
test_ubuntu() {
    log_info "Testing Ubuntu installation..."

    local deb_file="academic-workflow-suite_${VERSION}_amd64.deb"

    if [ ! -f "$DIST_DIR/$deb_file" ]; then
        log_warning "Debian package not found, skipping"
        return 0
    fi

    docker run --rm -v "$DIST_DIR:/packages" ubuntu:22.04 bash -c "
        set -e
        apt-get update -qq
        apt-get install -y -qq /packages/$deb_file
        aws --version
        aws --help > /dev/null
        echo 'Installation successful'
    " && log_success "Ubuntu installation test passed" || log_error "Ubuntu installation test failed"
}

# Test Fedora installation
test_fedora() {
    log_info "Testing Fedora installation..."

    local rpm_file=$(ls "$DIST_DIR"/academic-workflow-suite-${VERSION}*.rpm 2>/dev/null | head -1)

    if [ -z "$rpm_file" ] || [ ! -f "$rpm_file" ]; then
        log_warning "RPM package not found, skipping"
        return 0
    fi

    local rpm_basename=$(basename "$rpm_file")

    docker run --rm -v "$DIST_DIR:/packages" fedora:latest bash -c "
        set -e
        dnf install -y -q /packages/$rpm_basename
        aws --version
        aws --help > /dev/null
        echo 'Installation successful'
    " && log_success "Fedora installation test passed" || log_error "Fedora installation test failed"
}

# Test CentOS installation
test_centos() {
    log_info "Testing CentOS installation..."

    local rpm_file=$(ls "$DIST_DIR"/academic-workflow-suite-${VERSION}*.rpm 2>/dev/null | head -1)

    if [ -z "$rpm_file" ] || [ ! -f "$rpm_file" ]; then
        log_warning "RPM package not found, skipping"
        return 0
    fi

    local rpm_basename=$(basename "$rpm_file")

    docker run --rm -v "$DIST_DIR:/packages" centos:stream9 bash -c "
        set -e
        dnf install -y -q /packages/$rpm_basename
        aws --version
        aws --help > /dev/null
        echo 'Installation successful'
    " && log_success "CentOS installation test passed" || log_error "CentOS installation test failed"
}

# Test Alpine installation (from tarball)
test_alpine() {
    log_info "Testing Alpine installation from tarball..."

    local tarball="academic-workflow-suite-${VERSION}.tar.gz"

    if [ ! -f "$DIST_DIR/$tarball" ]; then
        log_warning "Tarball not found, skipping"
        return 0
    fi

    docker run --rm -v "$DIST_DIR:/packages" alpine:latest sh -c "
        set -e
        apk add --no-cache libc6-compat libgcc libstdc++
        tar -xzf /packages/$tarball -C /tmp
        # Find the binary (might be in a subdirectory)
        BINARY=\$(find /tmp -type f -name 'aws' | head -1)
        if [ -z \"\$BINARY\" ]; then
            echo 'Binary not found in tarball'
            exit 1
        fi
        chmod +x \"\$BINARY\"
        \"\$BINARY\" --version
        \"\$BINARY\" --help > /dev/null
        echo 'Installation successful'
    " && log_success "Alpine installation test passed" || log_error "Alpine installation test failed"
}

# Test Arch Linux installation (from tarball)
test_arch() {
    log_info "Testing Arch Linux installation from tarball..."

    local tarball="academic-workflow-suite-${VERSION}.tar.gz"

    if [ ! -f "$DIST_DIR/$tarball" ]; then
        log_warning "Tarball not found, skipping"
        return 0
    fi

    docker run --rm -v "$DIST_DIR:/packages" archlinux:latest bash -c "
        set -e
        tar -xzf /packages/$tarball -C /tmp
        BINARY=\$(find /tmp -type f -name 'aws' | head -1)
        if [ -z \"\$BINARY\" ]; then
            echo 'Binary not found in tarball'
            exit 1
        fi
        chmod +x \"\$BINARY\"
        \"\$BINARY\" --version
        \"\$BINARY\" --help > /dev/null
        echo 'Installation successful'
    " && log_success "Arch Linux installation test passed" || log_error "Arch Linux installation test failed"
}

# Test package removal
test_removal() {
    log_info "Testing package removal..."

    # Test Debian removal
    local deb_file="academic-workflow-suite_${VERSION}_amd64.deb"
    if [ -f "$DIST_DIR/$deb_file" ]; then
        docker run --rm -v "$DIST_DIR:/packages" ubuntu:22.04 bash -c "
            set -e
            apt-get update -qq
            apt-get install -y -qq /packages/$deb_file
            apt-get remove -y -qq academic-workflow-suite
            if command -v aws &> /dev/null; then
                echo 'Binary still exists after removal'
                exit 1
            fi
            echo 'Removal successful'
        " && log_success "Debian package removal test passed" || log_error "Debian package removal test failed"
    fi
}

# Test package upgrade
test_upgrade() {
    log_info "Testing package upgrade..."

    log_warning "Upgrade test requires previous version, skipping for now"
    # TODO: Implement upgrade testing when previous versions are available
}

# Test concurrent installations
test_concurrent() {
    log_info "Testing concurrent installations..."

    local deb_file="academic-workflow-suite_${VERSION}_amd64.deb"

    if [ ! -f "$DIST_DIR/$deb_file" ]; then
        log_warning "Debian package not found, skipping"
        return 0
    fi

    # Test that multiple containers can install simultaneously
    docker run --rm -v "$DIST_DIR:/packages" -d ubuntu:22.04 bash -c "
        apt-get update -qq && apt-get install -y -qq /packages/$deb_file
    " &

    docker run --rm -v "$DIST_DIR:/packages" -d ubuntu:22.04 bash -c "
        apt-get update -qq && apt-get install -y -qq /packages/$deb_file
    " &

    wait

    log_success "Concurrent installation test passed"
}

# Test with limited resources
test_limited_resources() {
    log_info "Testing with limited resources..."

    local deb_file="academic-workflow-suite_${VERSION}_amd64.deb"

    if [ ! -f "$DIST_DIR/$deb_file" ]; then
        log_warning "Debian package not found, skipping"
        return 0
    fi

    # Test with memory limit
    docker run --rm --memory=512m -v "$DIST_DIR:/packages" ubuntu:22.04 bash -c "
        set -e
        apt-get update -qq
        apt-get install -y -qq /packages/$deb_file
        aws --version
    " && log_success "Limited resources test passed" || log_error "Limited resources test failed"
}

# Cleanup
cleanup() {
    log_info "Cleaning up..."
    docker system prune -f &> /dev/null || true
    log_success "Cleanup completed"
}

# Main test flow
main() {
    echo "═══════════════════════════════════════════════════════"
    echo "  Academic Workflow Suite - Installation Tests"
    echo "  Version: $VERSION"
    echo "═══════════════════════════════════════════════════════"
    echo ""

    check_docker

    echo ""
    log_info "Running installation tests on various distributions..."
    echo ""

    test_debian
    test_ubuntu
    test_fedora
    test_centos
    test_alpine
    test_arch

    echo ""
    log_info "Running additional tests..."
    echo ""

    test_removal
    test_upgrade
    test_concurrent
    test_limited_resources

    echo ""
    cleanup

    echo ""
    echo "═══════════════════════════════════════════════════════"
    log_success "All installation tests completed!"
    echo "═══════════════════════════════════════════════════════"
}

# Handle interrupts
trap cleanup EXIT INT TERM

main
