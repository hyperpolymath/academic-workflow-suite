.PHONY: all build release test clean install uninstall completions help

# Variables
BINARY_NAME := aws
INSTALL_PATH := /usr/local/bin
COMPLETION_DIR := completions

# Default target
all: build

# Build in debug mode
build:
	@echo "Building $(BINARY_NAME) (debug)..."
	cargo build
	@echo "✓ Build complete: target/debug/$(BINARY_NAME)"

# Build in release mode (optimized)
release:
	@echo "Building $(BINARY_NAME) (release)..."
	cargo build --release
	@echo "✓ Build complete: target/release/$(BINARY_NAME)"

# Run tests
test:
	@echo "Running tests..."
	cargo test
	@echo "✓ Tests complete"

# Run tests with output
test-verbose:
	@echo "Running tests (verbose)..."
	cargo test -- --nocapture
	@echo "✓ Tests complete"

# Run clippy (linter)
lint:
	@echo "Running clippy..."
	cargo clippy -- -D warnings
	@echo "✓ Linting complete"

# Format code
fmt:
	@echo "Formatting code..."
	cargo fmt
	@echo "✓ Formatting complete"

# Check formatting
fmt-check:
	@echo "Checking code formatting..."
	cargo fmt -- --check
	@echo "✓ Format check complete"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	cargo clean
	@echo "✓ Clean complete"

# Install to system (requires sudo)
install: release
	@echo "Installing $(BINARY_NAME) to $(INSTALL_PATH)..."
	@sudo cp target/release/$(BINARY_NAME) $(INSTALL_PATH)/$(BINARY_NAME)
	@sudo chmod +x $(INSTALL_PATH)/$(BINARY_NAME)
	@echo "✓ Installed $(INSTALL_PATH)/$(BINARY_NAME)"
	@echo ""
	@echo "Run 'make completions' to generate shell completions"

# Uninstall from system (requires sudo)
uninstall:
	@echo "Uninstalling $(BINARY_NAME) from $(INSTALL_PATH)..."
	@sudo rm -f $(INSTALL_PATH)/$(BINARY_NAME)
	@echo "✓ Uninstalled"

# Generate shell completions
completions: release
	@echo "Generating shell completions..."
	@cd $(COMPLETION_DIR) && ./generate_completions.sh
	@echo "✓ Completions generated"

# Install completions (bash)
install-completions-bash: completions
	@echo "Installing bash completions..."
	@sudo cp $(COMPLETION_DIR)/$(BINARY_NAME).bash /etc/bash_completion.d/$(BINARY_NAME)
	@echo "✓ Bash completions installed"
	@echo "Restart your shell or run: source /etc/bash_completion.d/$(BINARY_NAME)"

# Install completions (zsh)
install-completions-zsh: completions
	@echo "Installing zsh completions..."
	@mkdir -p ~/.zsh/completion
	@cp $(COMPLETION_DIR)/_$(BINARY_NAME) ~/.zsh/completion/
	@echo "✓ Zsh completions installed"
	@echo "Add ~/.zsh/completion to your fpath in ~/.zshrc if not already done"
	@echo "Then run: compinit"

# Install completions (fish)
install-completions-fish: completions
	@echo "Installing fish completions..."
	@mkdir -p ~/.config/fish/completions
	@cp $(COMPLETION_DIR)/$(BINARY_NAME).fish ~/.config/fish/completions/
	@echo "✓ Fish completions installed"

# Run the CLI (debug mode)
run:
	cargo run -- $(ARGS)

# Run the CLI with help
run-help:
	cargo run -- --help

# Build documentation
doc:
	@echo "Building documentation..."
	cargo doc --no-deps
	@echo "✓ Documentation complete"
	@echo "View at: target/doc/$(BINARY_NAME)/index.html"

# Open documentation in browser
doc-open:
	cargo doc --no-deps --open

# Check for security vulnerabilities
audit:
	@echo "Running security audit..."
	cargo audit
	@echo "✓ Security audit complete"

# Update dependencies
update:
	@echo "Updating dependencies..."
	cargo update
	@echo "✓ Dependencies updated"

# Full CI check (lint, test, build)
ci: fmt-check lint test release
	@echo "✓ CI checks passed"

# Development setup
dev-setup:
	@echo "Setting up development environment..."
	rustup component add clippy rustfmt
	cargo install cargo-audit
	@echo "✓ Development environment ready"

# Show help
help:
	@echo "AWS CLI - Makefile targets:"
	@echo ""
	@echo "Building:"
	@echo "  make build              Build in debug mode"
	@echo "  make release            Build in release mode (optimized)"
	@echo "  make clean              Clean build artifacts"
	@echo ""
	@echo "Testing:"
	@echo "  make test               Run tests"
	@echo "  make test-verbose       Run tests with output"
	@echo "  make lint               Run clippy linter"
	@echo "  make fmt                Format code"
	@echo "  make fmt-check          Check code formatting"
	@echo ""
	@echo "Installation:"
	@echo "  make install            Install to $(INSTALL_PATH) (requires sudo)"
	@echo "  make uninstall          Uninstall from $(INSTALL_PATH) (requires sudo)"
	@echo ""
	@echo "Completions:"
	@echo "  make completions                Generate shell completions"
	@echo "  make install-completions-bash   Install bash completions"
	@echo "  make install-completions-zsh    Install zsh completions"
	@echo "  make install-completions-fish   Install fish completions"
	@echo ""
	@echo "Development:"
	@echo "  make run ARGS='...'     Run CLI with arguments"
	@echo "  make run-help           Run CLI with --help"
	@echo "  make doc                Build documentation"
	@echo "  make doc-open           Build and open documentation"
	@echo "  make audit              Run security audit"
	@echo "  make update             Update dependencies"
	@echo "  make ci                 Run full CI checks"
	@echo "  make dev-setup          Setup development environment"
	@echo ""
	@echo "Examples:"
	@echo "  make run ARGS='status'"
	@echo "  make run ARGS='mark --interactive'"
