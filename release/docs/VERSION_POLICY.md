# Version Policy

This document describes the versioning policy for the Academic Workflow Suite.

## Semantic Versioning

We follow [Semantic Versioning 2.0.0](https://semver.org/). Given a version number `MAJOR.MINOR.PATCH`:

- **MAJOR** version when you make incompatible API changes
- **MINOR** version when you add functionality in a backward compatible manner
- **PATCH** version when you make backward compatible bug fixes

### Format

```
MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]
```

Examples:
- `1.0.0` - Initial stable release
- `1.2.3` - Minor update with patches
- `2.0.0-alpha.1` - Pre-release
- `1.0.0+20250122` - Build metadata

## Version Components

### Major Version (X.0.0)

Increment when making **incompatible changes**:

- Breaking API changes
- Removing features
- Major architectural changes
- Incompatible CLI changes
- Database schema changes requiring migration

**Examples:**
```
1.x.x → 2.0.0  # Breaking API changes
2.x.x → 3.0.0  # Removed deprecated features
```

**Guidelines:**
- Provide migration guide
- Deprecate features in previous major version first
- Maintain backward compatibility for at least one version
- Document all breaking changes clearly

### Minor Version (x.Y.0)

Increment when adding **backward-compatible functionality**:

- New features
- New API endpoints
- Performance improvements
- Deprecating features (with warnings)
- Internal refactoring (user-facing compatible)

**Examples:**
```
1.0.x → 1.1.0  # Added new feature
1.1.x → 1.2.0  # Added new commands
```

**Guidelines:**
- Must be backward compatible
- Deprecation warnings allowed
- Performance improvements encouraged
- Update documentation for new features

### Patch Version (x.y.Z)

Increment for **backward-compatible bug fixes**:

- Bug fixes
- Security patches
- Documentation fixes
- Minor improvements
- Dependency updates (security)

**Examples:**
```
1.0.0 → 1.0.1  # Fixed bug
1.0.1 → 1.0.2  # Security patch
```

**Guidelines:**
- No new features
- No API changes
- Only fixes and security updates
- Safe to auto-update

## Pre-Release Versions

### Alpha (x.y.z-alpha.N)

- Very early development
- APIs may change frequently
- Not feature complete
- Internal testing only
- May have critical bugs

**Example:** `2.0.0-alpha.1`

### Beta (x.y.z-beta.N)

- Feature complete
- APIs mostly stable
- Public testing
- Known bugs being fixed
- Documentation in progress

**Example:** `2.0.0-beta.1`

### Release Candidate (x.y.z-rc.N)

- Ready for release
- No new features
- Only critical bug fixes
- Final testing phase
- Documentation complete

**Example:** `2.0.0-rc.1`

### Pre-Release Progression

```
1.9.0                    # Current stable
↓
2.0.0-alpha.1           # First alpha
2.0.0-alpha.2           # Second alpha
↓
2.0.0-beta.1            # First beta
2.0.0-beta.2            # Second beta
↓
2.0.0-rc.1              # Release candidate
2.0.0-rc.2              # Final RC
↓
2.0.0                   # Stable release
```

## Build Metadata

Build metadata can be appended with `+`:

- `1.0.0+20250122` - Date-based build
- `1.0.0+exp.sha.5114f85` - Experimental build
- `1.0.0+linux.amd64` - Platform-specific build

**Note:** Build metadata is ignored when determining version precedence.

## Version Precedence

From lowest to highest:

```
1.0.0-alpha.1
1.0.0-alpha.2
1.0.0-beta.1
1.0.0-beta.2
1.0.0-rc.1
1.0.0
1.0.1
1.1.0
2.0.0
```

## Development Workflow

### Feature Development

```
main (1.0.0)
  ↓
feature-branch (1.1.0-dev)
  ↓
merge → main (1.1.0)
```

### Hotfix

```
main (1.0.0)
  ↓
hotfix-branch (1.0.1-dev)
  ↓
merge → main (1.0.1)
```

### Major Release

```
main (1.9.0)
  ↓
2.0-branch (2.0.0-alpha.1)
  ↓
2.0-branch (2.0.0-beta.1)
  ↓
2.0-branch (2.0.0-rc.1)
  ↓
merge → main (2.0.0)
```

## Version Control

### Git Tags

All releases must be tagged:

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

### Tag Naming Convention

- Stable: `v1.0.0`
- Pre-release: `v2.0.0-beta.1`
- Internal: `v1.0.0-dev.20250122`

### Branch Protection

- `main`: Only stable releases
- `develop`: Next minor/major version
- `hotfix/*`: Patch releases

## Compatibility Guarantees

### API Stability

- **Major versions**: No compatibility guarantee
- **Minor versions**: Backward compatible
- **Patch versions**: Full compatibility

### CLI Stability

- Command names: Stable within major version
- Flags: Can add new, must deprecate before removing
- Output format: Stable for scripts (use `--format`)

### Configuration

- Config file format: Versioned separately
- Must support migration between major versions
- Deprecation warnings one minor version before breaking

## Deprecation Policy

### Deprecation Process

1. **Announce** (Minor release N):
   - Add deprecation warning
   - Document alternative
   - Update migration guide

2. **Maintain** (Minor release N+1 to N+X):
   - Keep deprecated feature working
   - Continue showing warnings
   - Give users time to migrate

3. **Remove** (Major release N+1):
   - Remove deprecated feature
   - Update documentation
   - Provide migration tools

### Deprecation Timeline

- **Minor features**: 2 minor versions
- **Major features**: 1 major version
- **Critical features**: 2 major versions

**Example:**
```
v1.5.0 - Deprecate old API
v1.6.0 - Still supported, with warnings
v1.7.0 - Still supported, with warnings
v2.0.0 - Removed
```

## Version File Locations

Versions are maintained in:

```
VERSION                           # Primary version file
Cargo.toml                        # Rust projects
package.json                      # Node.js projects
mix.exs                           # Elixir projects
setup.py                          # Python projects
README.md                         # Documentation
CHANGELOG.md                      # Release history
```

## Automated Version Management

### Bumping Versions

```bash
# Patch release
./release/scripts/version.sh bump patch

# Minor release
./release/scripts/version.sh bump minor

# Major release
./release/scripts/version.sh bump major
```

### Validation

```bash
# Check version consistency
./release/scripts/version.sh validate
```

## Changelog Requirements

Every version must have a changelog entry in `CHANGELOG.md`:

```markdown
## [1.2.0] - 2025-01-22

### Added
- New feature X
- Support for Y

### Changed
- Improved performance of Z

### Deprecated
- Feature A (use B instead)

### Removed
- Nothing

### Fixed
- Bug in component C
- Security issue in D

### Security
- CVE-2025-XXXX fixed
```

## Support Policy

### Long-Term Support (LTS)

- LTS releases: Every X.0.0 major version
- Support duration: 2 years
- Security patches: Backported to LTS
- Bug fixes: Critical only

### Standard Support

- Latest major version: Full support
- Previous major: Security patches for 6 months
- Older versions: Community support only

## Examples

### When to Bump Each Version

#### Patch (1.0.0 → 1.0.1)
```
✅ Fixed crash when parsing invalid input
✅ Updated dependency for security fix
✅ Fixed typo in error message
✅ Performance improvement (no API change)
❌ Added new command
❌ Changed default behavior
```

#### Minor (1.0.0 → 1.1.0)
```
✅ Added new optional parameter
✅ Added new command
✅ Deprecated old feature (still works)
✅ Performance improvement (significant)
❌ Removed deprecated feature
❌ Changed required parameter type
```

#### Major (1.0.0 → 2.0.0)
```
✅ Removed deprecated features
✅ Changed CLI argument structure
✅ Rewrote core architecture
✅ Changed configuration file format
❌ Added backward-compatible feature
❌ Fixed bug
```

## References

- [Semantic Versioning 2.0.0](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Git Tagging Best Practices](https://git-scm.com/book/en/v2/Git-Basics-Tagging)
- [Calendar Versioning](https://calver.org/) (for reference, not used)

## Questions?

For questions about versioning:
- Open an issue: https://github.com/academicworkflow/suite/issues
- Email: maintainers@academicworkflow.org
