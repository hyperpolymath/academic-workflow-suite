#!/usr/bin/env bash
#
# Academic Workflow Suite - Main Installation Script
# ===================================================
#
# This is the primary installation script for the Academic Workflow Suite.
# It provides an interactive TUI for installing the complete system with
# support for multiple installation modes and comprehensive error handling.
#
# Features:
#   - Interactive TUI using whiptail/dialog
#   - Three installation modes: Quick, Custom, Full
#   - OS detection (Windows/WSL/Linux)
#   - Automatic dependency installation
#   - Component building with progress tracking
#   - AI model downloading from HuggingFace
#   - Service configuration (systemd/Windows services)
#   - Desktop integration
#   - Comprehensive validation
#   - Rollback on failure
#   - Offline mode support
#
# Usage: ./install.sh [OPTIONS]
#
# Options:
#   --mode MODE        Installation mode: quick, custom, or full
#   --no-interactive   Run in non-interactive mode
#   --offline          Use cached downloads only (no network)
#   --skip-deps        Skip dependency installation
#   --skip-build       Skip building components
#   --skip-services    Skip service configuration
#   --prefix PATH      Installation prefix (default: /opt/academic-workflow-suite)
#   --help             Show this help message
#

set -euo pipefail

# ============================================================================
# CONFIGURATION AND GLOBALS
# ============================================================================

# Script metadata
SCRIPT_VERSION="0.1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default installation paths
DEFAULT_PREFIX="/opt/academic-workflow-suite"
DEFAULT_DATA_DIR="$HOME/.local/share/aws"
DEFAULT_CONFIG_DIR="$HOME/.config/aws"
DEFAULT_CACHE_DIR="$HOME/.cache/aws"

# Installation settings
INSTALL_PREFIX="${INSTALL_PREFIX:-$DEFAULT_PREFIX}"
DATA_DIR="${DATA_DIR:-$DEFAULT_DATA_DIR}"
CONFIG_DIR="${CONFIG_DIR:-$DEFAULT_CONFIG_DIR}"
CACHE_DIR="${CACHE_DIR:-$DEFAULT_CACHE_DIR}"

# Installation mode
INSTALL_MODE=""
INTERACTIVE=true
OFFLINE_MODE=false
SKIP_DEPS=false
SKIP_BUILD=false
SKIP_SERVICES=false

# Component flags
INSTALL_CORE=false
INSTALL_BACKEND=false
INSTALL_OFFICE=false
INSTALL_AI=false
INSTALL_DEV_TOOLS=false

# AI Model selection
AI_MODEL="mistral-7b"
AI_MODELS_TO_INSTALL=()

# System information
OS_TYPE=""
OS_DISTRO=""
OS_VERSION=""
IS_WSL=false

# Logging
LOG_FILE="${LOG_FILE:-$PWD/install.log}"
INSTALL_START_TIME=""
INSTALL_SUCCESS=false

# Rollback stack
declare -a ROLLBACK_STACK

# Dependencies
REQUIRED_RUST_VERSION="1.75.0"
REQUIRED_ELIXIR_VERSION="1.15.0"
REQUIRED_NODE_VERSION="18.0.0"
REQUIRED_PODMAN_VERSION="4.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    case "$level" in
        INFO)
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        SUCCESS)
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        DEBUG)
            if [[ "${DEBUG:-false}" == "true" ]]; then
                echo -e "${MAGENTA}[DEBUG]${NC} $message"
            fi
            ;;
    esac
}

log_info() { log INFO "$@"; }
log_success() { log SUCCESS "$@"; }
log_warn() { log WARN "$@"; }
log_error() { log ERROR "$@"; }
log_debug() { log DEBUG "$@"; }

# Print section header
print_header() {
    local title="$1"
    local width=70
    local padding=$(( (width - ${#title}) / 2 ))

    echo
    echo -e "${CYAN}$(printf '=%.0s' $(seq 1 $width))${NC}"
    echo -e "${CYAN}$(printf ' %.0s' $(seq 1 $padding))${WHITE}$title${NC}"
    echo -e "${CYAN}$(printf '=%.0s' $(seq 1 $width))${NC}"
    echo
}

# Progress bar
show_progress() {
    local current=$1
    local total=$2
    local message=$3
    local width=50

    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))

    printf "\r${CYAN}[${NC}"
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "${CYAN}]${NC} %3d%% %s" "$percentage" "$message"

    if [[ $current -eq $total ]]; then
        echo
    fi
}

# Spinner for long-running tasks
spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='|/-\'

    echo -n "$message "

    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done

    wait "$pid"
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        printf "${GREEN}[✓]${NC}\n"
    else
        printf "${RED}[✗]${NC}\n"
    fi

    return $exit_code
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Version comparison
version_ge() {
    local version1="$1"
    local version2="$2"

    if [[ "$(printf '%s\n' "$version1" "$version2" | sort -V | head -n1)" == "$version2" ]]; then
        return 0
    else
        return 1
    fi
}

# Add to rollback stack
add_rollback() {
    ROLLBACK_STACK+=("$*")
    log_debug "Added rollback action: $*"
}

# Execute rollback
execute_rollback() {
    log_warn "Executing rollback..."

    local i
    for ((i=${#ROLLBACK_STACK[@]}-1; i>=0; i--)); do
        local action="${ROLLBACK_STACK[$i]}"
        log_info "Rollback: $action"
        eval "$action" || log_error "Rollback action failed: $action"
    done

    log_info "Rollback complete"
}

# Cleanup on exit
cleanup() {
    local exit_code=$?

    if [[ $exit_code -ne 0 ]] && [[ "${INSTALL_SUCCESS}" == "false" ]]; then
        log_error "Installation failed with exit code $exit_code"

        if [[ ${#ROLLBACK_STACK[@]} -gt 0 ]]; then
            read -p "Do you want to rollback changes? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                execute_rollback
            fi
        fi
    fi

    if [[ -n "${INSTALL_START_TIME:-}" ]]; then
        local duration=$(($(date +%s) - INSTALL_START_TIME))
        log_info "Installation duration: ${duration}s"
    fi
}

trap cleanup EXIT

# ============================================================================
# SYSTEM DETECTION
# ============================================================================

detect_os() {
    log_info "Detecting operating system..."

    # Check if running in WSL
    if grep -qi microsoft /proc/version 2>/dev/null; then
        IS_WSL=true
        OS_TYPE="wsl"
        log_info "Detected WSL (Windows Subsystem for Linux)"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS_TYPE="windows"
    else
        OS_TYPE="unknown"
        log_error "Unknown operating system: $OSTYPE"
        return 1
    fi

    # Detect distribution
    if [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
        if [[ -f /etc/os-release ]]; then
            source /etc/os-release
            OS_DISTRO="${ID:-unknown}"
            OS_VERSION="${VERSION_ID:-unknown}"
        else
            OS_DISTRO="unknown"
            OS_VERSION="unknown"
        fi

        log_info "Distribution: $OS_DISTRO $OS_VERSION"
    fi

    log_success "OS detection complete: $OS_TYPE"
    return 0
}

# Check system requirements
check_system_requirements() {
    log_info "Checking system requirements..."

    local errors=0

    # Check disk space
    local available_space
    available_space=$(df -BG "$HOME" | tail -1 | awk '{print $4}' | sed 's/G//')

    local required_space=5
    case "$INSTALL_MODE" in
        full)
            required_space=20
            ;;
        custom)
            required_space=10
            ;;
        quick)
            required_space=5
            ;;
    esac

    if [[ $available_space -lt $required_space ]]; then
        log_error "Insufficient disk space. Required: ${required_space}GB, Available: ${available_space}GB"
        ((errors++))
    else
        log_success "Disk space check passed: ${available_space}GB available"
    fi

    # Check memory
    local total_mem
    total_mem=$(free -g | awk '/^Mem:/ {print $2}')

    local required_mem=4
    if [[ "$INSTALL_MODE" == "full" ]]; then
        required_mem=16
    elif [[ "$INSTALL_MODE" == "custom" ]]; then
        required_mem=8
    fi

    if [[ $total_mem -lt $required_mem ]]; then
        log_warn "Low memory. Recommended: ${required_mem}GB, Available: ${total_mem}GB"
        log_warn "Installation may be slow or fail"
    else
        log_success "Memory check passed: ${total_mem}GB available"
    fi

    # Check CPU cores
    local cpu_cores
    cpu_cores=$(nproc)
    log_info "CPU cores: $cpu_cores"

    if [[ $cpu_cores -lt 2 ]]; then
        log_warn "Low CPU core count. Build process may be slow."
    fi

    return $errors
}

# ============================================================================
# DEPENDENCY MANAGEMENT
# ============================================================================

check_dependency() {
    local name="$1"
    local command="$2"
    local required_version="${3:-}"

    if ! command_exists "$command"; then
        log_warn "$name not found"
        return 1
    fi

    local installed_version=""
    case "$name" in
        Rust)
            installed_version=$(rustc --version | awk '{print $2}')
            ;;
        Elixir)
            installed_version=$(elixir --version | grep "Elixir" | awk '{print $2}')
            ;;
        Node.js)
            installed_version=$(node --version | sed 's/v//')
            ;;
        Podman)
            installed_version=$(podman --version | awk '{print $3}')
            ;;
        Docker)
            installed_version=$(docker --version | awk '{print $3}' | sed 's/,//')
            ;;
    esac

    if [[ -n "$required_version" ]] && [[ -n "$installed_version" ]]; then
        if version_ge "$installed_version" "$required_version"; then
            log_success "$name $installed_version (>= $required_version required)"
            return 0
        else
            log_warn "$name $installed_version (< $required_version required)"
            return 1
        fi
    else
        log_success "$name found: $installed_version"
        return 0
    fi
}

check_all_dependencies() {
    log_info "Checking dependencies..."

    local missing_deps=()

    check_dependency "Rust" "rustc" "$REQUIRED_RUST_VERSION" || missing_deps+=("rust")
    check_dependency "Cargo" "cargo" "" || missing_deps+=("cargo")

    if [[ "$INSTALL_BACKEND" == "true" ]]; then
        check_dependency "Elixir" "elixir" "$REQUIRED_ELIXIR_VERSION" || missing_deps+=("elixir")
        check_dependency "Mix" "mix" "" || missing_deps+=("mix")
    fi

    if [[ "$INSTALL_OFFICE" == "true" ]]; then
        check_dependency "Node.js" "node" "$REQUIRED_NODE_VERSION" || missing_deps+=("nodejs")
        check_dependency "npm" "npm" "" || missing_deps+=("npm")
    fi

    if [[ "$INSTALL_AI" == "true" ]]; then
        if ! check_dependency "Podman" "podman" "$REQUIRED_PODMAN_VERSION"; then
            check_dependency "Docker" "docker" "" || missing_deps+=("container-runtime")
        fi
        check_dependency "Python" "python3" "" || missing_deps+=("python3")
    fi

    # Build essentials
    check_dependency "GCC" "gcc" "" || missing_deps+=("gcc")
    check_dependency "Make" "make" "" || missing_deps+=("make")
    check_dependency "Git" "git" "" || missing_deps+=("git")

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warn "Missing dependencies: ${missing_deps[*]}"
        return 1
    else
        log_success "All dependencies satisfied"
        return 0
    fi
}

install_dependencies() {
    if [[ "$SKIP_DEPS" == "true" ]]; then
        log_info "Skipping dependency installation (--skip-deps)"
        return 0
    fi

    print_header "Installing Dependencies"

    # Call OS-specific installation script
    if [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
        if [[ -x "$SCRIPT_DIR/install-linux.sh" ]]; then
            log_info "Running Linux dependency installer..."
            "$SCRIPT_DIR/install-linux.sh" || return 1
        else
            log_error "Linux installer not found: $SCRIPT_DIR/install-linux.sh"
            return 1
        fi
    elif [[ "$OS_TYPE" == "windows" ]]; then
        log_info "Please run install-windows.ps1 first to install Windows dependencies"
        return 1
    elif [[ "$OS_TYPE" == "macos" ]]; then
        log_error "macOS installation not yet supported"
        return 1
    fi

    log_success "Dependencies installed"
    return 0
}

# ============================================================================
# INTERACTIVE TUI
# ============================================================================

# Check for dialog tools
get_dialog_tool() {
    if command_exists whiptail; then
        echo "whiptail"
    elif command_exists dialog; then
        echo "dialog"
    else
        echo "none"
    fi
}

# Show main menu
show_main_menu() {
    local dialog_tool
    dialog_tool=$(get_dialog_tool)

    if [[ "$dialog_tool" == "none" ]]; then
        log_error "Neither whiptail nor dialog found. Please install one of them."
        return 1
    fi

    local choice
    if [[ "$dialog_tool" == "whiptail" ]]; then
        choice=$(whiptail --title "Academic Workflow Suite Installer" \
            --menu "Choose installation mode:" 20 78 3 \
            "1" "Quick Install (5 min) - Core + Office + AI (Mistral 7B)" \
            "2" "Custom Install - Select components to install" \
            "3" "Full Install - Everything including dev tools" \
            3>&1 1>&2 2>&3)
    else
        choice=$(dialog --title "Academic Workflow Suite Installer" \
            --menu "Choose installation mode:" 20 78 3 \
            "1" "Quick Install (5 min) - Core + Office + AI (Mistral 7B)" \
            "2" "Custom Install - Select components to install" \
            "3" "Full Install - Everything including dev tools" \
            3>&1 1>&2 2>&3)
    fi

    case "$choice" in
        1)
            INSTALL_MODE="quick"
            INSTALL_CORE=true
            INSTALL_BACKEND=true
            INSTALL_OFFICE=true
            INSTALL_AI=true
            AI_MODELS_TO_INSTALL=("mistral-7b")
            ;;
        2)
            INSTALL_MODE="custom"
            show_component_selection
            ;;
        3)
            INSTALL_MODE="full"
            INSTALL_CORE=true
            INSTALL_BACKEND=true
            INSTALL_OFFICE=true
            INSTALL_AI=true
            INSTALL_DEV_TOOLS=true
            AI_MODELS_TO_INSTALL=("mistral-7b" "llama2-13b")
            ;;
        *)
            return 1
            ;;
    esac

    return 0
}

# Show component selection
show_component_selection() {
    local dialog_tool
    dialog_tool=$(get_dialog_tool)

    local components
    if [[ "$dialog_tool" == "whiptail" ]]; then
        components=$(whiptail --title "Component Selection" \
            --checklist "Select components to install:" 20 78 6 \
            "core" "Core Engine (Required)" ON \
            "backend" "Backend API Server" ON \
            "office" "Office Add-in (Word/Excel)" ON \
            "ai" "AI Jail (Sandboxed AI)" OFF \
            "dev" "Development Tools" OFF \
            3>&1 1>&2 2>&3)
    else
        components=$(dialog --title "Component Selection" \
            --checklist "Select components to install:" 20 78 6 \
            "core" "Core Engine (Required)" ON \
            "backend" "Backend API Server" ON \
            "office" "Office Add-in (Word/Excel)" ON \
            "ai" "AI Jail (Sandboxed AI)" OFF \
            "dev" "Development Tools" OFF \
            3>&1 1>&2 2>&3)
    fi

    # Parse selection
    for component in $components; do
        component=$(echo "$component" | tr -d '"')
        case "$component" in
            core) INSTALL_CORE=true ;;
            backend) INSTALL_BACKEND=true ;;
            office) INSTALL_OFFICE=true ;;
            ai)
                INSTALL_AI=true
                show_ai_model_selection
                ;;
            dev) INSTALL_DEV_TOOLS=true ;;
        esac
    done

    # Core is always required
    INSTALL_CORE=true
}

# Show AI model selection
show_ai_model_selection() {
    local dialog_tool
    dialog_tool=$(get_dialog_tool)

    local models
    if [[ "$dialog_tool" == "whiptail" ]]; then
        models=$(whiptail --title "AI Model Selection" \
            --checklist "Select AI models to install:" 15 78 3 \
            "mistral-7b" "Mistral 7B (15 GB) - Recommended" ON \
            "llama2-13b" "Llama2 13B (30 GB) - More powerful" OFF \
            3>&1 1>&2 2>&3)
    else
        models=$(dialog --title "AI Model Selection" \
            --checklist "Select AI models to install:" 15 78 3 \
            "mistral-7b" "Mistral 7B (15 GB) - Recommended" ON \
            "llama2-13b" "Llama2 13B (30 GB) - More powerful" OFF \
            3>&1 1>&2 2>&3)
    fi

    # Parse selection
    AI_MODELS_TO_INSTALL=()
    for model in $models; do
        model=$(echo "$model" | tr -d '"')
        AI_MODELS_TO_INSTALL+=("$model")
    done
}

# Show installation summary
show_installation_summary() {
    local dialog_tool
    dialog_tool=$(get_dialog_tool)

    local summary="Installation Mode: $INSTALL_MODE\n\n"
    summary+="Components to install:\n"

    [[ "$INSTALL_CORE" == "true" ]] && summary+="  ✓ Core Engine\n"
    [[ "$INSTALL_BACKEND" == "true" ]] && summary+="  ✓ Backend API\n"
    [[ "$INSTALL_OFFICE" == "true" ]] && summary+="  ✓ Office Add-in\n"
    [[ "$INSTALL_AI" == "true" ]] && summary+="  ✓ AI Jail\n"
    [[ "$INSTALL_DEV_TOOLS" == "true" ]] && summary+="  ✓ Development Tools\n"

    if [[ "$INSTALL_AI" == "true" ]] && [[ ${#AI_MODELS_TO_INSTALL[@]} -gt 0 ]]; then
        summary+="\nAI Models:\n"
        for model in "${AI_MODELS_TO_INSTALL[@]}"; do
            summary+="  ✓ $model\n"
        done
    fi

    summary+="\nInstallation Path: $INSTALL_PREFIX\n"
    summary+="\nProceed with installation?"

    if [[ "$dialog_tool" == "whiptail" ]]; then
        whiptail --title "Installation Summary" --yesno "$summary" 20 78
    else
        dialog --title "Installation Summary" --yesno "$summary" 20 78
    fi

    return $?
}

# ============================================================================
# COMPONENT BUILDING
# ============================================================================

build_core() {
    if [[ "$INSTALL_CORE" != "true" ]]; then
        return 0
    fi

    print_header "Building Core Engine"

    local core_dir="$PROJECT_ROOT/components/core"

    if [[ ! -f "$core_dir/Cargo.toml" ]]; then
        log_error "Core component not found: $core_dir"
        return 1
    fi

    log_info "Building Rust core..."

    (
        cd "$core_dir"
        cargo build --release 2>&1 | tee -a "$LOG_FILE" || exit 1
    ) &

    spinner $! "Building core component..."

    if [[ $? -eq 0 ]]; then
        log_success "Core engine built successfully"
        add_rollback "rm -f '$core_dir/target/release/aws-core'"
        return 0
    else
        log_error "Core build failed"
        return 1
    fi
}

build_backend() {
    if [[ "$INSTALL_BACKEND" != "true" ]]; then
        return 0
    fi

    print_header "Building Backend API"

    local backend_dir="$PROJECT_ROOT/components/backend"

    if [[ ! -d "$backend_dir" ]]; then
        log_error "Backend component not found: $backend_dir"
        return 1
    fi

    log_info "Building Elixir backend..."

    (
        cd "$backend_dir"
        mix deps.get 2>&1 | tee -a "$LOG_FILE" || exit 1
        mix compile 2>&1 | tee -a "$LOG_FILE" || exit 1
    ) &

    spinner $! "Building backend component..."

    if [[ $? -eq 0 ]]; then
        log_success "Backend built successfully"
        return 0
    else
        log_error "Backend build failed"
        return 1
    fi
}

build_office_addin() {
    if [[ "$INSTALL_OFFICE" != "true" ]]; then
        return 0
    fi

    print_header "Building Office Add-in"

    local office_dir="$PROJECT_ROOT/components/office-addin"

    if [[ ! -d "$office_dir" ]]; then
        log_error "Office add-in component not found: $office_dir"
        return 1
    fi

    log_info "Building Office add-in..."

    (
        cd "$office_dir"
        npm install 2>&1 | tee -a "$LOG_FILE" || exit 1
        npm run build 2>&1 | tee -a "$LOG_FILE" || exit 1
    ) &

    spinner $! "Building Office add-in..."

    if [[ $? -eq 0 ]]; then
        log_success "Office add-in built successfully"
        return 0
    else
        log_error "Office add-in build failed"
        return 1
    fi
}

build_ai_jail() {
    if [[ "$INSTALL_AI" != "true" ]]; then
        return 0
    fi

    print_header "Building AI Jail Component"

    local ai_dir="$PROJECT_ROOT/components/ai-jail"

    if [[ ! -d "$ai_dir" ]]; then
        log_error "AI jail component not found: $ai_dir"
        return 1
    fi

    log_info "Building AI jail..."

    (
        cd "$ai_dir"
        cargo build --release 2>&1 | tee -a "$LOG_FILE" || exit 1
    ) &

    spinner $! "Building AI jail component..."

    if [[ $? -eq 0 ]]; then
        log_success "AI jail built successfully"
        return 0
    else
        log_error "AI jail build failed"
        return 1
    fi
}

# ============================================================================
# AI MODEL MANAGEMENT
# ============================================================================

download_ai_model() {
    local model_name="$1"

    log_info "Downloading AI model: $model_name"

    local model_dir="$DATA_DIR/models/$model_name"
    mkdir -p "$model_dir"

    case "$model_name" in
        mistral-7b)
            local model_url="https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf"
            local model_file="$model_dir/model.gguf"
            ;;
        llama2-13b)
            local model_url="https://huggingface.co/TheBloke/Llama-2-13B-chat-GGUF/resolve/main/llama-2-13b-chat.Q4_K_M.gguf"
            local model_file="$model_dir/model.gguf"
            ;;
        *)
            log_error "Unknown model: $model_name"
            return 1
            ;;
    esac

    if [[ -f "$model_file" ]]; then
        log_info "Model already downloaded: $model_file"
        return 0
    fi

    if [[ "$OFFLINE_MODE" == "true" ]]; then
        log_error "Model not found in cache and offline mode is enabled"
        return 1
    fi

    log_info "Downloading from: $model_url"
    log_info "This may take a while (several GB)..."

    if command_exists wget; then
        wget --progress=bar:force -O "$model_file" "$model_url" 2>&1 | tee -a "$LOG_FILE"
    elif command_exists curl; then
        curl -L --progress-bar -o "$model_file" "$model_url" 2>&1 | tee -a "$LOG_FILE"
    else
        log_error "Neither wget nor curl found. Cannot download models."
        return 1
    fi

    if [[ $? -eq 0 ]] && [[ -f "$model_file" ]]; then
        log_success "Model downloaded: $model_name"
        add_rollback "rm -f '$model_file'"
        return 0
    else
        log_error "Model download failed: $model_name"
        return 1
    fi
}

download_all_ai_models() {
    if [[ "$INSTALL_AI" != "true" ]] || [[ ${#AI_MODELS_TO_INSTALL[@]} -eq 0 ]]; then
        return 0
    fi

    print_header "Downloading AI Models"

    for model in "${AI_MODELS_TO_INSTALL[@]}"; do
        download_ai_model "$model" || return 1
    done

    return 0
}

# ============================================================================
# INSTALLATION
# ============================================================================

create_directories() {
    log_info "Creating installation directories..."

    local dirs=(
        "$INSTALL_PREFIX"
        "$INSTALL_PREFIX/bin"
        "$INSTALL_PREFIX/lib"
        "$INSTALL_PREFIX/share"
        "$INSTALL_PREFIX/etc"
        "$DATA_DIR"
        "$DATA_DIR/data"
        "$DATA_DIR/logs"
        "$DATA_DIR/models"
        "$DATA_DIR/backups"
        "$CONFIG_DIR"
        "$CACHE_DIR"
    )

    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir" || return 1
            log_debug "Created: $dir"
            add_rollback "rmdir '$dir' 2>/dev/null || true"
        fi
    done

    log_success "Directories created"
    return 0
}

install_binaries() {
    log_info "Installing binaries..."

    # Install core binary
    if [[ "$INSTALL_CORE" == "true" ]]; then
        local core_bin="$PROJECT_ROOT/components/core/target/release/aws-core"
        if [[ -f "$core_bin" ]]; then
            cp "$core_bin" "$INSTALL_PREFIX/bin/" || return 1
            chmod +x "$INSTALL_PREFIX/bin/aws-core"
            log_success "Installed: aws-core"
        fi
    fi

    # Install AI jail binary
    if [[ "$INSTALL_AI" == "true" ]]; then
        local ai_bin="$PROJECT_ROOT/components/ai-jail/target/release/aws-ai-jail"
        if [[ -f "$ai_bin" ]]; then
            cp "$ai_bin" "$INSTALL_PREFIX/bin/" || return 1
            chmod +x "$INSTALL_PREFIX/bin/aws-ai-jail"
            log_success "Installed: aws-ai-jail"
        fi
    fi

    log_success "Binaries installed"
    return 0
}

install_configuration() {
    log_info "Installing configuration files..."

    local config_template="$SCRIPT_DIR/config-template.yaml"
    local user_config="$CONFIG_DIR/config.yaml"

    if [[ -f "$config_template" ]]; then
        if [[ ! -f "$user_config" ]]; then
            cp "$config_template" "$user_config" || return 1
            log_success "Configuration installed: $user_config"
        else
            log_info "Configuration already exists: $user_config"
        fi
    else
        log_warn "Configuration template not found: $config_template"
    fi

    return 0
}

configure_services() {
    if [[ "$SKIP_SERVICES" == "true" ]]; then
        log_info "Skipping service configuration (--skip-services)"
        return 0
    fi

    print_header "Configuring Services"

    if command_exists systemctl; then
        log_info "Configuring systemd services..."

        local service_dir="$HOME/.config/systemd/user"
        mkdir -p "$service_dir"

        # Create AWS Core service
        cat > "$service_dir/aws-core.service" << EOF
[Unit]
Description=Academic Workflow Suite - Core Engine
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_PREFIX/bin/aws-core
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
Environment="AWS_CONFIG_DIR=$CONFIG_DIR"
Environment="AWS_DATA_DIR=$DATA_DIR"

[Install]
WantedBy=default.target
EOF

        systemctl --user daemon-reload
        log_success "systemd services configured"
    else
        log_warn "systemd not found, skipping service configuration"
    fi

    return 0
}

setup_environment() {
    log_info "Setting up environment..."

    local bashrc="$HOME/.bashrc"
    local env_marker="# Academic Workflow Suite"

    if grep -q "$env_marker" "$bashrc" 2>/dev/null; then
        log_info "Environment already configured"
        return 0
    fi

    cat >> "$bashrc" << EOF

$env_marker
export AWS_HOME="$INSTALL_PREFIX"
export PATH="\$AWS_HOME/bin:\$PATH"
export AWS_CONFIG_DIR="$CONFIG_DIR"
export AWS_DATA_DIR="$DATA_DIR"
EOF

    log_success "Environment configured"
    return 0
}

validate_installation() {
    print_header "Validating Installation"

    local errors=0

    # Check binaries
    if [[ "$INSTALL_CORE" == "true" ]]; then
        if [[ -x "$INSTALL_PREFIX/bin/aws-core" ]]; then
            log_success "Core binary: OK"
        else
            log_error "Core binary: NOT FOUND"
            ((errors++))
        fi
    fi

    # Check configuration
    if [[ -f "$CONFIG_DIR/config.yaml" ]]; then
        log_success "Configuration: OK"
    else
        log_error "Configuration: NOT FOUND"
        ((errors++))
    fi

    # Check directories
    if [[ -d "$DATA_DIR" ]]; then
        log_success "Data directory: OK"
    else
        log_error "Data directory: NOT FOUND"
        ((errors++))
    fi

    if [[ $errors -eq 0 ]]; then
        log_success "Installation validation passed"
        return 0
    else
        log_error "Installation validation failed with $errors errors"
        return 1
    fi
}

# ============================================================================
# MAIN INSTALLATION FLOW
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --mode)
                INSTALL_MODE="$2"
                shift 2
                ;;
            --no-interactive)
                INTERACTIVE=false
                shift
                ;;
            --offline)
                OFFLINE_MODE=true
                shift
                ;;
            --skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --skip-services)
                SKIP_SERVICES=true
                shift
                ;;
            --prefix)
                INSTALL_PREFIX="$2"
                shift 2
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

main() {
    INSTALL_START_TIME=$(date +%s)

    # Print banner
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    _                 _               _      __        __         _     __ _
   / \   ___ __ _  __| | ___ _ __ ___ (_) ___ \ \      / /__  _ __| | __/ _| | _____      __
  / _ \ / __/ _` |/ _` |/ _ \ '_ ` _ \| |/ __| \ \ /\ / / _ \| '__| |/ / |_| |/ _ \ \ /\ / /
 / ___ \ (_| (_| | (_| |  __/ | | | | | | (__   \ V  V / (_) | |  |   <|  _| | (_) \ V  V /
/_/   \_\___\__,_|\__,_|\___|_| |_| |_|_|\___|   \_/\_/ \___/|_|  |_|\_\_| |_|\___/ \_/\_/

                          Suite Installer v$SCRIPT_VERSION
EOF
    echo -e "${NC}"
    echo

    # Parse arguments
    parse_arguments "$@"

    # Initialize logging
    log_info "Installation started"
    log_info "Log file: $LOG_FILE"

    # Detect system
    detect_os || exit 1
    check_system_requirements || exit 1

    # Interactive mode
    if [[ "$INTERACTIVE" == "true" ]] && [[ -z "$INSTALL_MODE" ]]; then
        show_main_menu || exit 1
        show_installation_summary || exit 1
    fi

    # Set defaults for non-interactive mode
    if [[ -z "$INSTALL_MODE" ]]; then
        INSTALL_MODE="quick"
        INSTALL_CORE=true
        INSTALL_BACKEND=true
        INSTALL_OFFICE=true
    fi

    # Check and install dependencies
    if ! check_all_dependencies; then
        log_warn "Some dependencies are missing"
        install_dependencies || exit 1
        check_all_dependencies || exit 1
    fi

    # Create directories
    create_directories || exit 1

    # Build components
    if [[ "$SKIP_BUILD" != "true" ]]; then
        build_core || exit 1
        build_backend || exit 1
        build_office_addin || exit 1
        build_ai_jail || exit 1
    fi

    # Download AI models
    download_all_ai_models || exit 1

    # Install files
    install_binaries || exit 1
    install_configuration || exit 1

    # Configure system
    configure_services || exit 1
    setup_environment || exit 1

    # Validate
    validate_installation || exit 1

    INSTALL_SUCCESS=true

    # Print success message
    print_header "Installation Complete!"

    echo -e "${GREEN}Academic Workflow Suite has been successfully installed!${NC}"
    echo
    echo "Installation Details:"
    echo "  Installation Path: $INSTALL_PREFIX"
    echo "  Configuration:     $CONFIG_DIR"
    echo "  Data Directory:    $DATA_DIR"
    echo
    echo "Next Steps:"
    echo "  1. Restart your terminal or run: source ~/.bashrc"
    echo "  2. Start the core service: systemctl --user start aws-core"
    echo "  3. Check status: systemctl --user status aws-core"
    echo
    echo "For more information, visit the documentation."
    echo

    log_success "Installation completed successfully!"
}

# Run main
main "$@"
