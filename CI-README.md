# CI/CD Setup - Quick Start Guide

This repository includes a comprehensive CI/CD pipeline for the Academic Workflow Suite.

## 📋 What's Included

### Pipeline Configurations

1. **`.gitlab-ci.yml`** (785 lines)
   - Primary CI/CD pipeline for GitLab
   - 6 stages: Lint → Build → Test → Security → Package → Deploy
   - 30+ jobs with intelligent caching and parallelization
   - Comprehensive security scanning

2. **`.github/workflows/ci.yml`** (680 lines)
   - Mirror pipeline for GitHub
   - Matrix builds (Windows, Linux, macOS)
   - Integration with GitHub features (CodeQL, dependabot)
   - Container registry support (ghcr.io)

### Helper Scripts

Located in `scripts/ci/`:

- **`build-all.sh`** (201 lines) - Build all components
- **`test-integration.sh`** (290 lines) - Run integration tests
- **`package.sh`** (341 lines) - Create distribution packages

All scripts are executable and include:
- Color-coded output
- Error handling
- Detailed logging
- Cross-platform compatibility

### Configuration Files

- **`.dockerignore`** / **`.containerignore`** - Optimize container builds
- **`.yamllint`** - YAML linting configuration
- **`.editorconfig`** - Code style consistency
- **`.github/dependabot.yml`** - Automated dependency updates

### Documentation

- **`docs/CI-CD.md`** - Comprehensive pipeline documentation
- **`scripts/ci/README.md`** - Script usage and troubleshooting

## 🚀 Quick Start

### Local Testing (Before Push)

```bash
# Build everything
./scripts/ci/build-all.sh --release

# Run tests
./scripts/ci/test-integration.sh

# Create packages
./scripts/ci/package.sh all
```

### GitLab CI/CD Setup

1. **No additional configuration needed!** The pipeline will run automatically on push.

2. **Set required environment variables** (GitLab Settings → CI/CD → Variables):
   ```
   CODECOV_TOKEN       (optional - for coverage)
   STAGING_SERVER      (for deployment)
   STAGING_SSH_KEY     (for deployment)
   PROD_SERVER         (for deployment)
   PROD_SSH_KEY        (for deployment)
   ```

3. **Enable GitLab Container Registry** (for AI jail images)

### GitHub Actions Setup

1. **Enable Actions** in repository settings

2. **Set secrets** (Settings → Secrets and variables → Actions):
   ```
   CODECOV_TOKEN       (optional)
   GITHUB_TOKEN        (automatically provided)
   ```

3. **Enable GitHub Container Registry** (ghcr.io)

## 📊 Pipeline Stages

### Stage 1: Lint (7 jobs)
- Rust: clippy, fmt
- Elixir: format, credo
- ReScript: lint
- Shell: shellcheck
- YAML: yamllint

### Stage 2: Build (4 jobs)
- Rust core (release mode)
- Rust AI jail (release mode)
- Elixir backend (prod)
- Office add-in (webpack prod)

### Stage 3: Test (7 jobs)
- Rust unit tests (core, AI jail)
- Elixir unit tests
- ReScript tests
- Integration tests
- **AI isolation tests (CRITICAL!)**
- Code coverage

### Stage 4: Security (7 jobs)
- cargo-audit (Rust)
- hex.audit (Elixir)
- npm audit (Node)
- Semgrep SAST
- Secret detection
- License compliance
- Container scanning

### Stage 5: Package (5 jobs)
- DEB package (Linux)
- MSI installer (Windows)
- Container image (AI jail)
- Office add-in (.tgz)
- Checksums (SHA256)

### Stage 6: Deploy (3 jobs)
- Staging (manual)
- Production (manual, protected)
- Release creation (tags only)

## 🔒 Security Features

### Multi-Layer Security

1. **SAST** - Static analysis with Semgrep
2. **Dependency Scanning** - cargo-audit, hex.audit, npm audit
3. **Secret Detection** - Pattern-based scanning
4. **Container Scanning** - Trivy (if available)
5. **License Compliance** - Automated license checking

### Critical Security Tests

- **AI Jail Isolation** - MUST PASS
  - Container isolation validation
  - Resource limit testing
  - Capability dropping verification
  - Privilege escalation prevention

## 📦 Artifacts & Caching

### Caching Strategy

- **Rust:** Cargo dependencies (~70% faster builds)
- **Elixir:** Mix dependencies (~60% faster builds)
- **Node:** npm modules (~80% faster installs)

### Artifacts Retention

- Build artifacts: 1 week
- Test reports: 30 days
- Packages: 1 month
- Container images: Permanent

## 🎯 Key Features

### Intelligent Parallelization

Jobs run in parallel where possible for maximum speed:
- All lint jobs run simultaneously
- All build jobs run simultaneously
- All test jobs run simultaneously

### Fail-Fast Strategy

Critical issues block immediately:
- Rust clippy/fmt errors
- Shell script errors
- Test failures
- **AI isolation failures**

### Multi-Platform Support

- **Linux:** Native builds, DEB packages
- **Windows:** Cross-compilation, MSI installers
- **macOS:** Native builds, DMG packages (GitHub Actions)

### Automated Dependency Updates

Dependabot configured for:
- Rust (Cargo)
- Elixir (Mix)
- Node.js (npm)
- GitHub Actions
- Docker images

## 📈 Monitoring

### Pipeline Metrics

- Success rate (target: >95%)
- Average duration (target: <15 min)
- Cache hit rate (target: >80%)
- Test coverage (target: >80%)

### Status Indicators

- ✅ Green: All passed
- ⚠️ Yellow: Warnings
- ❌ Red: Failures
- ⏸️ Blue: Manual action needed

## 🛠️ Customization

### Adding Jobs

Edit `.gitlab-ci.yml` or `.github/workflows/ci.yml`:

```yaml
my-custom-job:
  stage: test
  script:
    - echo "Custom job"
  needs: [build:rust:core]
```

### Modifying Scripts

Edit scripts in `scripts/ci/`:
- Maintain error handling
- Use color-coded output
- Update README.md

### Environment Variables

Add variables in:
- GitLab: Settings → CI/CD → Variables
- GitHub: Settings → Secrets and variables

## 🐛 Troubleshooting

### Cache Issues

```bash
# Clear cache in GitLab CI/CD settings
# Or force rebuild:
git commit --allow-empty -m "chore: rebuild cache"
```

### Build Failures

1. Check build logs
2. Run locally: `./scripts/ci/build-all.sh`
3. Verify dependencies are installed
4. Check Cargo.lock/mix.lock/package-lock.json

### Test Failures

1. Download artifacts from failed job
2. Review test logs
3. Run locally: `./scripts/ci/test-integration.sh`
4. Check component-specific tests

### Deployment Issues

1. Verify environment variables are set
2. Check SSH key permissions
3. Test connectivity manually
4. Review deployment logs

## 📚 Documentation

- **[CI/CD.md](docs/CI-CD.md)** - Comprehensive pipeline documentation
- **[scripts/ci/README.md](scripts/ci/README.md)** - Script documentation
- **[CLAUDE.md](CLAUDE.md)** - Project guidelines

## 🔄 Workflow

### Development Flow

```
1. Create branch
   ↓
2. Make changes
   ↓
3. Test locally (build-all.sh, test-integration.sh)
   ↓
4. Push to repository
   ↓
5. CI pipeline runs automatically
   ↓
6. Fix any failures
   ↓
7. Create merge/pull request
   ↓
8. Maintainer review
   ↓
9. Merge to main
   ↓
10. Automatic package build
```

### Release Flow

```
1. Update VERSION in .gitlab-ci.yml
   ↓
2. Create tag: git tag v1.0.0
   ↓
3. Push tag: git push origin v1.0.0
   ↓
4. Pipeline builds packages
   ↓
5. Manual deployment to staging
   ↓
6. Test in staging
   ↓
7. Manual deployment to production
   ↓
8. Create GitHub/GitLab release
```

## 🎓 Learning Resources

- [GitLab CI/CD Docs](https://docs.gitlab.com/ee/ci/)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Rust CI Best Practices](https://doc.rust-lang.org/cargo/guide/continuous-integration.html)
- [Elixir CI Best Practices](https://hexdocs.pm/phoenix/testing.html)

## 💡 Tips

1. **Run locally first** - Save CI time and resources
2. **Use caching** - Massive speed improvements
3. **Fix lint errors early** - They block the pipeline
4. **Monitor coverage** - Aim for >80%
5. **Review security scans** - Don't ignore warnings
6. **Keep pipelines fast** - Optimize slow jobs
7. **Document changes** - Update this README

## 📞 Support

- **Issues:** Use GitHub/GitLab issue tracker
- **Questions:** Check documentation first
- **Bugs:** Provide pipeline logs and reproduction steps
- **Features:** Discuss in merge/pull requests

## 🎉 Success Checklist

Before your first pipeline run:

- [ ] Environment variables set
- [ ] Scripts are executable
- [ ] Dependencies documented
- [ ] Tests are passing locally
- [ ] Documentation updated
- [ ] Security scans reviewed

## 📝 License

Same as the main Academic Workflow Suite project.

---

**Last Updated:** 2025-11-22
**Pipeline Version:** 1.0
**Status:** ✅ Production Ready
