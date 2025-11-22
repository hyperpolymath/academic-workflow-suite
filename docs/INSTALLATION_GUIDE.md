# Installation Guide

**Complete installation instructions for Academic Workflow Suite**

This guide provides comprehensive installation instructions for all platforms and configurations.

---

## Table of Contents

- [System Requirements](#system-requirements)
- [Pre-Installation Checklist](#pre-installation-checklist)
- [Installation Methods](#installation-methods)
- [Quick Installation](#quick-installation)
- [Manual Installation](#manual-installation)
- [Installation Modes](#installation-modes)
- [Platform-Specific Instructions](#platform-specific-instructions)
- [Configuration](#configuration)
- [Post-Installation](#post-installation)
- [Offline Installation](#offline-installation)
- [Troubleshooting](#troubleshooting)
- [Uninstallation](#uninstallation)
- [Advanced Topics](#advanced-topics)

---

## System Requirements

### Minimum Requirements

| Component | Requirement |
|-----------|-------------|
| **Operating System** | Windows 10+, macOS 11+, Ubuntu 20.04+ |
| **CPU** | x86_64 or ARM64 (Apple Silicon supported) |
| **RAM** | 4 GB |
| **Disk Space** | 2 GB free space |
| **Office** | Microsoft Word 2019+ or Office 365 |
| **Internet** | Required for initial installation |

### Recommended Requirements

| Component | Recommendation |
|-----------|----------------|
| **RAM** | 8 GB or more |
| **CPU** | 4+ cores |
| **Disk** | SSD for better performance |
| **Display** | 1920x1080 or higher |
| **Network** | Broadband (for faster updates) |

### Software Dependencies

The installer will automatically install these if not present:

| Dependency | Version | Purpose |
|------------|---------|---------|
| **Rust** | 1.70+ | Core engine runtime |
| **Node.js** | 18+ | Office add-in |
| **Docker** or **Podman** | Latest | AI jail isolation |
| **Git** | 2.0+ | Version control (optional) |

### Office Compatibility

| Office Version | Compatibility | Notes |
|----------------|---------------|-------|
| Office 365 | ✅ Full | Recommended |
| Office 2021 | ✅ Full | All features |
| Office 2019 | ✅ Full | All features |
| Office 2016 | ⚠️ Limited | Basic features only |
| Office Online | ❌ Not supported | Desktop only |

---

## Pre-Installation Checklist

Before installing AWS, ensure:

- [ ] You have **administrator/sudo access** on your machine
- [ ] Your **Office installation is activated and working**
- [ ] You have a **stable internet connection** (at least 5 Mbps)
- [ ] **Firewall** allows downloads from `aws-edu.org` and `github.com`
- [ ] **Antivirus** is temporarily disabled (some may block the installer)
- [ ] You have **at least 4 GB of free disk space**
- [ ] **No other Office add-ins** are conflicting (rare but possible)

### Compatibility Check

Run this command to check system compatibility:

```bash
curl -sSL https://install.aws-edu.org/check.sh | bash
```

Expected output:

```
┌─────────────────────────────────────────────────┐
│  AWS Compatibility Check                        │
├─────────────────────────────────────────────────┤
│  ✓ Operating System: macOS 14.1 (Sonoma)        │
│  ✓ CPU Architecture: ARM64 (Apple Silicon)      │
│  ✓ RAM: 16 GB                                   │
│  ✓ Disk Space: 128 GB free                      │
│  ✓ Microsoft Word: Office 365 (v16.78)          │
│  ✓ Internet: Connected (45 Mbps)                │
│  ⚠ Docker: Not installed (will be installed)    │
│                                                 │
│  Result: Your system is compatible!             │
│  Recommended mode: Full Installation            │
└─────────────────────────────────────────────────┘
```

---

## Installation Methods

AWS offers three installation methods:

### 1. Quick Install (Recommended)

**Best for**: Most users, standard setups

- One-line command
- Automatic dependency installation
- Interactive configuration
- Estimated time: 5-10 minutes

### 2. Manual Install

**Best for**: Advanced users, custom configurations

- Step-by-step control
- Custom installation paths
- Selective component installation
- Estimated time: 15-30 minutes

### 3. Offline Install

**Best for**: Air-gapped systems, restricted networks

- Download installer bundle
- Install without internet
- Includes all dependencies
- Estimated time: 10-15 minutes

---

## Quick Installation

### macOS

```bash
curl -sSL https://install.aws-edu.org/install.sh | bash
```

### Linux

```bash
curl -sSL https://install.aws-edu.org/install.sh | bash
```

### Windows

**PowerShell (as Administrator)**:

```powershell
iwr https://install.aws-edu.org/install.ps1 -useb | iex
```

### Interactive Prompts

The installer will guide you through several choices:

#### 1. Installation Mode

```
┌─────────────────────────────────────────────────┐
│  Select installation mode:                      │
│                                                 │
│  1) Full (Recommended)                          │
│     • All components including AI               │
│     • Local AI processing                       │
│     • Disk: ~2 GB                               │
│                                                 │
│  2) Lite                                        │
│     • Core features only                        │
│     • Optional cloud AI                         │
│     • Disk: ~500 MB                             │
│                                                 │
│  3) Offline                                     │
│     • No network after install                  │
│     • All dependencies included                 │
│     • Disk: ~3 GB                               │
│                                                 │
│  Your choice [1]: _                             │
└─────────────────────────────────────────────────┘
```

**Recommendation**: Choose **1 (Full)** for the best experience.

#### 2. Installation Location

```
┌─────────────────────────────────────────────────┐
│  Installation directory:                        │
│                                                 │
│  Default locations:                             │
│  • macOS/Linux: /usr/local/aws                  │
│  • Windows:     C:\Program Files\AWS            │
│                                                 │
│  Press Enter for default, or type custom path:  │
│  > _                                            │
└─────────────────────────────────────────────────┘
```

**Recommendation**: Use the default unless you have specific requirements.

#### 3. Data Directory

```
┌─────────────────────────────────────────────────┐
│  Data storage location:                         │
│                                                 │
│  This is where AWS stores:                      │
│  • Event database                               │
│  • Configuration files                          │
│  • Cached rubrics                               │
│  • Logs                                         │
│                                                 │
│  Default: ~/.aws                                │
│  Press Enter for default, or type custom path:  │
│  > _                                            │
└─────────────────────────────────────────────────┘
```

**Recommendation**: Use the default for easy backups.

#### 4. AI Model Selection

```
┌─────────────────────────────────────────────────┐
│  Select AI model (Full mode only):              │
│                                                 │
│  1) Standard (Recommended)                      │
│     • Good balance of speed/quality             │
│     • ~800 MB download                          │
│     • 4 GB RAM minimum                          │
│                                                 │
│  2) High Quality                                │
│     • Better analysis, slower                   │
│     • ~2 GB download                            │
│     • 8 GB RAM minimum                          │
│                                                 │
│  3) Fast                                        │
│     • Faster analysis, simpler feedback         │
│     • ~400 MB download                          │
│     • 4 GB RAM minimum                          │
│                                                 │
│  Your choice [1]: _                             │
└─────────────────────────────────────────────────┘
```

**Recommendation**: Choose **1 (Standard)** unless you have specific needs.

#### 5. Installation Progress

```
┌─────────────────────────────────────────────────┐
│  Installing Academic Workflow Suite v0.1.0      │
├─────────────────────────────────────────────────┤
│                                                 │
│  ✓ Checking system requirements                 │
│  ✓ Installing Rust toolchain                    │
│  ✓ Installing Node.js dependencies              │
│  ⟳ Downloading AI model (800 MB)                │
│    [████████████░░░░░░] 65% - 2m 15s remaining  │
│  ⋯ Installing Docker/Podman                     │
│  ⋯ Building AWS Core Engine                     │
│  ⋯ Installing Office add-in                     │
│  ⋯ Configuring services                         │
│                                                 │
└─────────────────────────────────────────────────┘
```

#### 6. Completion

```
┌─────────────────────────────────────────────────┐
│  ✓ Installation Complete!                       │
├─────────────────────────────────────────────────┤
│                                                 │
│  AWS Core Engine: v0.1.0                        │
│  Office Add-in:   v1.0.0                        │
│  AI Model:        standard-v1                   │
│                                                 │
│  Installation directory: /usr/local/aws         │
│  Data directory:        ~/.aws                  │
│  Logs:                  ~/.aws/logs             │
│                                                 │
│  Next steps:                                    │
│  1. Start AWS:   aws-core start                 │
│  2. Open Word and look for the AWS tab          │
│  3. See Quick Start: aws-core docs quickstart   │
│                                                 │
│  Need help? Visit https://aws-edu.org/docs      │
└─────────────────────────────────────────────────┘
```

---

## Manual Installation

For users who want more control over the installation process.

### Step 1: Install System Dependencies

#### macOS

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install rust node docker git
```

#### Linux (Ubuntu/Debian)

```bash
# Update package list
sudo apt update

# Install dependencies
sudo apt install -y curl build-essential git

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
```

#### Windows

1. Download and install:
   - [Rust](https://www.rust-lang.org/tools/install)
   - [Node.js](https://nodejs.org/)
   - [Docker Desktop](https://www.docker.com/products/docker-desktop)
   - [Git](https://git-scm.com/download/win)

2. Restart your computer after installation

### Step 2: Download AWS

```bash
# Create installation directory
sudo mkdir -p /usr/local/aws
cd /usr/local/aws

# Download AWS
sudo git clone https://github.com/academic-workflow-suite/aws.git .

# Or download release tarball
curl -L https://github.com/academic-workflow-suite/aws/archive/v0.1.0.tar.gz | tar xz
```

### Step 3: Build Core Engine

```bash
cd components/core

# Build in release mode
cargo build --release

# Install binary
sudo cp target/release/aws-core /usr/local/bin/

# Verify
aws-core --version
```

### Step 4: Install Office Add-in

```bash
cd ../office-addin

# Install npm dependencies
npm install

# Build add-in
npm run build

# Install to Office
npm run install
```

### Step 5: Set Up AI Jail

```bash
cd ../ai-jail

# Build container image
docker build -t aws-ai-jail:latest .

# Or use Podman
podman build -t aws-ai-jail:latest .

# Verify
docker images | grep aws-ai-jail
```

### Step 6: Download AI Model

```bash
# Create models directory
mkdir -p ~/.aws/models

# Download standard model
curl -L https://models.aws-edu.org/standard-v1.onnx \
  -o ~/.aws/models/standard-v1.onnx

# Verify checksum
echo "7f3a2b9c... ~/.aws/models/standard-v1.onnx" | sha256sum -c
```

### Step 7: Initialize Configuration

```bash
# Create config directory
mkdir -p ~/.aws

# Generate default configuration
aws-core init

# This creates:
# ~/.aws/config.toml
# ~/.aws/data/
# ~/.aws/logs/
```

### Step 8: Start Services

```bash
# Start core engine
aws-core start

# Check status
aws-core status

# View logs
aws-core logs
```

---

## Installation Modes

### Full Mode (Recommended)

**Includes**:
- AWS Core Engine
- Office Add-in
- AI Jail with local AI model
- All dependencies

**Disk Space**: ~2 GB

**Use when**:
- You want complete functionality
- Privacy is a priority (local AI)
- You have sufficient disk space

**Installation**:

```bash
curl -sSL https://install.aws-edu.org/install.sh | bash -s -- --mode full
```

### Lite Mode

**Includes**:
- AWS Core Engine
- Office Add-in
- Optional cloud AI connection

**Disk Space**: ~500 MB

**Use when**:
- Disk space is limited
- You don't mind cloud AI (still privacy-preserving)
- You want faster installation

**Installation**:

```bash
curl -sSL https://install.aws-edu.org/install.sh | bash -s -- --mode lite
```

**Note**: Lite mode still anonymizes student data before sending to cloud AI.

### Offline Mode

**Includes**:
- All components
- Pre-downloaded dependencies
- Bundled AI model

**Disk Space**: ~3 GB

**Use when**:
- Installing on air-gapped systems
- Internet access is unreliable
- Corporate firewall restrictions

**Installation**:

1. Download offline bundle on a machine with internet:

```bash
curl -LO https://install.aws-edu.org/aws-offline-v0.1.0.tar.gz
```

2. Transfer to target machine via USB/network

3. Extract and install:

```bash
tar xzf aws-offline-v0.1.0.tar.gz
cd aws-offline-v0.1.0
./install-offline.sh
```

---

## Platform-Specific Instructions

### macOS

#### Apple Silicon (M1/M2/M3)

AWS is fully compatible with Apple Silicon:

```bash
# Installation is the same
curl -sSL https://install.aws-edu.org/install.sh | bash

# AWS will automatically use ARM64 binaries
```

#### Intel Macs

```bash
# Standard installation
curl -sSL https://install.aws-edu.org/install.sh | bash
```

#### Common macOS Issues

**Issue**: "Cannot be opened because it is from an unidentified developer"

**Solution**:

```bash
# Remove quarantine attribute
sudo xattr -r -d com.apple.quarantine /usr/local/aws
```

**Issue**: Homebrew not in PATH

**Solution**:

```bash
# Add to ~/.zshrc or ~/.bash_profile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

### Linux

#### Ubuntu/Debian

```bash
# Quick install
curl -sSL https://install.aws-edu.org/install.sh | bash
```

#### Fedora/RHEL/CentOS

```bash
# Install with DNF/YUM package manager
curl -sSL https://install.aws-edu.org/install.sh | bash -s -- --package-manager dnf
```

#### Arch Linux

```bash
# AUR package available
yay -S academic-workflow-suite
```

#### Common Linux Issues

**Issue**: Docker permission denied

**Solution**:

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Logout and login again
```

**Issue**: systemd service won't start

**Solution**:

```bash
# Check logs
journalctl -u aws-core -n 50

# Restart service
sudo systemctl restart aws-core
```

### Windows

#### Windows 10/11

```powershell
# Run PowerShell as Administrator
iwr https://install.aws-edu.org/install.ps1 -useb | iex
```

#### WSL2 (Windows Subsystem for Linux)

AWS can run in WSL2:

```bash
# Inside WSL2 terminal
curl -sSL https://install.aws-edu.org/install.sh | bash

# Note: Word must be Windows version, not WSL
```

#### Common Windows Issues

**Issue**: Execution policy prevents installation

**Solution**:

```powershell
# As Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Issue**: Office add-in not appearing

**Solution**:

1. Close all Office applications
2. Run as Administrator:

```powershell
aws-addin install --force
```

3. Restart Word

**Issue**: Docker Desktop not running

**Solution**:

1. Start Docker Desktop from Start menu
2. Wait for "Docker Desktop is running" notification
3. Run `aws-core restart`

---

## Configuration

### Configuration File

After installation, edit `~/.aws/config.toml`:

```toml
[core]
# Data directory
data_dir = "~/.aws/data"

# Log level: trace, debug, info, warn, error
log_level = "info"

# Auto-update check
check_updates = true

[ai]
# AI mode: local, cloud, hybrid
mode = "local"

# Model selection
model = "standard-v1"

# AI jail timeout (seconds)
timeout = 30

# Max concurrent analyses
max_concurrent = 2

[office]
# Auto-insert feedback
auto_insert = false

# Export format preference
export_format = "pdf"

# Theme: light, dark, auto
theme = "auto"

[privacy]
# Anonymization algorithm
hash_algorithm = "sha3-512"

# Audit logging
audit_enabled = true

# Telemetry (anonymous usage stats)
telemetry_enabled = false

[network]
# Proxy settings (if needed)
# proxy = "http://proxy.example.com:8080"

# Update server
update_server = "https://updates.aws-edu.org"
```

### Editing Configuration

```bash
# Edit config file
aws-core config edit

# Show current config
aws-core config show

# Reset to defaults
aws-core config reset

# Validate configuration
aws-core config validate
```

---

## Post-Installation

### Verification Steps

After installation, verify everything works:

#### 1. Check Core Engine

```bash
aws-core --version
# Expected: AWS Core Engine v0.1.0

aws-core status
# Expected: All services running
```

#### 2. Check Office Add-in

```bash
aws-addin status
# Expected: Installed and enabled
```

1. Open Microsoft Word
2. Look for "AWS" tab in ribbon
3. Click "Open AWS Panel"

#### 3. Test AI Jail

```bash
aws-core test-ai
# Expected: AI jail responding, test analysis successful
```

#### 4. Run System Diagnostics

```bash
aws-core doctor
```

Expected output:

```
┌─────────────────────────────────────────────────┐
│  AWS System Diagnostics                         │
├─────────────────────────────────────────────────┤
│  ✓ Core Engine:       Running (v0.1.0)          │
│  ✓ AI Jail:          Ready                      │
│  ✓ Office Add-in:    Installed                  │
│  ✓ Database:         OK (0 events)              │
│  ✓ Configuration:    Valid                      │
│  ✓ Network:          Connected                  │
│  ✓ Disk Space:       128 GB free                │
│  ✓ Permissions:      OK                         │
│                                                 │
│  No issues detected!                            │
└─────────────────────────────────────────────────┘
```

### First Run Setup

```bash
# Download sample rubrics
aws-core update-rubrics

# Download sample TMA for testing
aws-core download-sample --module TM112 --assignment TMA01

# Open sample in Word
open ~/Downloads/TM112-TMA01-Sample.docx  # macOS
xdg-open ~/Downloads/TM112-TMA01-Sample.docx  # Linux
start ~/Downloads/TM112-TMA01-Sample.docx  # Windows
```

### Setting Up Auto-Start (Optional)

#### macOS (launchd)

```bash
# Create launchd plist
aws-core install-service

# Enable auto-start
launchctl load ~/Library/LaunchAgents/org.aws-edu.core.plist

# Start now
launchctl start org.aws-edu.core
```

#### Linux (systemd)

```bash
# Create systemd service
aws-core install-service

# Enable auto-start
sudo systemctl enable aws-core

# Start now
sudo systemctl start aws-core
```

#### Windows (Task Scheduler)

```powershell
# Create scheduled task (as Administrator)
aws-core install-service

# Verify
Get-ScheduledTask -TaskName "AWS Core Engine"
```

---

## Offline Installation

For air-gapped systems or restricted networks.

### Preparing Offline Bundle

On a machine **with internet access**:

```bash
# Download offline installer
curl -LO https://install.aws-edu.org/aws-offline-v0.1.0.tar.gz

# Verify checksum
echo "abc123... aws-offline-v0.1.0.tar.gz" | sha256sum -c

# Transfer to target machine via:
# - USB drive
# - Internal network share
# - Physical media
```

### Installing from Offline Bundle

On the **target machine** (without internet):

```bash
# Extract bundle
tar xzf aws-offline-v0.1.0.tar.gz
cd aws-offline-v0.1.0

# Run offline installer
./install-offline.sh
```

The offline bundle includes:

- AWS Core Engine binaries
- Office Add-in files
- AI Jail container image
- AI model (standard-v1)
- All dependencies (Rust, Node.js, Docker)
- Documentation

### Updating Offline Installation

```bash
# Download update bundle (on internet-connected machine)
curl -LO https://install.aws-edu.org/aws-update-v0.2.0.tar.gz

# Transfer to target machine

# Apply update
tar xzf aws-update-v0.2.0.tar.gz
cd aws-update-v0.2.0
./update-offline.sh
```

---

## Troubleshooting

### Installation Failures

#### Issue: "Permission denied" errors

**Solution**:

```bash
# macOS/Linux: Use sudo for system directories
curl -sSL https://install.aws-edu.org/install.sh | sudo bash

# Or install to user directory
curl -sSL https://install.aws-edu.org/install.sh | bash -s -- --prefix ~/.local
```

#### Issue: "Command not found: aws-core"

**Solution**:

```bash
# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Reload shell
source ~/.bashrc
```

#### Issue: Docker installation fails

**Solution**:

```bash
# macOS: Install Docker Desktop manually
open https://www.docker.com/products/docker-desktop

# Linux: Install via package manager
curl -fsSL https://get.docker.com | sudo sh

# Windows: Download Docker Desktop
# https://www.docker.com/products/docker-desktop
```

### Runtime Issues

#### Issue: "AI Jail not responding"

**Symptoms**: Analysis times out or fails

**Diagnosis**:

```bash
aws-core test-ai --verbose
```

**Solutions**:

1. Check Docker is running:

```bash
docker ps
# Should show aws-ai-jail container
```

2. Restart AI jail:

```bash
aws-core restart-ai
```

3. Rebuild AI jail:

```bash
cd components/ai-jail
docker build -t aws-ai-jail:latest .
aws-core restart
```

#### Issue: Office Add-in not loading

**Symptoms**: AWS tab not in Word ribbon

**Diagnosis**:

```bash
aws-addin status
```

**Solutions**:

1. Reinstall add-in:

```bash
aws-addin uninstall
aws-addin install
```

2. Check Office add-ins settings:
   - Word → File → Options → Add-ins
   - Ensure "Academic Workflow Suite" is enabled

3. Clear Office cache:

```bash
# macOS
rm -rf ~/Library/Containers/com.microsoft.Word/Data/Library/Caches/*

# Windows
%LOCALAPPDATA%\Microsoft\Office\16.0\Wef\
# Delete all files in Wef folder
```

#### Issue: Database corruption

**Symptoms**: "Failed to open database" errors

**Diagnosis**:

```bash
aws-core check-db
```

**Solutions**:

1. Backup data:

```bash
cp -r ~/.aws/data ~/.aws/data.backup
```

2. Repair database:

```bash
aws-core repair-db
```

3. If repair fails, restore from backup:

```bash
aws-core restore-backup --date 2025-11-21
```

### Performance Issues

#### Issue: Slow AI analysis

**Possible causes**:
- Low RAM (< 4 GB available)
- CPU throttling
- Large document (> 5000 words)
- First run (model loading)

**Solutions**:

1. Check system resources:

```bash
# macOS
top -l 1 | grep PhysMem

# Linux
free -h

# Windows
Get-Process | Sort-Object -Property WS -Descending | Select-Object -First 5
```

2. Use faster AI model:

```bash
aws-core config set ai.model fast-v1
aws-core restart
```

3. Limit concurrent analyses:

```bash
aws-core config set ai.max_concurrent 1
```

4. Analyze question-by-question instead of full document

### Network Issues

#### Issue: "Cannot connect to update server"

**Solution**:

```bash
# Configure proxy (if behind corporate firewall)
aws-core config set network.proxy "http://proxy.company.com:8080"

# Test connection
aws-core test-network

# Or disable auto-updates
aws-core config set core.check_updates false
```

#### Issue: Firewall blocking installation

**Solution**:

Allow these domains in your firewall:
- `aws-edu.org`
- `github.com`
- `models.aws-edu.org`
- `updates.aws-edu.org`

Or use offline installation method.

---

## Uninstallation

### Complete Uninstall

#### macOS/Linux

```bash
# Stop services
aws-core stop

# Uninstall (keeps user data)
sudo /usr/local/aws/uninstall.sh

# Remove user data (optional)
rm -rf ~/.aws
```

#### Windows

```powershell
# Stop services
aws-core stop

# Uninstall (via Control Panel)
# Or via PowerShell
& "C:\Program Files\AWS\uninstall.ps1"

# Remove user data (optional)
Remove-Item -Recurse -Force $env:USERPROFILE\.aws
```

### Selective Uninstall

Remove only specific components:

```bash
# Remove Office add-in only
aws-addin uninstall

# Remove AI jail only
docker rmi aws-ai-jail:latest

# Remove core engine only
sudo rm /usr/local/bin/aws-core
```

### Data Cleanup

```bash
# Remove all data (WARNING: irreversible!)
rm -rf ~/.aws

# Remove only cache and logs (keeps database)
rm -rf ~/.aws/cache ~/.aws/logs

# Export data before removal
aws-core export-data --output ~/aws-backup.tar.gz
```

---

## Advanced Topics

### Custom Installation Prefix

```bash
# Install to custom directory
curl -sSL https://install.aws-edu.org/install.sh | \
  bash -s -- --prefix /opt/aws
```

### Multi-User Installation

For shared workstations:

```bash
# Install system-wide (requires root)
sudo curl -sSL https://install.aws-edu.org/install.sh | \
  sudo bash -s -- --system-wide

# Each user will have their own data directory
# User A: /home/userA/.aws
# User B: /home/userB/.aws
```

### Container-Based Installation

Run AWS entirely in Docker:

```bash
# Pull image
docker pull awsedu/academic-workflow-suite:latest

# Run
docker run -d \
  -p 8080:8080 \
  -v ~/.aws:/data \
  awsedu/academic-workflow-suite:latest
```

### Building from Source

For developers or custom modifications:

```bash
# Clone repository
git clone https://github.com/academic-workflow-suite/aws.git
cd aws

# Install build dependencies
./scripts/install/install-build-deps.sh

# Build all components
./scripts/dev/build-all.sh

# Install
sudo ./scripts/install/install-from-build.sh
```

### Cross-Compilation

Build for a different platform:

```bash
# Build macOS binary on Linux
cargo build --release --target x86_64-apple-darwin

# Build Windows binary on Linux
cargo build --release --target x86_64-pc-windows-gnu

# Build ARM64 binary on x86_64
cargo build --release --target aarch64-unknown-linux-gnu
```

---

## Getting Help

### Documentation

- **Quick Start**: [QUICK_START.md](QUICK_START.md)
- **User Guide**: [USER_GUIDE.md](USER_GUIDE.md)
- **FAQ**: [USER_GUIDE.md#faq](USER_GUIDE.md#faq)

### Community Support

- **Forum**: https://discuss.aws-edu.org
- **Issue Tracker**: https://github.com/academic-workflow-suite/issues

### Professional Support

- **Email**: support@aws-edu.org
- **Enterprise**: enterprise@aws-edu.org

### Reporting Installation Issues

When reporting installation issues, include:

```bash
# Generate diagnostic report
aws-core diagnose --output ~/aws-diagnostic.txt

# Include in your issue report
```

The report includes:
- System information
- Installation logs
- Configuration (sanitized)
- Error messages
- No personal data

---

## Appendices

### Appendix A: Installation Directory Structure

```
/usr/local/aws/
├── bin/
│   ├── aws-core              # Core engine binary
│   └── aws-addin             # Add-in CLI tool
├── lib/
│   ├── libaws_core.so        # Core library
│   └── ai-jail/              # AI jail container files
├── share/
│   ├── office-addin/         # Office add-in files
│   ├── models/               # AI models
│   └── docs/                 # Documentation
├── etc/
│   └── config.default.toml   # Default configuration
└── uninstall.sh              # Uninstall script
```

### Appendix B: User Data Directory Structure

```
~/.aws/
├── config.toml               # User configuration
├── data/
│   └── events.lmdb           # Event store database
├── rubrics/
│   ├── TM112-TMA01.json
│   ├── M250-TMA02.json
│   └── custom/               # User-created rubrics
├── models/
│   └── standard-v1.onnx      # Downloaded AI model
├── cache/
│   └── analysis/             # Cached analysis results
└── logs/
    ├── core.log
    ├── ai-jail.log
    └── office-addin.log
```

### Appendix C: Port Requirements

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| Core Engine | 8080 | HTTP | REST API (localhost only) |
| Office Add-in | N/A | N/A | Connects to Core |
| AI Jail | Unix socket | N/A | IPC with Core |

All communication is **local only**—no external ports opened.

### Appendix D: Checksum Verification

Verify download integrity:

```bash
# Download checksums file
curl -L https://install.aws-edu.org/checksums.txt

# Verify
sha256sum -c checksums.txt
```

---

**Installation complete!** Continue to [QUICK_START.md](QUICK_START.md) to mark your first TMA.

**Last Updated**: 2025-11-22
**Guide Version**: 1.0
