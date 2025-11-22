# Academic Workflow Suite - Installation Guide

This directory contains the complete installation system for the Academic Workflow Suite (AWS). The installer supports multiple platforms, installation modes, and provides comprehensive dependency management.

## Table of Contents

- [Quick Start](#quick-start)
- [Installation Modes](#installation-modes)
- [Platform-Specific Installation](#platform-specific-installation)
- [System Requirements](#system-requirements)
- [Installation Options](#installation-options)
- [Post-Installation](#post-installation)
- [Troubleshooting](#troubleshooting)
- [Uninstallation](#uninstallation)
- [Advanced Configuration](#advanced-configuration)

## Quick Start

### Linux/WSL

The fastest way to get started:

```bash
# Clone the repository
git clone https://github.com/academic-workflow-suite/aws.git
cd aws/scripts/install

# Make the installer executable
chmod +x install.sh

# Run the interactive installer
./install.sh
```

### Windows

```powershell
# Open PowerShell as Administrator
cd aws\scripts\install

# Run the Windows installer
.\install-windows.ps1

# Then run the main installer
.\install.sh
```

## Installation Modes

The installer offers three installation modes to suit different needs:

### 1. Quick Install (~5 minutes)

**What's included:**
- Core Engine (Rust-based marking automation)
- Backend API Server (Elixir)
- Office Add-in (Word/Excel integration)
- AI Jail with Mistral 7B model

**Disk space:** ~5 GB
**Memory:** 4 GB minimum

**Usage:**
```bash
./install.sh --mode quick
```

### 2. Custom Install

**What you can choose:**
- Select individual components
- Choose AI models (Mistral 7B, Llama2 13B)
- Enable/disable development tools

**Disk space:** 5-15 GB (depending on selection)
**Memory:** 8 GB recommended

**Usage:**
```bash
./install.sh --mode custom
```

The installer will present an interactive menu to select components.

### 3. Full Install

**What's included:**
- All components
- Multiple AI models (Mistral 7B + Llama2 13B)
- Development tools (cargo-watch, nextest, etc.)
- Full documentation

**Disk space:** ~20 GB
**Memory:** 16 GB recommended

**Usage:**
```bash
./install.sh --mode full
```

## Platform-Specific Installation

### Linux

#### Ubuntu/Debian

```bash
# Update package lists
sudo apt update

# Install prerequisites
sudo apt install -y curl wget git build-essential

# Run installer
cd scripts/install
./install.sh
```

The installer will automatically:
- Detect your Ubuntu/Debian version
- Install required dependencies via apt
- Configure systemd services
- Set up desktop integration

#### Fedora/RHEL/CentOS

```bash
# Install prerequisites
sudo dnf install -y curl wget git gcc make

# Run installer
cd scripts/install
./install.sh
```

#### Arch Linux

```bash
# Install prerequisites
sudo pacman -Sy curl wget git base-devel

# Run installer
cd scripts/install
./install.sh
```

### Windows

#### Prerequisites
- Windows 10 version 2004+ or Windows 11
- PowerShell 5.1 or later
- Administrator privileges

#### Step-by-Step

1. **Install Windows dependencies:**
   ```powershell
   cd scripts\install
   .\install-windows.ps1
   ```

   This will install:
   - Chocolatey package manager
   - Rust toolchain
   - Elixir/Erlang
   - Node.js
   - Visual C++ Build Tools
   - Optionally: WSL2, Docker Desktop

2. **Install Office Add-in:**
   ```powershell
   .\install-windows.ps1 -SkipWSL
   ```

3. **Run main installer:**
   ```bash
   # In WSL or Git Bash
   ./install.sh
   ```

### WSL (Windows Subsystem for Linux)

AWS works great with WSL2:

```powershell
# Enable WSL2
.\install-windows.ps1 -InstallWSL

# Restart if needed, then in WSL:
cd /mnt/c/Users/YourName/aws/scripts/install
./install.sh
```

## System Requirements

### Minimum Requirements (Quick Install)

| Component | Requirement |
|-----------|-------------|
| OS | Ubuntu 20.04+, Fedora 35+, Windows 10 2004+, WSL2 |
| CPU | 2 cores, x86_64 |
| RAM | 4 GB |
| Disk | 5 GB free space |
| Network | Broadband (for downloads) |

### Recommended Requirements (Full Install)

| Component | Requirement |
|-----------|-------------|
| OS | Ubuntu 22.04+, Fedora 38+, Windows 11 |
| CPU | 4+ cores, x86_64 |
| RAM | 16 GB |
| Disk | 20 GB free space (SSD recommended) |
| Network | Broadband (for model downloads) |
| GPU | Optional: NVIDIA GPU with CUDA 12+ for AI acceleration |

### Software Dependencies

The installer will check for and install these automatically:

**Core Dependencies:**
- Rust 1.75.0+ (via rustup)
- Git 2.30.0+
- GCC/Clang 9.0+
- OpenSSL 1.1.1+

**Component-Specific:**
- Elixir 1.15.0+ & Erlang 26+ (Backend)
- Node.js 18+ & npm 9+ (Office Add-in)
- Podman 4.6+ or Docker 24+ (AI Jail)
- Python 3.10+ (AI models)

## Installation Options

### Command-Line Options

```bash
./install.sh [OPTIONS]

Options:
  --mode MODE           Installation mode: quick, custom, or full
  --no-interactive      Run without interactive prompts
  --offline             Use cached downloads only (no network)
  --skip-deps           Skip dependency installation
  --skip-build          Skip building components (use pre-built)
  --skip-services       Skip service configuration
  --prefix PATH         Installation prefix (default: /opt/academic-workflow-suite)
  --help                Show help message
```

### Examples

**Non-interactive quick install:**
```bash
./install.sh --mode quick --no-interactive
```

**Custom install to home directory:**
```bash
./install.sh --mode custom --prefix ~/aws
```

**Offline installation (using cached files):**
```bash
./install.sh --offline
```

**Install without systemd services:**
```bash
./install.sh --skip-services
```

## Post-Installation

### 1. Verify Installation

```bash
# Check installed version
aws-core --version

# Check component status
systemctl --user status aws-core
systemctl --user status aws-backend
```

### 2. Start Services

**Linux/WSL:**
```bash
# Enable services to start on boot
systemctl --user enable aws-core aws-backend

# Start services now
systemctl --user start aws-core aws-backend

# Check logs
journalctl --user -u aws-core -f
```

**Windows:**
```powershell
# Start services
Start-Service AWSCore
Start-Service AWSBackend

# Check status
Get-Service AWS*
```

### 3. Configure

Edit the configuration file:

```bash
# Linux/WSL
nano ~/.config/aws/config.yaml

# Windows
notepad %APPDATA%\AWS\config.yaml
```

See [config-template.yaml](config-template.yaml) for all available options.

### 4. Test Office Add-in

1. Open Microsoft Word
2. Go to **Insert** → **My Add-ins**
3. Select **Academic Workflow Suite**
4. The add-in should load in the sidebar

### 5. Test AI Jail (if installed)

```bash
# Test AI model
aws-ai-jail --model mistral-7b --prompt "Hello, how are you?"

# Check model status
aws-ai-jail --list-models
```

## Troubleshooting

### Installation Fails with "Permission Denied"

**Issue:** Installer cannot write to `/opt`

**Solution:**
```bash
# Use home directory instead
./install.sh --prefix ~/aws
```

### Dependency Installation Fails

**Issue:** Package manager cannot find packages

**Solution:**
```bash
# Update package lists first
sudo apt update  # Ubuntu/Debian
sudo dnf update  # Fedora

# Then run installer
./install.sh
```

### Build Fails: "Cannot find OpenSSL"

**Issue:** OpenSSL development headers not installed

**Solution:**
```bash
# Ubuntu/Debian
sudo apt install libssl-dev

# Fedora
sudo dnf install openssl-devel

# Arch
sudo pacman -S openssl
```

### AI Model Download is Slow/Fails

**Issue:** Large model files (15-30 GB) timing out

**Solution:**
```bash
# Download manually with resume support
cd ~/.local/share/aws/models/mistral-7b
wget -c https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf -O model.gguf

# Then re-run installer
./install.sh --skip-build
```

### Office Add-in Not Appearing

**Windows:**
1. Check manifest is registered:
   ```
   %USERPROFILE%\AppData\Roaming\Microsoft\Office\AddIns\
   ```

2. Restart Office applications

3. Clear Office cache:
   ```
   %LOCALAPPDATA%\Microsoft\Office\16.0\Wef\
   ```

**macOS:**
- Office Add-ins for macOS not yet supported

### Services Not Starting

**Check logs:**
```bash
# Linux/WSL
journalctl --user -u aws-core -n 50

# Check service status
systemctl --user status aws-core --no-pager
```

**Common issues:**
- Port 8080 already in use (change in config.yaml)
- Database permissions (check ~/.local/share/aws/data)
- Missing dependencies (re-run installer)

### WSL-Specific Issues

**WSL1 vs WSL2:**
AWS requires WSL2 for container support.

**Check WSL version:**
```powershell
wsl --list --verbose
```

**Upgrade to WSL2:**
```powershell
wsl --set-version Ubuntu 2
```

## Uninstallation

### Linux/WSL

```bash
# Stop services
systemctl --user stop aws-core aws-backend
systemctl --user disable aws-core aws-backend

# Remove installation
sudo rm -rf /opt/academic-workflow-suite

# Remove user data (optional)
rm -rf ~/.config/aws
rm -rf ~/.local/share/aws
rm -rf ~/.cache/aws

# Remove environment variables from ~/.bashrc
# (Edit manually or use sed)
sed -i '/# Academic Workflow Suite/,+5d' ~/.bashrc
```

### Windows

```powershell
# Run the uninstaller
cd "C:\Program Files\Academic Workflow Suite"
.\uninstall.ps1
```

Or manually:
```powershell
# Stop and remove services
Stop-Service AWSCore, AWSBackend
sc.exe delete AWSCore
sc.exe delete AWSBackend

# Remove installation
Remove-Item "C:\Program Files\Academic Workflow Suite" -Recurse -Force

# Remove user data
Remove-Item "$env:APPDATA\AWS" -Recurse -Force
Remove-Item "$env:LOCALAPPDATA\AWS" -Recurse -Force
```

## Advanced Configuration

### Custom Build Options

Build individual components with custom options:

```bash
# Build core with specific features
cd components/core
cargo build --release --features "gpu-acceleration"

# Build backend for production
cd components/backend
MIX_ENV=prod mix release
```

### Environment Variables

Set these before installation to customize behavior:

```bash
# Custom installation paths
export INSTALL_PREFIX=/usr/local/aws
export DATA_DIR=/var/lib/aws
export CONFIG_DIR=/etc/aws

# Build options
export RUSTFLAGS="-C target-cpu=native"
export CARGO_BUILD_JOBS=8

# Run installer
./install.sh
```

### Offline Installation

1. **Prepare offline cache:**
   ```bash
   # On a machine with internet
   ./install.sh --mode full

   # Package cache
   tar czf aws-cache.tar.gz ~/.cache/aws
   ```

2. **Transfer to offline machine:**
   ```bash
   # Extract cache
   tar xzf aws-cache.tar.gz -C ~/

   # Install offline
   ./install.sh --offline
   ```

### Container Runtime Selection

Prefer Podman over Docker for better security:

```bash
# Install Podman
sudo apt install podman  # Ubuntu
sudo dnf install podman  # Fedora

# Configure AWS to use Podman
cat >> ~/.config/aws/config.yaml << EOF
ai:
  runtime:
    container_runtime: "podman"
EOF
```

### Multi-User Installation

For shared systems:

```bash
# Install to system directory
sudo ./install.sh --prefix /opt/aws

# Allow users to access
sudo chmod -R 755 /opt/aws

# Each user configures their own data
mkdir -p ~/.local/share/aws
mkdir -p ~/.config/aws
cp /opt/aws/etc/config-template.yaml ~/.config/aws/config.yaml
```

## File Structure

```
scripts/install/
├── README.md                    # This file
├── install.sh                   # Main installer (Linux/WSL)
├── install-windows.ps1          # Windows-specific installer
├── install-linux.sh             # Linux dependency installer
├── dependencies.txt             # Version requirements
├── config-template.yaml         # Default configuration template
└── install.log                  # Installation log (created during install)
```

## Installation Paths

### Linux/WSL

| Type | Path |
|------|------|
| Binaries | `/opt/academic-workflow-suite/bin` |
| Libraries | `/opt/academic-workflow-suite/lib` |
| Config | `~/.config/aws/config.yaml` |
| Data | `~/.local/share/aws/data` |
| Logs | `~/.local/share/aws/logs` |
| Models | `~/.local/share/aws/models` |
| Cache | `~/.cache/aws` |

### Windows

| Type | Path |
|------|------|
| Program | `C:\Program Files\Academic Workflow Suite` |
| Config | `%APPDATA%\AWS\config.yaml` |
| Data | `%LOCALAPPDATA%\AWS\data` |
| Logs | `%LOCALAPPDATA%\AWS\logs` |
| Models | `%LOCALAPPDATA%\AWS\models` |

## Getting Help

- **Documentation:** See `docs/` directory
- **Issues:** https://github.com/academic-workflow-suite/aws/issues
- **Discussions:** https://github.com/academic-workflow-suite/aws/discussions
- **Log File:** Check `install.log` for detailed error messages

## Security Considerations

1. **Verify downloads:**
   - The installer downloads from trusted sources (HuggingFace, official repositories)
   - Check checksums in `dependencies.txt`

2. **Permissions:**
   - User installation (default) runs with user privileges
   - System installation requires sudo only when necessary

3. **Sandboxing:**
   - AI Jail runs models in isolated containers (Podman/Docker)
   - Network isolation enabled by default

4. **Updates:**
   - Check for updates: `aws-core --check-update`
   - Enable auto-updates in config.yaml (disabled by default)

## License

The Academic Workflow Suite is licensed under the MIT License. See the [LICENSE](../../LICENSE) file for details.

---

**Last Updated:** 2025-11-22
**Version:** 0.1.0
**Maintainer:** Academic Workflow Suite Team
