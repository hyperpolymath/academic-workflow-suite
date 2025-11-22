# Release Process

This document describes the complete release process for the Academic Workflow Suite.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Release Types](#release-types)
- [Automated Release](#automated-release)
- [Manual Release](#manual-release)
- [Post-Release](#post-release)
- [Rollback](#rollback)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before starting a release, ensure you have:

1. **Clean Git Working Directory**
   ```bash
   git status
   # Should show no uncommitted changes
   ```

2. **All Tests Passing**
   ```bash
   cargo test --all
   npm test
   mix test
   ```

3. **Updated Documentation**
   - README.md reflects new features
   - CHANGELOG.md is up to date (if manual release)
   - API documentation is current

4. **Required Tools Installed**
   - Git
   - Cargo (for Rust projects)
   - Node.js and npm (for JavaScript projects)
   - Elixir and Mix (for Elixir projects)
   - jq (JSON processor)
   - gpg (for signing)
   - GitHub CLI (gh) - optional but recommended

5. **Permissions**
   - Write access to the repository
   - Permission to create tags and releases
   - GPG key configured for signing (optional)

## Release Types

We follow [Semantic Versioning](https://semver.org/):

- **Major Release** (X.0.0): Breaking changes, incompatible API changes
- **Minor Release** (x.Y.0): New features, backward compatible
- **Patch Release** (x.y.Z): Bug fixes, backward compatible

## Automated Release

The recommended way to create a release is using the automated release script.

### 1. Prepare for Release

```bash
# Ensure you're on the main branch
git checkout main
git pull origin main

# Run pre-release checks
cd release
./scripts/release.sh --dry-run patch
```

### 2. Create Release

```bash
# For a patch release
./scripts/release.sh patch

# For a minor release
./scripts/release.sh minor

# For a major release
./scripts/release.sh major
```

### 3. What the Script Does

The release script automatically:

1. ✅ Runs pre-release checks
2. ✅ Bumps the version number
3. ✅ Generates changelog from git commits
4. ✅ Runs the complete test suite
5. ✅ Builds all components
6. ✅ Packages for all platforms
7. ✅ Creates a git tag
8. ✅ Generates release notes
9. ✅ Pushes to remote repository
10. ✅ Creates GitHub release with artifacts

### 4. Monitor CI/CD

After the script completes:

1. Check GitHub Actions for build status
2. Verify all platform builds succeeded
3. Check that packages were uploaded correctly

## Manual Release

If you need more control over the release process:

### 1. Bump Version

```bash
cd release/scripts
./version.sh bump [major|minor|patch]
```

### 2. Update Changelog

Edit `CHANGELOG.md` manually or generate:

```bash
# Get commits since last tag
git log $(git describe --tags --abbrev=0)..HEAD --oneline
```

### 3. Commit Version Bump

```bash
git add -A
git commit -m "Release v$(cat VERSION)"
```

### 4. Create Tag

```bash
VERSION=$(cat VERSION)
git tag -a "v$VERSION" -m "Release v$VERSION"
```

### 5. Run Tests

```bash
cargo test --all
npm test
mix test
```

### 6. Build Packages

```bash
cd release
./scripts/package.sh --all
```

### 7. Push to Remote

```bash
git push origin main
git push origin v$VERSION
```

### 8. Create GitHub Release

```bash
gh release create "v$VERSION" \
  --title "Release v$VERSION" \
  --notes-file release/release-notes-$VERSION.md \
  release/dist/*
```

## Post-Release

After the release is published:

### 1. Update Package Managers

**Homebrew**
```bash
# Update formula in homebrew-aws repository
cd homebrew-aws
./update-formula.sh $VERSION
git commit -am "Update to v$VERSION"
git push
```

**Chocolatey**
```bash
# Submit to Chocolatey (automated via CI)
# Or manually:
choco push release/dist/academic-workflow-suite.$VERSION.nupkg
```

**Snap Store**
```bash
snapcraft upload release/snap/*.snap --release=stable
```

### 2. Publish Announcement

1. **Blog Post**: Write release announcement
2. **Social Media**: Share on relevant channels
3. **Mailing List**: Email subscribers
4. **Discord/Slack**: Post in community channels

### 3. Update Documentation Site

```bash
# If you have a separate docs site
cd docs-site
./deploy.sh $VERSION
```

### 4. Monitor Issues

- Watch for bug reports related to new release
- Monitor package manager installation issues
- Check for platform-specific problems

## Rollback

If you need to rollback a release:

### 1. Delete GitHub Release

```bash
gh release delete v$VERSION
```

### 2. Delete Tag

```bash
# Delete remote tag
git push --delete origin v$VERSION

# Delete local tag
git tag -d v$VERSION
```

### 3. Revert Version Changes

```bash
git revert HEAD
git push origin main
```

### 4. Communicate

- Update GitHub release notes (if keeping as draft)
- Post to community channels
- Document issues that caused rollback

## Troubleshooting

### Tests Failing

```bash
# Run tests with verbose output
cargo test --all -- --nocapture

# Run specific test
cargo test test_name -- --nocapture

# Check CI logs
gh run list
gh run view <run-id>
```

### Build Failures

```bash
# Clean build
cargo clean
cargo build --release

# Check for platform-specific issues
docker run -it --rm -v $(pwd):/app ubuntu:latest bash
cd /app && cargo build --release
```

### Package Creation Issues

```bash
# Test package creation locally
./scripts/package.sh --deb
dpkg -c release/dist/*.deb  # Check contents

./scripts/package.sh --rpm
rpm -qlp release/dist/*.rpm  # Check contents
```

### Git Tag Already Exists

```bash
# Delete local tag
git tag -d v$VERSION

# Delete remote tag (be careful!)
git push --delete origin v$VERSION

# Try release again
./scripts/release.sh patch
```

### Permission Denied

```bash
# Make scripts executable
chmod +x release/scripts/*.sh

# Check GitHub permissions
gh auth status

# Verify GPG key
gpg --list-keys
```

## Best Practices

1. **Always use semantic versioning**
2. **Test thoroughly before releasing**
3. **Write clear changelog entries**
4. **Tag releases immediately after merging**
5. **Keep release notes user-focused**
6. **Monitor first 24 hours after release**
7. **Have a rollback plan**
8. **Communicate with users**

## Release Checklist

Use this checklist for each release:

- [ ] All tests passing
- [ ] Documentation updated
- [ ] Changelog updated
- [ ] Version bumped correctly
- [ ] Git working directory clean
- [ ] Release notes written
- [ ] Packages built and tested
- [ ] Tag created and pushed
- [ ] GitHub release created
- [ ] Artifacts uploaded
- [ ] Package managers updated
- [ ] Announcement published
- [ ] Community notified

## Security Releases

For security releases:

1. **Do not** disclose vulnerability details before release
2. Use patch version bump
3. Coordinate with security team
4. Prepare security advisory
5. Release simultaneously with advisory
6. Notify users through security channels

## Support

For help with releases:

- Open an issue: https://github.com/academicworkflow/suite/issues
- Email: maintainers@academicworkflow.org
- Discord: https://discord.gg/academicworkflow
