# Release Automation

Comprehensive release automation and packaging infrastructure for the Academic Workflow Suite.

## Overview

This directory contains all the tools, scripts, and configurations needed to create, package, and distribute releases of the Academic Workflow Suite across multiple platforms.

## Directory Structure

```
release/
├── scripts/                    # Release automation scripts
│   ├── release.sh             # Main release orchestration script
│   ├── package.sh             # Multi-platform packaging script
│   └── version.sh             # Version management script
├── packaging/                  # Platform-specific packaging configs
│   ├── debian/                # Debian/Ubuntu (.deb) packaging
│   ├── rpm/                   # Fedora/RHEL (.rpm) packaging
│   ├── windows/               # Windows (.msi) installer
│   └── macos/                 # macOS (.pkg) packaging
├── homebrew/                   # Homebrew formula
├── chocolatey/                 # Chocolatey package config
├── snap/                       # Snap package config
├── flatpak/                    # Flatpak manifest
├── appimage/                   # AppImage builder config
├── .github/workflows/          # GitHub Actions CI/CD
├── .gitlab-ci-release.yml      # GitLab CI/CD pipeline
├── docs/                       # Release documentation
│   ├── RELEASE_PROCESS.md     # Step-by-step release guide
│   ├── PACKAGING_GUIDE.md     # Platform packaging guide
│   └── VERSION_POLICY.md      # Versioning policy
├── templates/                  # Release note templates
│   ├── RELEASE_NOTES.md.tmpl  # Release notes template
│   └── ANNOUNCEMENT.md.tmpl   # Release announcement template
├── verify/                     # Release verification scripts
│   ├── verify_release.sh      # Verify release artifacts
│   └── test_install.sh        # Test installation on various platforms
└── README.md                   # This file
```

## Quick Start

### Prerequisites

Install required tools:

```bash
# On Ubuntu/Debian
sudo apt-get install -y dpkg-dev rpm git jq gpg

# On macOS
brew install git jq gpg

# On Fedora
sudo dnf install -y rpm-build git jq gpg
```

### Create a Release

1. **Automated Release (Recommended)**

   ```bash
   cd release

   # Dry run first
   ./scripts/release.sh patch --dry-run

   # Create actual release
   ./scripts/release.sh patch    # For patch release (1.0.0 → 1.0.1)
   ./scripts/release.sh minor    # For minor release (1.0.0 → 1.1.0)
   ./scripts/release.sh major    # For major release (1.0.0 → 2.0.0)
   ```

2. **What Gets Done Automatically**

   The release script handles:
   - ✅ Version bumping across all files
   - ✅ Changelog generation from git commits
   - ✅ Running full test suite
   - ✅ Building all components
   - ✅ Packaging for all platforms
   - ✅ Creating git tags
   - ✅ Generating release notes
   - ✅ Creating GitHub/GitLab releases
   - ✅ Uploading all artifacts

## Usage

### Version Management

```bash
# Check current version
./scripts/version.sh current

# Bump version
./scripts/version.sh bump patch   # 1.0.0 → 1.0.1
./scripts/version.sh bump minor   # 1.0.0 → 1.1.0
./scripts/version.sh bump major   # 1.0.0 → 2.0.0

# Set specific version
./scripts/version.sh set 2.5.3

# Validate version consistency
./scripts/version.sh validate
```

### Packaging

```bash
# Package for all platforms
./scripts/package.sh --all

# Package for specific platforms
./scripts/package.sh --deb        # Debian/Ubuntu
./scripts/package.sh --rpm        # Fedora/RHEL
./scripts/package.sh --macos      # macOS
./scripts/package.sh --windows    # Windows

# Sign packages
./scripts/package.sh --all --sign
```

### Release Script Options

```bash
./scripts/release.sh [version-type] [options]

Version Types:
  major    Bump major version (X.0.0)
  minor    Bump minor version (x.Y.0)
  patch    Bump patch version (x.y.Z)

Options:
  --dry-run       Simulate release without making changes
  --skip-tests    Skip test suite
  --skip-build    Skip build process
  --skip-package  Skip packaging
  --skip-upload   Skip artifact upload
  -h, --help      Show help message
```

### Verification

```bash
# Verify release artifacts
./verify/verify_release.sh 1.0.0

# Test installation on various platforms (requires Docker)
./verify/test_install.sh 1.0.0
```

## Supported Platforms

### Package Formats

| Format | Platform | Command |
|--------|----------|---------|
| .deb | Debian, Ubuntu | `apt install ./package.deb` |
| .rpm | Fedora, RHEL, CentOS | `dnf install ./package.rpm` |
| .pkg | macOS | Double-click installer |
| .msi | Windows | Double-click installer |
| .tar.gz | All Linux | Extract and run |
| .zip | Windows | Extract and run |

### Package Managers

| Manager | Platform | Install Command |
|---------|----------|----------------|
| Homebrew | macOS, Linux | `brew install academic-workflow-suite` |
| Chocolatey | Windows | `choco install academic-workflow-suite` |
| Snap | Linux | `snap install academic-workflow-suite` |
| Flatpak | Linux | `flatpak install academic-workflow-suite` |
| AppImage | Linux | Download and run |

## CI/CD Integration

### GitHub Actions

The release workflow is automatically triggered on:
- Git tags (`v*`)
- Manual dispatch

```bash
# Create tag to trigger release
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

Workflow location: `.github/workflows/release.yml`

### GitLab CI

Configuration: `.gitlab-ci-release.yml`

Triggered on:
- Tags
- Main branch
- Manual pipeline

### What CI/CD Does

1. **Build** - Compiles for all platforms
   - Linux (x86_64, aarch64)
   - macOS (x86_64, arm64)
   - Windows (x86_64)

2. **Test** - Runs test suites
   - Unit tests
   - Integration tests
   - Platform-specific tests

3. **Package** - Creates all package formats
   - .deb, .rpm, .pkg, .msi
   - Snap, Flatpak, AppImage
   - Source archives

4. **Release** - Publishes release
   - Creates GitHub/GitLab release
   - Uploads all artifacts
   - Generates checksums
   - Signs packages

5. **Publish** - Distributes to registries
   - Docker Hub
   - Package managers
   - Distribution channels

## Package Signing

### Setup GPG Key

```bash
# Generate GPG key
gpg --full-generate-key

# List keys
gpg --list-secret-keys --keyid-format=long

# Export public key
gpg --armor --export YOUR_KEY_ID > public-key.asc
```

### Sign Packages

Packages are automatically signed when using:

```bash
./scripts/package.sh --all --sign
```

Or manually:

```bash
# Sign .deb
dpkg-sig --sign builder package.deb

# Sign .rpm
rpmsign --addsign package.rpm

# Sign tarball
gpg --detach-sign --armor package.tar.gz
```

## Documentation

### Essential Reading

- **[Release Process](docs/RELEASE_PROCESS.md)** - Complete release workflow
- **[Packaging Guide](docs/PACKAGING_GUIDE.md)** - Platform-specific packaging
- **[Version Policy](docs/VERSION_POLICY.md)** - Versioning guidelines

### Templates

- **[Release Notes Template](templates/RELEASE_NOTES.md.tmpl)** - Format for release notes
- **[Announcement Template](templates/ANNOUNCEMENT.md.tmpl)** - Release announcement format

## Troubleshooting

### Common Issues

**Tests Failing**
```bash
# Run tests with verbose output
cargo test --all -- --nocapture
npm test -- --verbose
```

**Build Failures**
```bash
# Clean build
cargo clean
rm -rf node_modules
cargo build --release
```

**Package Creation Issues**
```bash
# Check package contents
dpkg -c package.deb
rpm -qlp package.rpm
```

**Version Mismatch**
```bash
# Validate and fix version consistency
./scripts/version.sh validate
./scripts/version.sh set $(cat VERSION)
```

### Debug Mode

Enable debug mode for scripts:

```bash
# Dry run mode (no changes)
./scripts/release.sh patch --dry-run

# Verbose output
bash -x ./scripts/release.sh patch
```

## Best Practices

1. **Always test before releasing**
   - Run full test suite
   - Test on clean VM/container
   - Verify package installation

2. **Use semantic versioning**
   - Major: Breaking changes
   - Minor: New features
   - Patch: Bug fixes

3. **Write clear changelogs**
   - Document all changes
   - Include migration guides
   - List breaking changes

4. **Sign releases**
   - Use GPG for signing
   - Provide public key
   - Include checksums

5. **Verify artifacts**
   - Run verification scripts
   - Test on multiple platforms
   - Check package integrity

6. **Communicate releases**
   - Write release notes
   - Post announcements
   - Update documentation

## Security

### Security Releases

For security-related releases:

1. **Do not** disclose vulnerability before release
2. Use patch version bump
3. Coordinate with security team
4. Release with security advisory
5. Notify users through security channels

### Reporting Security Issues

Email: security@academicworkflow.org

## Support

### Getting Help

- 📖 [Documentation](docs/)
- 🐛 [Issue Tracker](https://github.com/academicworkflow/suite/issues)
- 💬 [Discord](https://discord.gg/academicworkflow)
- 📧 Email: maintainers@academicworkflow.org

### Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines.

## License

See [LICENSE](../LICENSE) for license information.

---

**Last Updated:** 2025-11-22
**Maintained by:** Academic Workflow Suite Team
