# CI/CD Scripts

This directory contains helper scripts for the CI/CD pipeline of Academic Workflow Suite.

## Scripts

### build-all.sh
Builds all components of the Academic Workflow Suite.

**Usage:**
```bash
./build-all.sh [--release|--debug]
```

**Features:**
- Builds Rust core component
- Builds Rust AI jail component
- Builds Elixir backend
- Builds Office add-in (Node.js/ReScript)
- Generates detailed build log
- Color-coded output for easy reading

**Output:**
- Build artifacts in respective `target/`, `_build/`, and `dist/` directories
- Build log at `build.log` in project root

### test-integration.sh
Runs integration tests across all components.

**Usage:**
```bash
./test-integration.sh
```

**Features:**
- Tests binary existence and execution
- Tests component communication
- Tests AI jail isolation
- Validates configuration files
- Checks documentation
- Generates JUnit XML test reports

**Output:**
- Test results in `tests/integration/results/`
- JUnit XML report at `tests/integration/results/junit.xml`
- Individual test logs for each test case

### package.sh
Creates distribution packages for various platforms.

**Usage:**
```bash
./package.sh [deb|msi|dmg|office-addin|all]
```

**Package Types:**
- `deb` - Debian/Ubuntu package (.deb)
- `msi` - Windows installer (.msi)
- `dmg` - macOS disk image (.dmg)
- `office-addin` - Office add-in package (.tgz)
- `all` - Build all package types

**Features:**
- Creates platform-specific installers
- Includes all necessary binaries and documentation
- Generates SHA256 checksums
- Sets up post-install scripts (for .deb)

**Output:**
- Packages in `packages/` directory
- Checksums in `packages/SHA256SUMS`

## CI/CD Integration

These scripts are used by:
- **GitLab CI/CD** - See `.gitlab-ci.yml`
- **GitHub Actions** - See `.github/workflows/ci.yml`

### GitLab CI Pipeline Stages

1. **Lint** - Code quality checks (Rust, Elixir, ReScript, Shell)
2. **Build** - Build all components using `build-all.sh`
3. **Test** - Run unit and integration tests using `test-integration.sh`
4. **Security** - Security scanning (cargo-audit, npm audit, Semgrep)
5. **Package** - Create distribution packages using `package.sh`
6. **Deploy** - Deploy to staging/production environments

### GitHub Actions Workflow

- Matrix builds across Windows, Linux, and macOS
- Parallel execution of independent jobs
- Artifact uploading and downloading
- Integration with Codecov for coverage reports

## Development Usage

### Local Testing

Before pushing to CI, you can test locally:

```bash
# Build everything
./scripts/ci/build-all.sh --release

# Run integration tests
./scripts/ci/test-integration.sh

# Create packages
./scripts/ci/package.sh all
```

### Debugging

Each script generates detailed logs:
- `build-all.sh` → `build.log`
- `test-integration.sh` → `tests/integration/results/*.log`
- `package.sh` → stdout (can be redirected)

### Color Output

All scripts use color-coded output:
- 🔵 **BLUE** - Informational messages
- 🟢 **GREEN** - Success messages
- 🟡 **YELLOW** - Warnings
- 🔴 **RED** - Errors

## Environment Variables

Scripts respect the following environment variables:

- `VERSION` - Package version (default: 0.1.0)
- `BUILD_MODE` - Build mode: release or debug (default: release)
- `MIX_ENV` - Elixir environment: prod, dev, test
- `NODE_ENV` - Node.js environment: production, development, test

## Requirements

### Build Dependencies

**For Rust components:**
- Rust 1.75+
- cargo
- build-essential (Linux)

**For Elixir backend:**
- Elixir 1.15+
- Erlang/OTP 26+
- mix

**For Office add-in:**
- Node.js 20+
- npm

**For Packaging:**
- `dpkg-deb` (for .deb packages)
- `wixl` or WiX Toolset (for .msi packages)
- `hdiutil` (macOS, for .dmg packages)

## Contributing

When modifying these scripts:

1. Test locally before committing
2. Ensure scripts are POSIX-compatible where possible
3. Add appropriate error handling (`set -e`, `set -u`, `set -o pipefail`)
4. Update this README with any new features
5. Maintain color-coded output for consistency

## Troubleshooting

### Build Failures

If `build-all.sh` fails:
1. Check `build.log` for detailed error messages
2. Ensure all dependencies are installed
3. Verify Cargo.lock and mix.lock are up to date
4. Try building individual components manually

### Test Failures

If `test-integration.sh` fails:
1. Check individual test logs in `tests/integration/results/`
2. Ensure all components built successfully
3. Verify binaries have execute permissions
4. Check that required configuration files exist

### Packaging Issues

If `package.sh` fails:
1. Ensure release builds completed successfully
2. Check that packaging tools are installed
3. Verify VERSION environment variable is set
4. Review package structure in `packages/` directory

## License

Same as the main Academic Workflow Suite project (see LICENSE file).
