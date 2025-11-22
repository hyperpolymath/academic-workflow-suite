#!/usr/bin/env bash
#
# Academic Workflow Suite - Linux-Specific Installation Script
# =============================================================
#
# This script handles Linux-specific installation tasks including:
# - Distribution detection (Ubuntu, Fedora, Arch, Debian, etc.)
# - Package manager selection and dependency installation
# - Container runtime setup (Podman preferred)
# - systemd service configuration
# - Desktop integration
#
# Usage: ./install-linux.sh [OPTIONS]
#
# Options:
#   --distro DISTRO    Force specific distribution detection
#   --no-systemd       Skip systemd service setup
#   --no-desktop       Skip desktop integration
#   --help             Show this help message
#

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common functions if available
if [[ -f "$SCRIPT_DIR/common.sh" ]]; then
    source "$SCRIPT_DIR/common.sh"
fi

# Default options
FORCE_DISTRO=""
SETUP_SYSTEMD=true
SETUP_DESKTOP=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --distro)
                FORCE_DISTRO="$2"
                shift 2
                ;;
            --no-systemd)
                SETUP_SYSTEMD=false
                shift
                ;;
            --no-desktop)
                SETUP_DESKTOP=false
                shift
                ;;
            --help)
                grep "^#" "$0" | grep -v "#!/" | sed 's/^# //' | sed 's/^#//'
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# Detect Linux distribution
detect_distro() {
    if [[ -n "$FORCE_DISTRO" ]]; then
        echo "$FORCE_DISTRO"
        return
    fi

    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "${ID:-unknown}"
    elif [[ -f /etc/lsb-release ]]; then
        source /etc/lsb-release
        echo "${DISTRIB_ID:-unknown}" | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

# Detect distribution version
detect_version() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "${VERSION_ID:-unknown}"
    else
        echo "unknown"
    fi
}

# Check if running with sufficient privileges
check_privileges() {
    if [[ $EUID -eq 0 ]]; then
        log_warn "Running as root. This is not recommended for user installations."
        SUDO=""
    else
        if command -v sudo &> /dev/null; then
            SUDO="sudo"
            log_info "Will use sudo for privileged operations"
        else
            log_error "sudo not found. Please run as root or install sudo."
            exit 1
        fi
    fi
}

# Install packages using apt (Debian/Ubuntu)
install_apt_packages() {
    local packages=("$@")

    log_info "Updating apt package lists..."
    $SUDO apt-get update -qq

    log_info "Installing packages: ${packages[*]}"
    $SUDO apt-get install -y -qq "${packages[@]}"
}

# Install packages using dnf (Fedora)
install_dnf_packages() {
    local packages=("$@")

    log_info "Installing packages: ${packages[*]}"
    $SUDO dnf install -y -q "${packages[@]}"
}

# Install packages using pacman (Arch)
install_pacman_packages() {
    local packages=("$@")

    log_info "Updating pacman database..."
    $SUDO pacman -Sy --noconfirm

    log_info "Installing packages: ${packages[*]}"
    $SUDO pacman -S --noconfirm --needed "${packages[@]}"
}

# Install packages using zypper (openSUSE)
install_zypper_packages() {
    local packages=("$@")

    log_info "Refreshing zypper repositories..."
    $SUDO zypper refresh

    log_info "Installing packages: ${packages[*]}"
    $SUDO zypper install -y "${packages[@]}"
}

# Install base dependencies based on distribution
install_base_dependencies() {
    local distro="$1"

    log_info "Installing base dependencies for $distro..."

    case "$distro" in
        ubuntu|debian)
            install_apt_packages \
                build-essential \
                pkg-config \
                libssl-dev \
                libsqlite3-dev \
                liblmdb-dev \
                curl \
                wget \
                git \
                cmake \
                unzip
            ;;
        fedora|rhel|centos|rocky|alma)
            install_dnf_packages \
                gcc \
                gcc-c++ \
                make \
                pkgconfig \
                openssl-devel \
                sqlite-devel \
                lmdb-devel \
                curl \
                wget \
                git \
                cmake \
                unzip
            ;;
        arch|manjaro)
            install_pacman_packages \
                base-devel \
                pkg-config \
                openssl \
                sqlite \
                lmdb \
                curl \
                wget \
                git \
                cmake \
                unzip
            ;;
        opensuse*|sles)
            install_zypper_packages \
                gcc \
                gcc-c++ \
                make \
                pkg-config \
                libopenssl-devel \
                sqlite3-devel \
                lmdb-devel \
                curl \
                wget \
                git \
                cmake \
                unzip
            ;;
        *)
            log_error "Unsupported distribution: $distro"
            return 1
            ;;
    esac

    log_success "Base dependencies installed"
}

# Install Rust toolchain
install_rust() {
    if command -v rustc &> /dev/null; then
        local rust_version
        rust_version=$(rustc --version | awk '{print $2}')
        log_info "Rust already installed: $rust_version"
        return 0
    fi

    log_info "Installing Rust toolchain..."

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

    # Source cargo environment
    source "$HOME/.cargo/env"

    log_success "Rust installed: $(rustc --version)"
}

# Install Elixir and Erlang
install_elixir() {
    local distro="$1"

    if command -v elixir &> /dev/null; then
        local elixir_version
        elixir_version=$(elixir --version | grep "Elixir" | awk '{print $2}')
        log_info "Elixir already installed: $elixir_version"
        return 0
    fi

    log_info "Installing Erlang and Elixir..."

    case "$distro" in
        ubuntu|debian)
            # Add Erlang Solutions repository
            wget -q https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
            $SUDO dpkg -i erlang-solutions_2.0_all.deb
            rm erlang-solutions_2.0_all.deb
            $SUDO apt-get update -qq
            install_apt_packages erlang elixir
            ;;
        fedora)
            install_dnf_packages erlang elixir
            ;;
        arch|manjaro)
            install_pacman_packages erlang elixir
            ;;
        opensuse*)
            install_zypper_packages erlang elixir
            ;;
        *)
            log_error "Elixir installation not supported for: $distro"
            return 1
            ;;
    esac

    log_success "Elixir installed: $(elixir --version | grep Elixir)"
}

# Install Node.js and npm
install_nodejs() {
    local distro="$1"

    if command -v node &> /dev/null; then
        local node_version
        node_version=$(node --version)
        log_info "Node.js already installed: $node_version"
        return 0
    fi

    log_info "Installing Node.js..."

    # Use NodeSource repository for latest LTS
    curl -fsSL https://deb.nodesource.com/setup_lts.x | $SUDO -E bash -

    case "$distro" in
        ubuntu|debian)
            install_apt_packages nodejs
            ;;
        fedora|rhel|centos|rocky|alma)
            install_dnf_packages nodejs
            ;;
        arch|manjaro)
            install_pacman_packages nodejs npm
            ;;
        opensuse*)
            install_zypper_packages nodejs npm
            ;;
        *)
            log_error "Node.js installation not supported for: $distro"
            return 1
            ;;
    esac

    log_success "Node.js installed: $(node --version)"
}

# Install Podman (preferred) or Docker
install_container_runtime() {
    local distro="$1"

    # Check if Podman is already installed
    if command -v podman &> /dev/null; then
        log_info "Podman already installed: $(podman --version)"
        return 0
    fi

    # Check if Docker is already installed
    if command -v docker &> /dev/null; then
        log_info "Docker already installed: $(docker --version)"
        log_warn "Podman is recommended for better security. Consider switching."
        return 0
    fi

    log_info "Installing Podman..."

    case "$distro" in
        ubuntu|debian)
            # Ubuntu 20.10+ has podman in main repo
            local version
            version=$(detect_version)
            if [[ "$distro" == "ubuntu" ]] && [[ "${version%%.*}" -lt 21 ]]; then
                # Add Kubic repository for older Ubuntu
                echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libpod:/stable/xUbuntu_${version}/ /" | \
                    $SUDO tee /etc/apt/sources.list.d/devel:kubic:libpod:stable.list
                curl -fsSL "https://download.opensuse.org/repositories/devel:kubic:libpod:stable/xUbuntu_${version}/Release.key" | \
                    $SUDO apt-key add -
                $SUDO apt-get update -qq
            fi
            install_apt_packages podman
            ;;
        fedora|rhel|centos|rocky|alma)
            install_dnf_packages podman
            ;;
        arch|manjaro)
            install_pacman_packages podman
            ;;
        opensuse*)
            install_zypper_packages podman
            ;;
        *)
            log_error "Podman installation not supported for: $distro"
            log_info "Please install Podman or Docker manually"
            return 1
            ;;
    esac

    # Enable podman socket for rootless operation
    if command -v podman &> /dev/null && [[ $EUID -ne 0 ]]; then
        log_info "Enabling Podman socket for rootless operation..."
        systemctl --user enable --now podman.socket || true
    fi

    log_success "Podman installed: $(podman --version)"
}

# Install Python and AI dependencies (optional)
install_ai_dependencies() {
    local distro="$1"

    log_info "Installing Python and AI dependencies..."

    case "$distro" in
        ubuntu|debian)
            install_apt_packages \
                python3 \
                python3-pip \
                python3-venv \
                python3-dev
            ;;
        fedora|rhel|centos|rocky|alma)
            install_dnf_packages \
                python3 \
                python3-pip \
                python3-devel
            ;;
        arch|manjaro)
            install_pacman_packages \
                python \
                python-pip
            ;;
        opensuse*)
            install_zypper_packages \
                python3 \
                python3-pip \
                python3-devel
            ;;
    esac

    # Upgrade pip
    python3 -m pip install --user --upgrade pip

    # Install PyTorch and Transformers (for AI models)
    log_info "Installing PyTorch and Transformers (this may take a while)..."
    python3 -m pip install --user torch transformers accelerate

    log_success "AI dependencies installed"
}

# Setup systemd services
setup_systemd_services() {
    if [[ "$SETUP_SYSTEMD" != "true" ]]; then
        log_info "Skipping systemd setup (--no-systemd)"
        return 0
    fi

    if ! command -v systemctl &> /dev/null; then
        log_warn "systemd not found. Skipping service setup."
        return 0
    fi

    log_info "Setting up systemd services..."

    local service_dir="$HOME/.config/systemd/user"
    mkdir -p "$service_dir"

    # Create AWS Core service
    cat > "$service_dir/aws-core.service" << EOF
[Unit]
Description=Academic Workflow Suite - Core Engine
After=network.target

[Service]
Type=simple
ExecStart=/opt/academic-workflow-suite/bin/aws-core
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF

    # Create AWS Backend service
    cat > "$service_dir/aws-backend.service" << EOF
[Unit]
Description=Academic Workflow Suite - Backend API
After=network.target aws-core.service
Requires=aws-core.service

[Service]
Type=simple
ExecStart=/opt/academic-workflow-suite/bin/aws-backend
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
Environment="PORT=8080"

[Install]
WantedBy=default.target
EOF

    # Reload systemd daemon
    systemctl --user daemon-reload

    log_success "systemd services created"
    log_info "Enable services with: systemctl --user enable aws-core aws-backend"
    log_info "Start services with: systemctl --user start aws-core aws-backend"
}

# Setup desktop integration
setup_desktop_integration() {
    if [[ "$SETUP_DESKTOP" != "true" ]]; then
        log_info "Skipping desktop integration (--no-desktop)"
        return 0
    fi

    log_info "Setting up desktop integration..."

    local desktop_dir="$HOME/.local/share/applications"
    mkdir -p "$desktop_dir"

    # Create desktop entry
    cat > "$desktop_dir/academic-workflow-suite.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Academic Workflow Suite
Comment=Streamline and automate academic workflows
Exec=/opt/academic-workflow-suite/bin/aws-gui
Icon=/opt/academic-workflow-suite/share/icons/aws.png
Terminal=false
Categories=Education;Office;Science;
Keywords=academic;research;citation;bibliography;
EOF

    # Update desktop database
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$desktop_dir"
    fi

    log_success "Desktop integration setup complete"
}

# Configure environment variables
configure_environment() {
    log_info "Configuring environment variables..."

    local bashrc="$HOME/.bashrc"
    local profile="$HOME/.profile"

    # Add AWS to PATH
    local env_config="
# Academic Workflow Suite
export AWS_HOME=\"/opt/academic-workflow-suite\"
export PATH=\"\$AWS_HOME/bin:\$PATH\"
export AWS_CONFIG_DIR=\"\$HOME/.config/aws\"
export AWS_DATA_DIR=\"\$HOME/.local/share/aws\"
"

    # Check if already configured
    if grep -q "Academic Workflow Suite" "$bashrc" 2>/dev/null; then
        log_info "Environment already configured in $bashrc"
    else
        echo "$env_config" >> "$bashrc"
        log_success "Added AWS environment to $bashrc"
    fi

    # Also add to .profile for non-bash shells
    if [[ -f "$profile" ]]; then
        if ! grep -q "Academic Workflow Suite" "$profile" 2>/dev/null; then
            echo "$env_config" >> "$profile"
            log_success "Added AWS environment to $profile"
        fi
    fi
}

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."

    local dirs=(
        "$HOME/.config/aws"
        "$HOME/.local/share/aws"
        "$HOME/.local/share/aws/data"
        "$HOME/.local/share/aws/logs"
        "$HOME/.local/share/aws/models"
        "$HOME/.local/share/aws/backups"
        "$HOME/.cache/aws"
    )

    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done

    log_success "Directories created"
}

# Optimize system settings for AWS
optimize_system() {
    log_info "Optimizing system settings..."

    # Increase file descriptor limits
    local limits_file="/etc/security/limits.conf"
    if [[ -w "$limits_file" ]] || [[ -n "$SUDO" ]]; then
        if ! grep -q "aws file descriptors" "$limits_file" 2>/dev/null; then
            echo "# aws file descriptors" | $SUDO tee -a "$limits_file" > /dev/null
            echo "* soft nofile 65536" | $SUDO tee -a "$limits_file" > /dev/null
            echo "* hard nofile 65536" | $SUDO tee -a "$limits_file" > /dev/null
            log_success "File descriptor limits increased"
        fi
    fi

    # Set swappiness for better performance
    if [[ -w /proc/sys/vm/swappiness ]] || [[ -n "$SUDO" ]]; then
        echo 10 | $SUDO tee /proc/sys/vm/swappiness > /dev/null || true
    fi
}

# Main installation flow
main() {
    log_info "Academic Workflow Suite - Linux Installation"
    log_info "=============================================="
    echo

    parse_args "$@"

    # Detect system
    local distro
    distro=$(detect_distro)
    local version
    version=$(detect_version)

    log_info "Detected distribution: $distro $version"

    # Check privileges
    check_privileges

    # Install dependencies
    install_base_dependencies "$distro"
    install_rust
    install_elixir "$distro"
    install_nodejs "$distro"
    install_container_runtime "$distro"

    # Create directories
    create_directories

    # Configure environment
    configure_environment

    # Setup services
    setup_systemd_services

    # Desktop integration
    setup_desktop_integration

    # Optimize system
    optimize_system

    echo
    log_success "Linux-specific installation complete!"
    log_info "Please restart your shell or run: source ~/.bashrc"
}

# Run main function
main "$@"
