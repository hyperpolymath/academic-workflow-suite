# Academic Workflow Suite - Windows Installation Script
# ======================================================
#
# This PowerShell script handles Windows-specific installation tasks including:
# - Windows version detection and compatibility check
# - WSL2 installation and configuration
# - Chocolatey package manager setup
# - Rust, Elixir, and Node.js installation
# - Office Add-in registration
# - Windows Service creation
# - Desktop shortcuts and Start Menu integration
#
# Usage: .\install-windows.ps1 [OPTIONS]
#
# Options:
#   -InstallWSL        Install WSL2 for Linux components
#   -SkipOfficeAddin   Skip Office Add-in registration
#   -NoServices        Don't create Windows services
#   -Help              Show this help message
#
# Requirements:
#   - Windows 10 version 2004+ or Windows 11
#   - PowerShell 5.1 or later
#   - Administrator privileges
#

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [switch]$InstallWSL,
    [switch]$SkipOfficeAddin,
    [switch]$NoServices,
    [switch]$Help
)

# Script configuration
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Script paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

# Installation paths
$InstallPath = "C:\Program Files\Academic Workflow Suite"
$DataPath = "$env:LOCALAPPDATA\AWS"
$ConfigPath = "$env:APPDATA\AWS"

# Logging
$LogFile = "$env:TEMP\aws-install.log"

# Color output functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
    Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [INFO] $Message"
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
    Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [SUCCESS] $Message"
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
    Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [WARN] $Message"
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [ERROR] $Message"
}

# Show help
function Show-Help {
    Get-Content $MyInvocation.ScriptName | Select-String -Pattern "^#" | ForEach-Object {
        $_.Line.TrimStart("#").TrimStart()
    }
}

if ($Help) {
    Show-Help
    exit 0
}

# Check Windows version
function Test-WindowsVersion {
    Write-Info "Checking Windows version..."

    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $version = [System.Version]$os.Version
    $build = $os.BuildNumber

    Write-Info "Windows version: $($os.Caption) (Build $build)"

    # Windows 10 2004 (build 19041) or later required
    if ($build -lt 19041) {
        Write-Error-Custom "Windows 10 version 2004 (build 19041) or later is required"
        Write-Error-Custom "Current build: $build"
        return $false
    }

    Write-Success "Windows version is compatible"
    return $true
}

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Install Chocolatey package manager
function Install-Chocolatey {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Info "Chocolatey already installed: $(choco --version)"
        return
    }

    Write-Info "Installing Chocolatey package manager..."

    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

    try {
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Success "Chocolatey installed successfully"
    }
    catch {
        Write-Error-Custom "Failed to install Chocolatey: $_"
        throw
    }

    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# Install WSL2
function Install-WSL2 {
    if (-not $InstallWSL) {
        Write-Info "Skipping WSL2 installation (use -InstallWSL to enable)"
        return
    }

    Write-Info "Checking WSL2 status..."

    # Check if WSL is already installed
    $wsl = Get-Command wsl -ErrorAction SilentlyContinue
    if ($wsl) {
        $wslVersion = wsl --status 2>&1 | Select-String -Pattern "Default Version: (\d+)"
        if ($wslVersion) {
            Write-Info "WSL already installed (version $($wslVersion.Matches.Groups[1].Value))"
            return
        }
    }

    Write-Info "Installing WSL2..."

    # Enable WSL feature
    Write-Info "Enabling Windows Subsystem for Linux feature..."
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

    # Enable Virtual Machine Platform
    Write-Info "Enabling Virtual Machine Platform feature..."
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

    # Download and install WSL2 kernel update
    Write-Info "Downloading WSL2 kernel update..."
    $wslUpdateUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
    $wslUpdatePath = "$env:TEMP\wsl_update_x64.msi"

    Invoke-WebRequest -Uri $wslUpdateUrl -OutFile $wslUpdatePath
    Start-Process msiexec.exe -ArgumentList "/i", $wslUpdatePath, "/quiet" -Wait

    # Set WSL2 as default
    wsl --set-default-version 2

    # Install Ubuntu distribution
    Write-Info "Installing Ubuntu for WSL..."
    wsl --install -d Ubuntu

    Write-Success "WSL2 installation complete"
    Write-Warning "A system restart may be required for WSL2 to function properly"
}

# Install Rust
function Install-Rust {
    if (Get-Command rustc -ErrorAction SilentlyContinue) {
        $rustVersion = rustc --version
        Write-Info "Rust already installed: $rustVersion"
        return
    }

    Write-Info "Installing Rust..."

    # Download rustup-init.exe
    $rustupUrl = "https://win.rustup.rs/x86_64"
    $rustupPath = "$env:TEMP\rustup-init.exe"

    Write-Info "Downloading rustup..."
    Invoke-WebRequest -Uri $rustupUrl -OutFile $rustupPath

    # Run rustup installer
    Write-Info "Running Rust installer..."
    Start-Process -FilePath $rustupPath -ArgumentList "-y" -Wait -NoNewWindow

    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    Write-Success "Rust installed: $(rustc --version)"
}

# Install Elixir
function Install-Elixir {
    if (Get-Command elixir -ErrorAction SilentlyContinue) {
        $elixirVersion = elixir --version | Select-String "Elixir"
        Write-Info "Elixir already installed: $elixirVersion"
        return
    }

    Write-Info "Installing Erlang and Elixir via Chocolatey..."

    choco install erlang -y
    choco install elixir -y

    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    Write-Success "Elixir installed: $(elixir --version | Select-String 'Elixir')"
}

# Install Node.js
function Install-NodeJS {
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $nodeVersion = node --version
        Write-Info "Node.js already installed: $nodeVersion"
        return
    }

    Write-Info "Installing Node.js via Chocolatey..."

    choco install nodejs-lts -y

    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    Write-Success "Node.js installed: $(node --version)"
}

# Install Git
function Install-Git {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitVersion = git --version
        Write-Info "Git already installed: $gitVersion"
        return
    }

    Write-Info "Installing Git via Chocolatey..."

    choco install git -y

    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    Write-Success "Git installed: $(git --version)"
}

# Install Visual C++ Build Tools
function Install-VCBuildTools {
    Write-Info "Checking for Visual C++ Build Tools..."

    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vsWhere) {
        $buildTools = & $vsWhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if ($buildTools) {
            Write-Info "Visual C++ Build Tools already installed"
            return
        }
    }

    Write-Info "Installing Visual C++ Build Tools..."
    Write-Warning "This may take several minutes..."

    choco install visualstudio2022buildtools -y
    choco install visualstudio2022-workload-vctools -y

    Write-Success "Visual C++ Build Tools installed"
}

# Install Docker Desktop (alternative to Podman on Windows)
function Install-DockerDesktop {
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        $dockerVersion = docker --version
        Write-Info "Docker already installed: $dockerVersion"
        return
    }

    Write-Info "Installing Docker Desktop..."
    Write-Warning "Docker Desktop requires WSL2 to be installed"

    choco install docker-desktop -y

    Write-Success "Docker Desktop installed"
    Write-Warning "Please start Docker Desktop manually after installation"
}

# Create installation directories
function New-InstallDirectories {
    Write-Info "Creating installation directories..."

    $directories = @(
        $InstallPath,
        "$InstallPath\bin",
        "$InstallPath\lib",
        "$InstallPath\share",
        "$DataPath",
        "$DataPath\data",
        "$DataPath\logs",
        "$DataPath\models",
        "$DataPath\backups",
        "$ConfigPath"
    )

    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Info "Created: $dir"
        }
    }

    Write-Success "Directories created"
}

# Register Office Add-in
function Register-OfficeAddin {
    if ($SkipOfficeAddin) {
        Write-Info "Skipping Office Add-in registration"
        return
    }

    Write-Info "Registering Office Add-in..."

    $manifestPath = Join-Path $InstallPath "office-addin\manifest.xml"

    if (-not (Test-Path $manifestPath)) {
        Write-Warning "Office Add-in manifest not found: $manifestPath"
        return
    }

    # Copy manifest to Office Add-ins directory
    $officeAddinsPath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Office\AddIns"
    New-Item -ItemType Directory -Path $officeAddinsPath -Force | Out-Null

    Copy-Item -Path $manifestPath -Destination $officeAddinsPath -Force

    Write-Success "Office Add-in registered"
    Write-Info "The add-in will appear in Word/Excel after restarting Office applications"
}

# Create Windows Services
function New-WindowsServices {
    if ($NoServices) {
        Write-Info "Skipping Windows service creation"
        return
    }

    Write-Info "Creating Windows services..."

    # Create AWS Core service
    $coreExe = Join-Path $InstallPath "bin\aws-core.exe"
    $coreSvc = Get-Service -Name "AWSCore" -ErrorAction SilentlyContinue

    if ($coreSvc) {
        Write-Info "AWS Core service already exists"
    }
    elseif (Test-Path $coreExe) {
        New-Service -Name "AWSCore" `
            -BinaryPathName $coreExe `
            -DisplayName "Academic Workflow Suite - Core" `
            -Description "Core engine for Academic Workflow Suite" `
            -StartupType Automatic

        Write-Success "AWS Core service created"
    }

    # Create AWS Backend service
    $backendExe = Join-Path $InstallPath "bin\aws-backend.exe"
    $backendSvc = Get-Service -Name "AWSBackend" -ErrorAction SilentlyContinue

    if ($backendSvc) {
        Write-Info "AWS Backend service already exists"
    }
    elseif (Test-Path $backendExe) {
        New-Service -Name "AWSBackend" `
            -BinaryPathName $backendExe `
            -DisplayName "Academic Workflow Suite - Backend" `
            -Description "Backend API for Academic Workflow Suite" `
            -StartupType Automatic `
            -DependsOn "AWSCore"

        Write-Success "AWS Backend service created"
    }
}

# Create desktop shortcuts
function New-DesktopShortcuts {
    Write-Info "Creating desktop shortcuts..."

    $WshShell = New-Object -ComObject WScript.Shell

    # Desktop shortcut
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcut = $WshShell.CreateShortcut("$desktopPath\Academic Workflow Suite.lnk")
    $shortcut.TargetPath = Join-Path $InstallPath "bin\aws-gui.exe"
    $shortcut.WorkingDirectory = $InstallPath
    $shortcut.IconLocation = Join-Path $InstallPath "share\icons\aws.ico"
    $shortcut.Description = "Academic Workflow Suite"
    $shortcut.Save()

    # Start Menu shortcut
    $startMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
    $shortcut = $WshShell.CreateShortcut("$startMenuPath\Academic Workflow Suite.lnk")
    $shortcut.TargetPath = Join-Path $InstallPath "bin\aws-gui.exe"
    $shortcut.WorkingDirectory = $InstallPath
    $shortcut.IconLocation = Join-Path $InstallPath "share\icons\aws.ico"
    $shortcut.Description = "Academic Workflow Suite"
    $shortcut.Save()

    Write-Success "Desktop shortcuts created"
}

# Add to PATH
function Add-ToPath {
    Write-Info "Adding AWS to system PATH..."

    $binPath = Join-Path $InstallPath "bin"
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")

    if ($currentPath -notlike "*$binPath*") {
        $newPath = "$currentPath;$binPath"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
        Write-Success "Added to PATH: $binPath"
    }
    else {
        Write-Info "Already in PATH: $binPath"
    }
}

# Configure firewall rules
function Set-FirewallRules {
    Write-Info "Configuring Windows Firewall rules..."

    # Allow backend API through firewall
    $ruleName = "Academic Workflow Suite - Backend API"
    $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

    if (-not $existingRule) {
        New-NetFirewallRule -DisplayName $ruleName `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort 8080 `
            -Action Allow `
            -Profile Private,Public

        Write-Success "Firewall rule created"
    }
    else {
        Write-Info "Firewall rule already exists"
    }
}

# Download and extract pre-built binaries (if available)
function Get-PrebuiltBinaries {
    Write-Info "Checking for pre-built binaries..."

    $releaseUrl = "https://github.com/academic-workflow-suite/aws/releases/latest"

    try {
        $response = Invoke-WebRequest -Uri $releaseUrl -UseBasicParsing -ErrorAction Stop
        Write-Info "Found release, downloading binaries..."

        # Parse download URL from release page
        # This would need to be implemented based on actual release structure

        Write-Warning "Pre-built binary download not yet implemented"
    }
    catch {
        Write-Info "No pre-built binaries available, will build from source"
    }
}

# Configure environment variables
function Set-EnvironmentVariables {
    Write-Info "Setting environment variables..."

    [Environment]::SetEnvironmentVariable("AWS_HOME", $InstallPath, "Machine")
    [Environment]::SetEnvironmentVariable("AWS_CONFIG_DIR", $ConfigPath, "User")
    [Environment]::SetEnvironmentVariable("AWS_DATA_DIR", $DataPath, "User")

    Write-Success "Environment variables configured"
}

# Create uninstaller
function New-Uninstaller {
    Write-Info "Creating uninstaller..."

    $uninstallScript = @"
# Academic Workflow Suite Uninstaller

Write-Host "Uninstalling Academic Workflow Suite..." -ForegroundColor Cyan

# Stop services
Stop-Service -Name "AWSCore" -ErrorAction SilentlyContinue
Stop-Service -Name "AWSBackend" -ErrorAction SilentlyContinue

# Remove services
sc.exe delete "AWSCore"
sc.exe delete "AWSBackend"

# Remove from PATH
`$binPath = "$InstallPath\bin"
`$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
`$newPath = `$currentPath -replace [regex]::Escape(";`$binPath"), ""
[Environment]::SetEnvironmentVariable("Path", `$newPath, "Machine")

# Remove environment variables
[Environment]::SetEnvironmentVariable("AWS_HOME", `$null, "Machine")
[Environment]::SetEnvironmentVariable("AWS_CONFIG_DIR", `$null, "User")
[Environment]::SetEnvironmentVariable("AWS_DATA_DIR", `$null, "User")

# Remove firewall rule
Remove-NetFirewallRule -DisplayName "Academic Workflow Suite - Backend API" -ErrorAction SilentlyContinue

# Remove shortcuts
Remove-Item -Path "`$env:USERPROFILE\Desktop\Academic Workflow Suite.lnk" -ErrorAction SilentlyContinue
Remove-Item -Path "`$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Academic Workflow Suite.lnk" -ErrorAction SilentlyContinue

# Remove installation directory (ask for confirmation)
`$response = Read-Host "Remove all data? This will delete $DataPath (y/N)"
if (`$response -eq 'y') {
    Remove-Item -Path "$DataPath" -Recurse -Force -ErrorAction SilentlyContinue
}

Remove-Item -Path "$InstallPath" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Uninstallation complete!" -ForegroundColor Green
"@

    $uninstallScript | Out-File -FilePath "$InstallPath\uninstall.ps1" -Encoding UTF8

    Write-Success "Uninstaller created: $InstallPath\uninstall.ps1"
}

# Main installation flow
function Start-Installation {
    Write-Info ""
    Write-Info "Academic Workflow Suite - Windows Installation"
    Write-Info "==============================================="
    Write-Info ""

    # Verify prerequisites
    if (-not (Test-Administrator)) {
        Write-Error-Custom "This script must be run as Administrator"
        exit 1
    }

    if (-not (Test-WindowsVersion)) {
        exit 1
    }

    # Install package managers and tools
    Install-Chocolatey
    Install-Git

    # Install development tools
    Install-VCBuildTools
    Install-Rust
    Install-Elixir
    Install-NodeJS

    # Install container runtime (optional)
    $installDocker = Read-Host "Install Docker Desktop? (y/N)"
    if ($installDocker -eq 'y') {
        Install-DockerDesktop
    }

    # Install WSL2 if requested
    Install-WSL2

    # Create directories
    New-InstallDirectories

    # Configure environment
    Set-EnvironmentVariables
    Add-ToPath

    # Setup services
    New-WindowsServices

    # Register Office add-in
    Register-OfficeAddin

    # Create shortcuts
    New-DesktopShortcuts

    # Configure firewall
    Set-FirewallRules

    # Create uninstaller
    New-Uninstaller

    Write-Info ""
    Write-Success "Windows installation complete!"
    Write-Info ""
    Write-Info "Next steps:"
    Write-Info "1. Restart your terminal/PowerShell session"
    Write-Info "2. Run the main installer to build components"
    Write-Info "3. Start services: Start-Service AWSCore, AWSBackend"
    Write-Info ""
    Write-Info "Log file: $LogFile"
}

# Run main installation
try {
    Start-Installation
}
catch {
    Write-Error-Custom "Installation failed: $_"
    Write-Error-Custom "See log file: $LogFile"
    exit 1
}
