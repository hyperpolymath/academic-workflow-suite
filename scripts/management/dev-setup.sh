#!/usr/bin/env bash
#
# dev-setup.sh - Development environment setup for Academic Workflow Suite
#
# Usage: ./dev-setup.sh [OPTIONS]
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="/var/log/aws"
LOG_FILE="$LOG_DIR/dev-setup.log"

# ============================================================================
# Color Output
# ============================================================================

if [[ -t 1 ]]; then
    RED=$(tput setaf 1 2>/dev/null || echo '')
    GREEN=$(tput setaf 2 2>/dev/null || echo '')
    YELLOW=$(tput setaf 3 2>/dev/null || echo '')
    BLUE=$(tput setaf 4 2>/dev/null || echo '')
    MAGENTA=$(tput setaf 5 2>/dev/null || echo '')
    CYAN=$(tput setaf 6 2>/dev/null || echo '')
    BOLD=$(tput bold 2>/dev/null || echo '')
    RESET=$(tput sgr0 2>/dev/null || echo '')
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    BOLD=''
    RESET=''
fi

# ============================================================================
# Global Variables
# ============================================================================

VERBOSE=false
DRY_RUN=false
SKIP_GIT_HOOKS=false
SKIP_LSP=false
SKIP_DEPS=false
SKIP_BUILD=false

# ============================================================================
# Functions
# ============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ -d "$LOG_DIR" ]] && [[ -w "$LOG_DIR" ]]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi

    if [[ "$VERBOSE" == true ]] || [[ "$level" != "DEBUG" ]]; then
        case "$level" in
            ERROR)   echo "${RED}[ERROR]${RESET} $message" >&2 ;;
            WARN)    echo "${YELLOW}[WARN]${RESET} $message" ;;
            SUCCESS) echo "${GREEN}[OK]${RESET} $message" ;;
            INFO)    echo "${BLUE}[INFO]${RESET} $message" ;;
            DEBUG)   echo "${CYAN}[DEBUG]${RESET} $message" ;;
            *)       echo "$message" ;;
        esac
    fi
}

usage() {
    cat << EOF
${BOLD}Academic Workflow Suite - Development Setup${RESET}

Usage: $0 [OPTIONS]

OPTIONS:
    --verbose           Enable verbose output
    --dry-run           Simulate setup without making changes
    --skip-git-hooks    Skip git hooks installation
    --skip-lsp          Skip LSP server installation
    --skip-deps         Skip dependency installation
    --skip-build        Skip initial build
    -h, --help          Show this help message

DESCRIPTION:
    Sets up a complete development environment for AWS:
    - Installs development dependencies
    - Sets up git hooks (pre-commit, commit-msg)
    - Installs LSP servers (rust-analyzer, elixir-ls)
    - Creates .env file from template
    - Builds all components in dev mode
    - Verifies installation

EXAMPLES:
    $0                      # Full development setup
    $0 --skip-build         # Setup without building
    $0 --verbose            # Show detailed progress

EOF
    exit 0
}

print_header() {
    local title="$1"
    echo ""
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo "${BOLD}${CYAN}  $title${RESET}"
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo ""
}

check_system_dependencies() {
    print_header "Checking System Dependencies"

    local missing_deps=()

    # Check for essential tools
    local required_tools=(
        "git:git"
        "curl:curl"
        "make:make"
    )

    for tool_spec in "${required_tools[@]}"; do
        IFS=':' read -r cmd package <<< "$tool_spec"

        if ! command -v "$cmd" &> /dev/null; then
            log WARN "$cmd not found"
            missing_deps+=("$package")
        else
            local version
            version=$("$cmd" --version 2>&1 | head -1)
            log SUCCESS "$cmd found: $version"
        fi
    done

    # Check for Rust
    if ! command -v cargo &> /dev/null; then
        log WARN "Rust not found. Install from: https://rustup.rs/"
        missing_deps+=("rust")
    else
        local rust_version
        rust_version=$(rustc --version)
        log SUCCESS "Rust found: $rust_version"
    fi

    # Check for Node.js
    if ! command -v node &> /dev/null; then
        log WARN "Node.js not found. Install from: https://nodejs.org/"
        missing_deps+=("nodejs")
    else
        local node_version
        node_version=$(node --version)
        log SUCCESS "Node.js found: $node_version"
    fi

    # Check for Elixir
    if ! command -v elixir &> /dev/null; then
        log WARN "Elixir not found. Install from: https://elixir-lang.org/install.html"
        missing_deps+=("elixir")
    else
        local elixir_version
        elixir_version=$(elixir --version | head -1)
        log SUCCESS "Elixir found: $elixir_version"
    fi

    # Check for PostgreSQL client
    if ! command -v psql &> /dev/null; then
        log WARN "PostgreSQL client not found"
        missing_deps+=("postgresql-client")
    else
        log SUCCESS "PostgreSQL client found"
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log ERROR "Missing dependencies: ${missing_deps[*]}"
        log INFO "Please install missing dependencies and run this script again"
        return 1
    fi

    log SUCCESS "All system dependencies satisfied"
}

install_rust_dependencies() {
    print_header "Installing Rust Dependencies"

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would install Rust dependencies"
        return 0
    fi

    # Install additional Rust tools
    local rust_tools=(
        "cargo-watch"
        "cargo-edit"
        "cargo-audit"
    )

    for tool in "${rust_tools[@]}"; do
        if ! cargo install --list | grep -q "^$tool"; then
            log INFO "Installing $tool..."
            cargo install "$tool" || log WARN "Failed to install $tool"
        else
            log DEBUG "$tool already installed"
        fi
    done

    # Install rustfmt and clippy
    if ! command -v rustfmt &> /dev/null; then
        log INFO "Installing rustfmt..."
        rustup component add rustfmt
    fi

    if ! command -v cargo-clippy &> /dev/null; then
        log INFO "Installing clippy..."
        rustup component add clippy
    fi

    log SUCCESS "Rust dependencies installed"
}

install_node_dependencies() {
    print_header "Installing Node.js Dependencies"

    local office_addin_dir="$PROJECT_ROOT/components/office-addin"

    if [[ ! -d "$office_addin_dir" ]]; then
        log WARN "Office add-in directory not found"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would install Node.js dependencies"
        return 0
    fi

    log INFO "Installing npm packages..."

    (
        cd "$office_addin_dir"
        npm install --prefer-offline
    )

    log SUCCESS "Node.js dependencies installed"

    # Install global dev tools
    local global_tools=(
        "eslint"
        "prettier"
    )

    for tool in "${global_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log INFO "Installing global tool: $tool..."
            npm install -g "$tool" || log WARN "Failed to install $tool"
        fi
    done
}

install_elixir_dependencies() {
    print_header "Installing Elixir Dependencies"

    local backend_dir="$PROJECT_ROOT/components/backend"

    if [[ ! -f "$backend_dir/mix.exs" ]]; then
        log WARN "Elixir project not found"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would install Elixir dependencies"
        return 0
    fi

    log INFO "Installing Hex and Rebar..."
    mix local.hex --force
    mix local.rebar --force

    log INFO "Installing Elixir packages..."

    (
        cd "$backend_dir"
        mix deps.get
        mix deps.compile
    )

    log SUCCESS "Elixir dependencies installed"
}

setup_git_hooks() {
    print_header "Setting Up Git Hooks"

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would setup git hooks"
        return 0
    fi

    local hooks_dir="$PROJECT_ROOT/.git/hooks"

    # Create pre-commit hook
    log INFO "Creating pre-commit hook..."

    cat > "$hooks_dir/pre-commit" << 'EOF'
#!/usr/bin/env bash
#
# Pre-commit hook for Academic Workflow Suite
#

set -e

echo "Running pre-commit checks..."

# Run Rust formatting check
if command -v cargo &> /dev/null; then
    echo "Checking Rust formatting..."
    cargo fmt --all -- --check || {
        echo "Error: Rust code is not formatted. Run 'cargo fmt --all' to fix."
        exit 1
    }
fi

# Run Rust linting
if command -v cargo &> /dev/null; then
    echo "Running Rust clippy..."
    cargo clippy --all-targets --all-features -- -D warnings || {
        echo "Error: Clippy found issues. Please fix them before committing."
        exit 1
    }
fi

# Run Elixir formatting check
if command -v mix &> /dev/null && [ -f "mix.exs" ]; then
    echo "Checking Elixir formatting..."
    mix format --check-formatted || {
        echo "Error: Elixir code is not formatted. Run 'mix format' to fix."
        exit 1
    }
fi

# Run JavaScript/TypeScript linting
if command -v npm &> /dev/null && [ -f "package.json" ]; then
    echo "Running ESLint..."
    npm run lint || {
        echo "Error: ESLint found issues. Please fix them before committing."
        exit 1
    }
fi

echo "Pre-commit checks passed!"
EOF

    chmod +x "$hooks_dir/pre-commit"
    log SUCCESS "Pre-commit hook created"

    # Create commit-msg hook
    log INFO "Creating commit-msg hook..."

    cat > "$hooks_dir/commit-msg" << 'EOF'
#!/usr/bin/env bash
#
# Commit message hook for Academic Workflow Suite
#

commit_msg_file="$1"
commit_msg=$(cat "$commit_msg_file")

# Check commit message format (conventional commits)
if ! echo "$commit_msg" | grep -qE "^(feat|fix|docs|style|refactor|perf|test|chore|build|ci)(\(.+\))?: .+"; then
    echo "Error: Commit message does not follow conventional commits format"
    echo ""
    echo "Format: <type>(<scope>): <subject>"
    echo ""
    echo "Types: feat, fix, docs, style, refactor, perf, test, chore, build, ci"
    echo ""
    echo "Example: feat(backend): add user authentication"
    echo ""
    exit 1
fi

# Check commit message length
first_line=$(echo "$commit_msg" | head -1)
if [ ${#first_line} -gt 72 ]; then
    echo "Error: Commit message first line is too long (max 72 characters)"
    exit 1
fi

echo "Commit message format is valid"
EOF

    chmod +x "$hooks_dir/commit-msg"
    log SUCCESS "Commit-msg hook created"

    log SUCCESS "Git hooks configured"
}

install_lsp_servers() {
    print_header "Installing LSP Servers"

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would install LSP servers"
        return 0
    fi

    # Install rust-analyzer
    if ! command -v rust-analyzer &> /dev/null; then
        log INFO "Installing rust-analyzer..."
        rustup component add rust-analyzer || {
            log WARN "Failed to install rust-analyzer via rustup, trying manual installation..."

            # Manual installation
            local ra_version="2024-01-15"
            curl -L "https://github.com/rust-lang/rust-analyzer/releases/download/$ra_version/rust-analyzer-x86_64-unknown-linux-gnu.gz" \
                | gunzip -c - > ~/.cargo/bin/rust-analyzer
            chmod +x ~/.cargo/bin/rust-analyzer
        }
        log SUCCESS "rust-analyzer installed"
    else
        log DEBUG "rust-analyzer already installed"
    fi

    # Install elixir-ls
    if ! command -v elixir-ls &> /dev/null; then
        log INFO "Installing elixir-ls..."

        local els_dir="$HOME/.local/share/elixir-ls"
        mkdir -p "$els_dir"

        if [[ ! -d "$els_dir/elixir-ls" ]]; then
            git clone https://github.com/elixir-lsp/elixir-ls.git "$els_dir/elixir-ls" || {
                log WARN "Failed to clone elixir-ls"
                return 0
            }

            (
                cd "$els_dir/elixir-ls"
                mix deps.get
                MIX_ENV=prod mix compile
                MIX_ENV=prod mix elixir_ls.release -o release
            )

            # Create symlink
            mkdir -p "$HOME/.local/bin"
            ln -sf "$els_dir/elixir-ls/release/language_server.sh" "$HOME/.local/bin/elixir-ls"
        fi

        log SUCCESS "elixir-ls installed"
    else
        log DEBUG "elixir-ls already installed"
    fi

    log SUCCESS "LSP servers installed"
}

create_env_file() {
    print_header "Creating Environment File"

    local env_file="$PROJECT_ROOT/.env"
    local env_template="$PROJECT_ROOT/.env.template"

    if [[ -f "$env_file" ]]; then
        log INFO ".env file already exists, skipping"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would create .env file"
        return 0
    fi

    # Create .env from template if it exists
    if [[ -f "$env_template" ]]; then
        log INFO "Creating .env from template..."
        cp "$env_template" "$env_file"
        log SUCCESS ".env file created from template"
    else
        # Create default .env
        log INFO "Creating default .env file..."

        cat > "$env_file" << EOF
# Academic Workflow Suite - Development Environment
# Generated by dev-setup.sh

# Database Configuration
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=aws_development
POSTGRES_TEST_DB=aws_test

# Backend Configuration
BACKEND_PORT=4000
BACKEND_HOST=localhost
SECRET_KEY_BASE=$(openssl rand -base64 64 | tr -d '\n')

# AI Jail Configuration
AI_JAIL_PORT=8080
AI_JAIL_HOST=localhost

# Event Store Configuration
EVENT_STORE_PATH=$PROJECT_ROOT/events
EVENT_STORE_SIZE=10737418240

# Development Settings
MIX_ENV=dev
NODE_ENV=development
RUST_LOG=debug

# API Keys (add your keys here)
# OPENAI_API_KEY=
# ANTHROPIC_API_KEY=

EOF

        log SUCCESS "Default .env file created"
    fi

    log WARN "Please review and update .env file with your configuration"
}

build_components() {
    print_header "Building Components"

    if [[ "$DRY_RUN" == true ]]; then
        log DEBUG "DRY-RUN: Would build components"
        return 0
    fi

    # Build Rust components
    local backend_dir="$PROJECT_ROOT/components/backend"
    if [[ -f "$backend_dir/Cargo.toml" ]]; then
        log INFO "Building Rust backend..."
        (cd "$backend_dir" && cargo build) || log WARN "Backend build failed"
    fi

    local ai_jail_dir="$PROJECT_ROOT/components/ai-jail"
    if [[ -f "$ai_jail_dir/Cargo.toml" ]]; then
        log INFO "Building Rust AI jail..."
        (cd "$ai_jail_dir" && cargo build) || log WARN "AI jail build failed"
    fi

    # Build Elixir components
    if [[ -f "$backend_dir/mix.exs" ]]; then
        log INFO "Compiling Elixir backend..."
        (cd "$backend_dir" && mix compile) || log WARN "Elixir compilation failed"
    fi

    # Build ReScript/Node components
    local office_addin_dir="$PROJECT_ROOT/components/office-addin"
    if [[ -f "$office_addin_dir/package.json" ]]; then
        log INFO "Building office add-in..."
        (cd "$office_addin_dir" && npm run build) || log WARN "Office add-in build failed"
    fi

    log SUCCESS "Components built"
}

verify_setup() {
    print_header "Verifying Setup"

    local all_ok=true

    # Check if .env exists
    if [[ -f "$PROJECT_ROOT/.env" ]]; then
        log SUCCESS ".env file exists"
    else
        log ERROR ".env file not found"
        all_ok=false
    fi

    # Check git hooks
    if [[ -x "$PROJECT_ROOT/.git/hooks/pre-commit" ]]; then
        log SUCCESS "Git hooks installed"
    else
        log WARN "Git hooks not installed"
    fi

    # Check dependencies
    if [[ -d "$PROJECT_ROOT/components/backend/target" ]]; then
        log SUCCESS "Rust backend built"
    else
        log WARN "Rust backend not built"
    fi

    if [[ -d "$PROJECT_ROOT/components/office-addin/node_modules" ]]; then
        log SUCCESS "Node.js dependencies installed"
    else
        log WARN "Node.js dependencies not installed"
    fi

    if [[ "$all_ok" == true ]]; then
        log SUCCESS "Development environment setup verified"
    else
        log WARN "Some components may need attention"
    fi
}

print_summary() {
    echo ""
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo "${BOLD}${CYAN}  Development Setup Complete${RESET}"
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo ""
    echo "  ${BOLD}Next Steps:${RESET}"
    echo ""
    echo "  1. Review and update ${CYAN}.env${RESET} file"
    echo "  2. Initialize database: ${YELLOW}./scripts/management/init-database.sh${RESET}"
    echo "  3. Run tests: ${YELLOW}./scripts/management/test-all.sh${RESET}"
    echo "  4. Start development:"
    echo "     ${CYAN}cd components/backend && cargo run${RESET}"
    echo "     ${CYAN}cd components/ai-jail && cargo run${RESET}"
    echo "     ${CYAN}cd components/office-addin && npm run dev${RESET}"
    echo ""
    echo "  ${BOLD}Useful Commands:${RESET}"
    echo "  - ${YELLOW}cargo watch -x run${RESET}     # Auto-reload Rust"
    echo "  - ${YELLOW}mix phx.server${RESET}         # Start Phoenix server"
    echo "  - ${YELLOW}npm run dev${RESET}            # Start dev server"
    echo ""
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo ""
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose)
                VERBOSE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --skip-git-hooks)
                SKIP_GIT_HOOKS=true
                shift
                ;;
            --skip-lsp)
                SKIP_LSP=true
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
            -h|--help)
                usage
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage
                ;;
        esac
    done

    # Create log directory if it doesn't exist
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || true
    fi

    print_header "Academic Workflow Suite - Development Setup"

    log INFO "Starting development environment setup..."
    [[ "$DRY_RUN" == true ]] && log INFO "Running in DRY-RUN mode"

    # Check system dependencies
    check_system_dependencies || exit 1

    # Install dependencies
    if [[ "$SKIP_DEPS" == false ]]; then
        install_rust_dependencies
        install_node_dependencies
        install_elixir_dependencies
    fi

    # Setup git hooks
    if [[ "$SKIP_GIT_HOOKS" == false ]]; then
        setup_git_hooks
    fi

    # Install LSP servers
    if [[ "$SKIP_LSP" == false ]]; then
        install_lsp_servers
    fi

    # Create .env file
    create_env_file

    # Build components
    if [[ "$SKIP_BUILD" == false ]]; then
        build_components
    fi

    # Verify setup
    verify_setup

    # Print summary
    print_summary

    log SUCCESS "Development environment setup completed"
}

# ============================================================================
# Entry Point
# ============================================================================

main "$@"
