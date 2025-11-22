# Packaging Guide

Comprehensive guide for packaging the Academic Workflow Suite for different platforms.

## Table of Contents

- [Overview](#overview)
- [Platform-Specific Packaging](#platform-specific-packaging)
  - [Debian/Ubuntu (.deb)](#debianubuntu-deb)
  - [Fedora/RHEL (.rpm)](#fedorarhel-rpm)
  - [macOS (.pkg)](#macos-pkg)
  - [Windows (.msi)](#windows-msi)
- [Package Managers](#package-managers)
  - [Homebrew](#homebrew)
  - [Chocolatey](#chocolatey)
  - [Snap](#snap)
  - [Flatpak](#flatpak)
  - [AppImage](#appimage)
- [Package Signing](#package-signing)
- [Testing Packages](#testing-packages)

## Overview

The Academic Workflow Suite supports multiple packaging formats to ensure easy installation across all platforms.

### Package Types

| Format | Platform | Install Method | Update Method |
|--------|----------|---------------|---------------|
| .deb | Debian, Ubuntu | `dpkg -i` or `apt` | `apt upgrade` |
| .rpm | Fedora, RHEL, CentOS | `rpm -i` or `dnf` | `dnf upgrade` |
| .pkg | macOS | Installer GUI | Manual |
| .msi | Windows | Installer GUI | Manual |
| Homebrew | macOS, Linux | `brew install` | `brew upgrade` |
| Chocolatey | Windows | `choco install` | `choco upgrade` |
| Snap | Linux | `snap install` | `snap refresh` |
| Flatpak | Linux | `flatpak install` | `flatpak update` |
| AppImage | Linux | Execute directly | Manual |

## Platform-Specific Packaging

### Debian/Ubuntu (.deb)

#### Prerequisites

```bash
sudo apt-get install dpkg-dev build-essential
```

#### Directory Structure

```
package-root/
├── DEBIAN/
│   ├── control
│   ├── postinst
│   ├── prerm
│   └── postrm
├── usr/
│   ├── bin/
│   │   └── aws
│   └── share/
│       └── doc/
│           └── academic-workflow-suite/
│               ├── README.md
│               └── LICENSE
```

#### Building

```bash
cd release
./scripts/package.sh --deb
```

#### Manual Build

```bash
# Create package structure
mkdir -p pkg/DEBIAN
mkdir -p pkg/usr/bin
mkdir -p pkg/usr/share/doc/academic-workflow-suite

# Copy files
cp target/release/aws pkg/usr/bin/
cp README.md LICENSE pkg/usr/share/doc/academic-workflow-suite/

# Create control file
cat > pkg/DEBIAN/control << EOF
Package: academic-workflow-suite
Version: 1.0.0
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Your Name <email@example.com>
Depends: libc6 (>= 2.31)
Description: Academic workflow automation suite
EOF

# Build package
dpkg-deb --build pkg academic-workflow-suite_1.0.0_amd64.deb
```

#### Testing

```bash
# Check package contents
dpkg -c academic-workflow-suite_1.0.0_amd64.deb

# Check package info
dpkg -I academic-workflow-suite_1.0.0_amd64.deb

# Install locally
sudo dpkg -i academic-workflow-suite_1.0.0_amd64.deb

# Verify installation
aws --version
```

### Fedora/RHEL (.rpm)

#### Prerequisites

```bash
sudo dnf install rpm-build rpmdevtools
```

#### Setup RPM Build Environment

```bash
rpmdev-setuptree
```

Creates:
```
~/rpmbuild/
├── BUILD/
├── RPMS/
├── SOURCES/
├── SPECS/
└── SRPMS/
```

#### Building

```bash
cd release
./scripts/package.sh --rpm
```

#### Manual Build

```bash
# Create source tarball
tar czf ~/rpmbuild/SOURCES/academic-workflow-suite-1.0.0.tar.gz .

# Copy spec file
cp release/packaging/rpm/aws.spec ~/rpmbuild/SPECS/

# Build RPM
rpmbuild -ba ~/rpmbuild/SPECS/aws.spec

# Find built RPM
ls ~/rpmbuild/RPMS/x86_64/
```

#### Testing

```bash
# Check RPM contents
rpm -qlp ~/rpmbuild/RPMS/x86_64/academic-workflow-suite-1.0.0-1.x86_64.rpm

# Check RPM info
rpm -qip ~/rpmbuild/RPMS/x86_64/academic-workflow-suite-1.0.0-1.x86_64.rpm

# Install locally
sudo rpm -i ~/rpmbuild/RPMS/x86_64/academic-workflow-suite-1.0.0-1.x86_64.rpm

# Verify installation
aws --version
```

### macOS (.pkg)

#### Prerequisites

Xcode Command Line Tools (includes pkgbuild)

```bash
xcode-select --install
```

#### Building

```bash
cd release
./scripts/package.sh --macos
```

#### Manual Build

```bash
# Create directory structure
mkdir -p package-root/usr/local/bin
cp target/release/aws package-root/usr/local/bin/

# Create package
pkgbuild --root package-root \
         --identifier com.academicworkflow.suite \
         --version 1.0.0 \
         --install-location / \
         academic-workflow-suite-1.0.0.pkg
```

#### Testing

```bash
# Check package contents
pkgutil --payload-files academic-workflow-suite-1.0.0.pkg

# Install locally
sudo installer -pkg academic-workflow-suite-1.0.0.pkg -target /

# Verify installation
aws --version
```

### Windows (.msi)

#### Prerequisites

Install WiX Toolset: https://wixtoolset.org/

#### Building

```bash
cd release
./scripts/package.sh --windows
```

#### Manual Build (Windows)

```powershell
# Compile WiX file
candle.exe packaging\windows\installer.wxs

# Create MSI
light.exe installer.wixobj -out academic-workflow-suite-1.0.0.msi
```

#### Testing

```powershell
# Install silently
msiexec /i academic-workflow-suite-1.0.0.msi /quiet

# Verify installation
aws --version

# Uninstall
msiexec /x academic-workflow-suite-1.0.0.msi /quiet
```

## Package Managers

### Homebrew

#### Formula Location

```
homebrew-aws/
└── Formula/
    └── aws.rb
```

#### Update Formula

```bash
# Calculate SHA256
sha256sum academic-workflow-suite-1.0.0.tar.gz

# Update formula
cd homebrew-aws
vim Formula/aws.rb  # Update version and sha256

# Test formula
brew install --build-from-source Formula/aws.rb

# Audit formula
brew audit --strict Formula/aws.rb
```

#### Submit to Homebrew

```bash
# Fork homebrew-core
# Create branch
git checkout -b aws-1.0.0

# Add formula
cp Formula/aws.rb homebrew-core/Formula/

# Commit and push
git add Formula/aws.rb
git commit -m "aws 1.0.0 (new formula)"
git push origin aws-1.0.0

# Create pull request
```

### Chocolatey

#### Package Structure

```
chocolatey/
├── aws.nuspec
└── tools/
    └── chocolateyinstall.ps1
```

#### Building

```powershell
# Pack package
choco pack chocolatey\aws.nuspec

# Test locally
choco install academic-workflow-suite -s . -y

# Push to Chocolatey
choco push academic-workflow-suite.1.0.0.nupkg --api-key YOUR_API_KEY
```

### Snap

#### Building

```bash
cd release/snap
snapcraft

# Test locally
sudo snap install academic-workflow-suite_1.0.0_amd64.snap --dangerous

# Publish
snapcraft upload academic-workflow-suite_1.0.0_amd64.snap --release=stable
```

#### Multi-Architecture

```bash
# Build for multiple architectures
snapcraft remote-build
```

### Flatpak

#### Prerequisites

```bash
sudo apt-get install flatpak flatpak-builder
```

#### Building

```bash
cd release/flatpak

# Install required runtimes
flatpak install flathub org.freedesktop.Platform//23.08
flatpak install flathub org.freedesktop.Sdk//23.08

# Build
flatpak-builder --force-clean build-dir com.academicworkflow.AWS.yaml

# Test
flatpak-builder --run build-dir com.academicworkflow.AWS.yaml aws --version

# Export
flatpak build-export export build-dir

# Create single-file bundle
flatpak build-bundle export academic-workflow-suite.flatpak com.academicworkflow.AWS
```

### AppImage

#### Prerequisites

```bash
pip3 install appimage-builder
```

#### Building

```bash
cd release/appimage
appimage-builder --recipe AppImageBuilder.yml
```

#### Testing

```bash
chmod +x academic-workflow-suite-1.0.0-x86_64.AppImage
./academic-workflow-suite-1.0.0-x86_64.AppImage --version
```

## Package Signing

### GPG Signing

#### Setup GPG Key

```bash
# Generate key
gpg --full-generate-key

# List keys
gpg --list-secret-keys --keyid-format=long

# Export public key
gpg --armor --export YOUR_KEY_ID > public-key.asc
```

#### Sign Packages

```bash
# Sign .deb
dpkg-sig --sign builder academic-workflow-suite_1.0.0_amd64.deb

# Sign .rpm
rpmsign --addsign academic-workflow-suite-1.0.0-1.x86_64.rpm

# Sign tarball
gpg --detach-sign --armor academic-workflow-suite-1.0.0.tar.gz

# Sign checksums
gpg --detach-sign --armor SHA256SUMS
```

#### Verify Signatures

```bash
# Verify .deb
dpkg-sig --verify academic-workflow-suite_1.0.0_amd64.deb

# Verify .rpm
rpm --checksig academic-workflow-suite-1.0.0-1.x86_64.rpm

# Verify GPG signature
gpg --verify academic-workflow-suite-1.0.0.tar.gz.asc academic-workflow-suite-1.0.0.tar.gz
```

## Testing Packages

### Automated Testing

```bash
cd release/verify
./verify_release.sh 1.0.0
./test_install.sh
```

### Manual Testing

#### Docker Testing

```bash
# Test Debian package
docker run -it --rm -v $(pwd):/packages debian:bookworm bash
dpkg -i /packages/academic-workflow-suite_1.0.0_amd64.deb
aws --version

# Test RPM package
docker run -it --rm -v $(pwd):/packages fedora:latest bash
dnf install -y /packages/academic-workflow-suite-1.0.0-1.x86_64.rpm
aws --version

# Test Ubuntu
docker run -it --rm -v $(pwd):/packages ubuntu:22.04 bash
apt-get update && apt-get install -y /packages/academic-workflow-suite_1.0.0_amd64.deb
aws --version
```

### Virtual Machine Testing

Test on clean virtual machines:

- Windows 10/11
- macOS (latest)
- Ubuntu 22.04 LTS
- Fedora 39
- Arch Linux

### Verification Checklist

- [ ] Package installs without errors
- [ ] Binary is in PATH
- [ ] `aws --version` works
- [ ] `aws --help` displays help
- [ ] Dependencies are satisfied
- [ ] Package can be upgraded
- [ ] Package can be removed cleanly
- [ ] Post-install scripts run correctly
- [ ] No file conflicts
- [ ] Correct file permissions

## Best Practices

1. **Always test on clean systems**
2. **Verify checksums match**
3. **Sign all packages**
4. **Test upgrade path**
5. **Document dependencies clearly**
6. **Include uninstall instructions**
7. **Maintain backward compatibility**
8. **Test on supported platforms only**

## Troubleshooting

### Common Issues

**Package won't install**
- Check dependencies
- Verify architecture (amd64 vs arm64)
- Check package integrity

**Binary not in PATH**
- Verify install location
- Check post-install script
- Source shell profile

**Permission errors**
- Use sudo for system-wide install
- Check file permissions in package

**Dependency conflicts**
- Use package manager to resolve
- Check required versions
- Consider using static binary

## Resources

- [Debian Policy Manual](https://www.debian.org/doc/debian-policy/)
- [RPM Packaging Guide](https://rpm-packaging-guide.github.io/)
- [WiX Documentation](https://wixtoolset.org/documentation/)
- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Snapcraft Documentation](https://snapcraft.io/docs)
- [Flatpak Documentation](https://docs.flatpak.org/)
