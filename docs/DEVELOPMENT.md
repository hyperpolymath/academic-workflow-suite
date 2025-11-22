# Development Guide

**Complete developer guide for contributing to Academic Workflow Suite**

This guide covers everything you need to know to contribute to AWS development.

---

## Table of Contents

- [Getting Started](#getting-started)
- [Development Environment Setup](#development-environment-setup)
- [Project Structure](#project-structure)
- [Building from Source](#building-from-source)
- [Running Tests](#running-tests)
- [Code Style & Standards](#code-style--standards)
- [Contributing Guidelines](#contributing-guidelines)
- [Development Workflow](#development-workflow)
- [Debugging](#debugging)
- [Performance Profiling](#performance-profiling)
- [Release Process](#release-process)
- [Troubleshooting](#troubleshooting)

---

## Getting Started

### Prerequisites

Before you begin, ensure you have:

- **Git**: Version 2.0+
- **Rust**: 1.70+ (install via [rustup](https://rustup.rs/))
- **Node.js**: 18+ (for Office add-in)
- **Docker** or **Podman**: Latest version
- **Code Editor**: VS Code (recommended) or your preferred editor

### Quick Start for Developers

```bash
# Clone the repository
git clone https://github.com/academic-workflow-suite/aws.git
cd aws

# Run setup script
./scripts/dev/setup.sh

# Build all components
./scripts/dev/build-all.sh

# Run tests
./scripts/dev/test-all.sh

# Start development servers
./scripts/dev/start-all.sh
```

---

## Development Environment Setup

### 1. Install Rust

```bash
# Install Rust via rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add to PATH (add to ~/.bashrc or ~/.zshrc)
source $HOME/.cargo/env

# Verify installation
rustc --version
cargo --version

# Install useful tools
cargo install cargo-watch      # Auto-rebuild on file changes
cargo install cargo-edit        # Manage dependencies
cargo install cargo-outdated    # Check outdated dependencies
```

### 2. Install Node.js

```bash
# Using nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
nvm install 18
nvm use 18

# Or download from nodejs.org
# Verify installation
node --version
npm --version

# Install global tools
npm install -g office-addin-dev-certs
npm install -g office-addin-dev-server
```

### 3. Install Docker

**macOS**:
```bash
# Download Docker Desktop
open https://www.docker.com/products/docker-desktop

# Or via Homebrew
brew install --cask docker
```

**Linux**:
```bash
# Install Docker
curl -fsSL https://get.docker.com | sudo sh

# Add user to docker group
sudo usermod -aG docker $USER

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker
```

**Windows**:
```powershell
# Download Docker Desktop
start https://www.docker.com/products/docker-desktop
```

### 4. Install VS Code (Recommended)

```bash
# macOS
brew install --cask visual-studio-code

# Linux (Ubuntu/Debian)
sudo snap install code --classic

# Windows: Download from code.visualstudio.com
```

**Recommended Extensions**:
- **rust-analyzer**: Rust language support
- **ReScript**: ReScript language support
- **Docker**: Docker management
- **GitLens**: Git visualization
- **Thunder Client**: API testing
- **Prettier**: Code formatting

### 5. Configure Git

```bash
# Set your name and email
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Set up commit signing (optional but recommended)
git config --global commit.gpgsign true
git config --global user.signingkey YOUR_GPG_KEY_ID

# Set up helpful aliases
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
```

---

## Project Structure

```
academic-workflow-suite/
├── components/
│   ├── core/                    # Core engine (Rust)
│   │   ├── src/
│   │   │   ├── lib.rs          # Library entry point
│   │   │   ├── main.rs         # Binary entry point
│   │   │   ├── api/            # REST API handlers
│   │   │   ├── domain/         # Business logic
│   │   │   ├── event_store/    # Event sourcing
│   │   │   ├── anonymization/  # Privacy layer
│   │   │   └── ai_client/      # AI jail communication
│   │   ├── tests/              # Integration tests
│   │   ├── benches/            # Benchmarks
│   │   └── Cargo.toml          # Rust dependencies
│   │
│   ├── office-addin/           # Office add-in (ReScript)
│   │   ├── src/
│   │   │   ├── App.res         # Main app component
│   │   │   ├── TaskPane.res    # Task pane UI
│   │   │   ├── ApiClient.res   # HTTP client
│   │   │   └── State.res       # State management
│   │   ├── tests/              # Jest tests
│   │   ├── package.json        # npm dependencies
│   │   └── webpack.config.js   # Build configuration
│   │
│   ├── ai-jail/                # AI jail (Rust + Docker)
│   │   ├── src/
│   │   │   ├── main.rs         # IPC server
│   │   │   ├── inference.rs    # AI model inference
│   │   │   └── models/         # Model loaders
│   │   ├── Dockerfile          # Container definition
│   │   └── Cargo.toml
│   │
│   ├── backend/                # Optional backend (Rust)
│   │   ├── src/
│   │   │   ├── main.rs
│   │   │   ├── rubrics.rs      # Rubric repository
│   │   │   └── updates.rs      # Update server
│   │   └── Cargo.toml
│   │
│   └── shared/                 # Shared code
│       ├── rust/               # Rust shared types
│       └── rescript/           # ReScript shared types
│
├── scripts/
│   ├── dev/                    # Development scripts
│   │   ├── setup.sh            # Setup dev environment
│   │   ├── build-all.sh        # Build all components
│   │   ├── test-all.sh         # Run all tests
│   │   └── start-all.sh        # Start dev servers
│   ├── install/                # Installation scripts
│   └── management/             # Admin scripts
│
├── tests/                      # End-to-end tests
│   ├── integration/
│   ├── e2e/
│   └── fixtures/
│
├── docs/                       # Documentation
│   ├── README.md
│   ├── ARCHITECTURE.md
│   ├── API_REFERENCE.md
│   └── ...
│
├── config/                     # Configuration files
│   ├── rubrics/                # Default rubrics
│   └── models/                 # AI model configs
│
├── .github/
│   ├── workflows/              # CI/CD pipelines
│   └── ISSUE_TEMPLATE/
│
├── Cargo.toml                  # Workspace configuration
├── package.json                # Workspace npm config
├── README.md
├── LICENSE
└── CLAUDE.md
```

---

## Building from Source

### Build All Components

```bash
# One command to build everything
./scripts/dev/build-all.sh
```

This script does:
1. Builds Rust core engine
2. Builds Office add-in
3. Builds AI jail container
4. Runs post-build checks

### Build Individual Components

#### Core Engine (Rust)

```bash
cd components/core

# Development build (faster, includes debug info)
cargo build

# Release build (optimized)
cargo build --release

# Build specific binary
cargo build --bin aws-core

# Build with features
cargo build --features "full-ai offline-mode"

# Check compilation without building
cargo check

# Watch mode (rebuild on file change)
cargo watch -x build
```

#### Office Add-in (ReScript)

```bash
cd components/office-addin

# Install dependencies
npm install

# Development build
npm run build

# Watch mode (rebuild on file change)
npm run dev

# Production build
npm run build -- --mode production

# Type checking only
npx rescript build
```

#### AI Jail (Docker)

```bash
cd components/ai-jail

# Build container image
docker build -t aws-ai-jail:dev .

# Build with specific platform
docker build --platform linux/amd64 -t aws-ai-jail:dev .

# Build and tag
docker build -t aws-ai-jail:dev -t aws-ai-jail:latest .
```

### Cross-Compilation

Build for different platforms:

```bash
# Add target
rustup target add x86_64-pc-windows-gnu
rustup target add x86_64-apple-darwin
rustup target add aarch64-apple-darwin

# Build for Windows
cargo build --release --target x86_64-pc-windows-gnu

# Build for macOS Intel
cargo build --release --target x86_64-apple-darwin

# Build for macOS Apple Silicon
cargo build --release --target aarch64-apple-darwin
```

---

## Running Tests

### Run All Tests

```bash
# Run all tests across all components
./scripts/dev/test-all.sh
```

### Rust Tests

```bash
cd components/core

# Run all tests
cargo test

# Run specific test
cargo test test_anonymization

# Run tests with output
cargo test -- --nocapture

# Run tests in parallel
cargo test -- --test-threads=4

# Run only integration tests
cargo test --test '*'

# Run benchmarks
cargo bench

# Generate coverage report
cargo tarpaulin --out Html
```

### ReScript/JavaScript Tests

```bash
cd components/office-addin

# Run all tests
npm test

# Run tests in watch mode
npm test -- --watch

# Run specific test file
npm test -- TaskPane.test.js

# Generate coverage report
npm test -- --coverage
```

### Integration Tests

```bash
# Run end-to-end tests
cd tests/e2e
npm install
npm test

# Run specific test suite
npm test -- marking-workflow.test.js
```

### Docker Container Tests

```bash
cd components/ai-jail

# Test container build
docker build --target test -t aws-ai-jail:test .

# Run isolation tests
./tests/test-isolation.sh

# Test network isolation
docker run --rm aws-ai-jail:test /tests/test-network.sh
```

---

## Code Style & Standards

### Rust Code Style

AWS follows standard Rust conventions:

**Formatting**: Use `rustfmt`

```bash
# Format all Rust code
cargo fmt

# Check formatting without changing files
cargo fmt -- --check
```

**Linting**: Use `clippy`

```bash
# Run Clippy linter
cargo clippy

# Deny all warnings
cargo clippy -- -D warnings

# Fix automatically fixable issues
cargo clippy --fix
```

**Naming Conventions**:
- **Types**: `PascalCase` (e.g., `StudentId`, `EventStore`)
- **Functions**: `snake_case` (e.g., `anonymize_student_id`)
- **Constants**: `SCREAMING_SNAKE_CASE` (e.g., `MAX_ESSAY_LENGTH`)
- **Modules**: `snake_case` (e.g., `event_store`, `ai_client`)

**Example**:

```rust
// Good
pub struct DocumentState {
    document_id: Uuid,
    student_id_hash: Hash,
}

impl DocumentState {
    pub fn new(document_id: Uuid) -> Self {
        Self {
            document_id,
            student_id_hash: Hash::default(),
        }
    }

    pub fn anonymize_student_id(&mut self, id: &str, salt: &[u8; 32]) {
        self.student_id_hash = hash_student_id(id, salt);
    }
}

// Bad - violates naming conventions
pub struct documentState {  // Should be PascalCase
    DocumentID: Uuid,       // Should be snake_case
}
```

### ReScript Code Style

**Formatting**: Use ReScript formatter

```bash
# Format all ReScript code
npx rescript format

# Check formatting
npx rescript format -check
```

**Naming Conventions**:
- **Modules**: `PascalCase` (e.g., `TaskPane`, `ApiClient`)
- **Types**: `camelCase` (e.g., `documentState`, `analysisResult`)
- **Functions**: `camelCase` (e.g., `loadDocument`, `analyzeSubmission`)
- **Variants**: `PascalCase` (e.g., `Loading`, `Success`, `Error`)

**Example**:

```rescript
// Good
type documentState = {
  documentId: string,
  studentIdHash: string,
  status: documentStatus,
}

and documentStatus = Loading | Analyzing | Complete

let loadDocument = (studentId: string) => {
  // Implementation
}

// Bad - inconsistent naming
type DocumentState = {  // Should be camelCase for types
  document_id: string,  // Should be camelCase
}
```

### Documentation

**Rust Documentation**:

```rust
/// Anonymizes a student ID using SHA3-512 hashing.
///
/// # Arguments
///
/// * `student_id` - The student's OU ID (e.g., "A1234567")
/// * `salt` - A 32-byte random salt for the hash
///
/// # Returns
///
/// A 64-byte SHA3-512 hash of the student ID
///
/// # Examples
///
/// ```
/// let salt = generate_salt();
/// let hash = hash_student_id("A1234567", &salt);
/// assert_eq!(hash.len(), 64);
/// ```
pub fn hash_student_id(student_id: &str, salt: &[u8; 32]) -> [u8; 64] {
    // Implementation
}
```

**ReScript Documentation**:

```rescript
/**
 * Loads a document for marking.
 *
 * @param studentId - The student's OU ID
 * @param module - Module code (e.g., "TM112")
 * @param assignment - Assignment name (e.g., "TMA01")
 * @returns Promise resolving to document metadata
 */
let loadDocument = (
  ~studentId: string,
  ~module_: string,
  ~assignment: string,
): promise<documentMetadata> => {
  // Implementation
}
```

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

**Format**: `<type>(<scope>): <description>`

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Maintenance tasks

**Examples**:

```
feat(core): add batch analysis support
fix(addin): resolve feedback insertion bug
docs(api): update endpoint descriptions
test(core): add anonymization tests
refactor(ai-jail): simplify IPC protocol
```

---

## Contributing Guidelines

### Reporting Issues

Before creating an issue:

1. **Search existing issues** to avoid duplicates
2. **Provide context**: What were you trying to do?
3. **Include details**: Version, OS, error messages
4. **Steps to reproduce**: Minimal reproducible example

**Issue Template**:

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen.

**Environment**
- AWS Version: 0.1.0
- OS: macOS 14.1
- Office Version: Office 365
- Rust Version: 1.75.0

**Additional context**
Any other context or screenshots.
```

### Pull Request Process

1. **Fork the repository**

```bash
# Fork on GitHub, then clone your fork
git clone https://github.com/YOUR-USERNAME/aws.git
cd aws
git remote add upstream https://github.com/academic-workflow-suite/aws.git
```

2. **Create a feature branch**

```bash
git checkout -b feat/my-new-feature
```

3. **Make your changes**

- Write code following style guidelines
- Add tests for new functionality
- Update documentation as needed
- Ensure all tests pass: `./scripts/dev/test-all.sh`

4. **Commit your changes**

```bash
git add .
git commit -m "feat(core): add batch analysis support"
```

5. **Push to your fork**

```bash
git push origin feat/my-new-feature
```

6. **Create Pull Request**

- Go to GitHub and create a PR from your fork
- Fill out the PR template
- Link related issues
- Request review from maintainers

**PR Template**:

```markdown
**Description**
Brief description of changes.

**Related Issues**
Fixes #123, Related to #456

**Changes Made**
- Added batch analysis feature
- Updated API documentation
- Added tests for new functionality

**Testing**
- [ ] All tests pass
- [ ] New tests added
- [ ] Manually tested on macOS/Windows/Linux

**Documentation**
- [ ] Code comments added
- [ ] API documentation updated
- [ ] User guide updated (if needed)

**Screenshots** (if applicable)
```

7. **Code Review**

- Address reviewer feedback
- Make requested changes
- Keep discussion focused and respectful

8. **Merge**

Once approved, maintainers will merge your PR.

---

## Development Workflow

### Typical Development Cycle

```bash
# 1. Update your local repository
git checkout main
git pull upstream main

# 2. Create feature branch
git checkout -b feat/new-feature

# 3. Start development servers
./scripts/dev/start-all.sh

# 4. Make changes and test
# Edit code in VS Code
# Save files → auto-rebuild (watch mode)
# Check browser/Word for changes

# 5. Run tests frequently
cargo test                  # Rust tests
npm test                    # ReScript tests

# 6. Commit when ready
git add .
git commit -m "feat(component): description"

# 7. Push and create PR
git push origin feat/new-feature
# Create PR on GitHub

# 8. Address review feedback
git add .
git commit -m "refactor: address review comments"
git push origin feat/new-feature

# 9. After merge, update main
git checkout main
git pull upstream main
git branch -d feat/new-feature
```

### Development Servers

#### Core Engine Development Server

```bash
cd components/core

# Run with auto-reload
cargo watch -x 'run -- --dev'

# Or manually
cargo run -- --dev --log-level debug
```

#### Office Add-in Development Server

```bash
cd components/office-addin

# Start development server with hot reload
npm run dev

# In another terminal, start Office
npm run start
```

This opens Word with the add-in sideloaded. Changes to `.res` files auto-reload.

---

## Debugging

### Rust Debugging

**Using VS Code**:

1. Install `CodeLLDB` extension
2. Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "lldb",
      "request": "launch",
      "name": "Debug Core Engine",
      "cargo": {
        "args": ["build", "--bin=aws-core", "--package=aws-core"],
        "filter": {
          "name": "aws-core",
          "kind": "bin"
        }
      },
      "args": ["--dev"],
      "cwd": "${workspaceFolder}/components/core"
    }
  ]
}
```

3. Set breakpoints in code
4. Press F5 to start debugging

**Using `dbg!` macro**:

```rust
fn analyze_document(doc: &Document) -> Result<Analysis> {
    dbg!(&doc.student_id_hash);  // Prints to stderr
    let result = perform_analysis(doc)?;
    dbg!(&result);
    Ok(result)
}
```

**Using `tracing` for structured logging**:

```rust
use tracing::{info, warn, error, debug};

fn process_request(req: &Request) {
    info!("Processing request: {}", req.id);
    debug!(?req, "Full request details");

    if let Err(e) = validate_request(req) {
        error!("Validation failed: {}", e);
        return;
    }

    info!("Request processed successfully");
}
```

### ReScript/JavaScript Debugging

**Using VS Code**:

1. Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "chrome",
      "request": "launch",
      "name": "Debug Office Add-in",
      "url": "https://localhost:3000",
      "webRoot": "${workspaceFolder}/components/office-addin"
    }
  ]
}
```

2. Set breakpoints in `.res` files
3. Press F5

**Using `Js.log`**:

```rescript
let analyzeDocument = (documentId: string) => {
  Js.log("Analyzing document: " ++ documentId)

  let result = performAnalysis(documentId)
  Js.log2("Result:", result)

  result
}
```

### Debugging AI Jail

```bash
# Start AI jail with debug logging
docker run -it --rm \
  -e RUST_LOG=debug \
  -v $(pwd)/test-data:/data:ro \
  aws-ai-jail:dev

# Attach to running container
docker exec -it <container-id> /bin/sh

# View logs
docker logs -f <container-id>
```

---

## Performance Profiling

### Rust Profiling

**Using `cargo flamegraph`**:

```bash
# Install
cargo install flamegraph

# Profile
cargo flamegraph --bin aws-core

# Opens flamegraph.svg in browser
```

**Using `criterion` benchmarks**:

```bash
cd components/core

# Run benchmarks
cargo bench

# Compare with baseline
cargo bench -- --save-baseline my-baseline
# Make changes
cargo bench -- --baseline my-baseline
```

**Example benchmark**:

```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn benchmark_anonymization(c: &mut Criterion) {
    c.bench_function("hash_student_id", |b| {
        let id = "A1234567";
        let salt = [0u8; 32];
        b.iter(|| hash_student_id(black_box(id), black_box(&salt)))
    });
}

criterion_group!(benches, benchmark_anonymization);
criterion_main!(benches);
```

### JavaScript Profiling

**Using Chrome DevTools**:

1. Open add-in in Word
2. Right-click → Inspect
3. Go to Performance tab
4. Click Record, perform actions, Stop
5. Analyze flame graph

---

## Release Process

### Version Numbering

AWS uses [Semantic Versioning](https://semver.org/):

- **MAJOR.MINOR.PATCH** (e.g., 1.2.3)
- **MAJOR**: Breaking API changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

### Release Checklist

```
[ ] All tests passing on main branch
[ ] Documentation updated
[ ] CHANGELOG.md updated
[ ] Version bumped in Cargo.toml and package.json
[ ] Git tag created
[ ] Release notes written
[ ] Binaries built for all platforms
[ ] Docker images pushed
[ ] GitHub release created
[ ] Announcement published
```

### Creating a Release

```bash
# 1. Update version numbers
./scripts/management/bump-version.sh 0.2.0

# 2. Update CHANGELOG.md
vim CHANGELOG.md

# 3. Commit version bump
git add .
git commit -m "chore: bump version to 0.2.0"

# 4. Create tag
git tag -a v0.2.0 -m "Release version 0.2.0"

# 5. Push to GitHub
git push origin main
git push origin v0.2.0

# 6. Build release artifacts
./scripts/management/build-release.sh v0.2.0

# 7. Create GitHub release
# Go to https://github.com/academic-workflow-suite/aws/releases/new
# Upload binaries and write release notes

# 8. Publish announcement
# Forum, mailing list, etc.
```

---

## Troubleshooting

### Common Development Issues

#### Issue: `cargo build` fails with linker errors

**Solution**:

```bash
# macOS: Install Xcode Command Line Tools
xcode-select --install

# Linux: Install build essentials
sudo apt install build-essential

# Windows: Install Visual Studio Build Tools
```

#### Issue: Office add-in not loading

**Solution**:

```bash
# Clear Office cache
# macOS
rm -rf ~/Library/Containers/com.microsoft.Word/Data/Library/Caches/*

# Windows
%LOCALAPPDATA%\Microsoft\Office\16.0\Wef\

# Reinstall add-in
npm run install
```

#### Issue: Docker build fails

**Solution**:

```bash
# Clear Docker cache
docker system prune -a

# Rebuild from scratch
docker build --no-cache -t aws-ai-jail:dev .
```

#### Issue: Tests failing randomly

**Solution**:

```bash
# Run tests single-threaded
cargo test -- --test-threads=1

# Check for race conditions in code
```

---

## Additional Resources

### Documentation

- **Rust Book**: https://doc.rust-lang.org/book/
- **ReScript Docs**: https://rescript-lang.org/docs/
- **Office.js API**: https://learn.microsoft.com/en-us/office/dev/add-ins/
- **Docker Docs**: https://docs.docker.com/

### Community

- **Discord**: https://discord.gg/aws-dev
- **Forum**: https://discuss.aws-edu.org/c/development
- **GitHub Discussions**: https://github.com/academic-workflow-suite/aws/discussions

### Getting Help

- **Documentation**: Read the docs first
- **Search Issues**: Check existing GitHub issues
- **Ask Questions**: Discord #dev-help channel
- **Email**: dev@aws-edu.org

---

## Code of Conduct

All contributors must follow our [Code of Conduct](../CODE_OF_CONDUCT.md):

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- No harassment or discrimination

---

**Happy Coding!** 🚀

Thank you for contributing to Academic Workflow Suite. Your efforts help make TMA marking more efficient for tutors and improve feedback quality for students.

---

**Last Updated**: 2025-11-22
**Development Guide Version**: 1.0
