# CI/CD Pipeline Documentation

## Overview

The Academic Workflow Suite uses a comprehensive CI/CD pipeline to ensure code quality, security, and reliable deployments. The pipeline is configured for both **GitLab CI/CD** (primary) and **GitHub Actions** (mirror).

## Pipeline Architecture

### GitLab CI/CD (Primary)

The pipeline consists of **6 stages** with **30+ jobs**:

```
Lint → Build → Test → Security → Package → Deploy
```

#### Stage 1: Lint (Code Quality)

Ensures code quality and style consistency across all languages.

| Job | Purpose | Tools | Fail Fast |
|-----|---------|-------|-----------|
| `lint:rust:clippy` | Rust static analysis | cargo clippy | ✅ Yes |
| `lint:rust:fmt` | Rust formatting | cargo fmt | ✅ Yes |
| `lint:elixir:format` | Elixir formatting | mix format | ✅ Yes |
| `lint:elixir:credo` | Elixir static analysis | mix credo | ⚠️ Warning |
| `lint:rescript` | ReScript linting | npm lint | ⚠️ Warning |
| `lint:shell` | Shell script validation | shellcheck | ✅ Yes |
| `lint:yaml` | YAML validation | yamllint | ⚠️ Warning |

**Triggers:** Runs on all commits and merge requests.

#### Stage 2: Build

Compiles all components in release mode with caching.

| Job | Component | Output | Cache |
|-----|-----------|--------|-------|
| `build:rust:core` | Core application | Binary | Cargo cache |
| `build:rust:ai-jail` | AI isolation | Binary | Cargo cache |
| `build:elixir:backend` | API backend | Release | Mix cache |
| `build:office-addin` | Office add-in | Webpack bundle | npm cache |

**Artifacts:** All build outputs are saved for 1 week and used in subsequent stages.

**Caching Strategy:**
- Cargo dependencies cached by `Cargo.lock` hash
- Mix dependencies cached by `mix.lock` hash
- npm dependencies cached by `package-lock.json` hash

#### Stage 3: Test

Comprehensive testing including unit, integration, and specialized tests.

| Job | Type | Coverage | Report Format |
|-----|------|----------|---------------|
| `test:rust:core` | Unit tests | Yes | JUnit XML |
| `test:rust:ai-jail` | Unit tests | Yes | JUnit XML |
| `test:elixir:backend` | Unit tests | Yes | Cobertura XML |
| `test:rescript:office-addin` | Unit tests | Yes | Cobertura XML |
| `test:integration` | Integration | No | JUnit XML |
| `test:ai-isolation` | **Critical security** | No | Custom |
| `test:coverage` | Coverage report | Codecov | XML |

**Critical Tests:**
- `test:ai-isolation` - **MUST PASS** - Validates AI jail security
  - Tests container isolation
  - Validates resource limits
  - Checks capability dropping
  - Ensures no privilege escalation

**Coverage:**
- Uploaded to Codecov
- Tracked per component (core, ai-jail, backend, office-addin)

#### Stage 4: Security

Multi-layer security scanning for vulnerabilities and compliance.

| Job | Scope | Tool | Severity |
|-----|-------|------|----------|
| `security:rust:audit` | Rust dependencies | cargo-audit | High |
| `security:elixir:audit` | Elixir dependencies | mix hex.audit | Medium |
| `security:node:audit` | Node dependencies | npm audit | Medium |
| `security:sast:semgrep` | Source code | Semgrep | High |
| `security:secret-detection` | Secrets/credentials | git grep | Critical |
| `security:license-compliance` | License check | Various | Info |
| `security:container-scan` | Container images | Trivy | High |

**Security Policies:**
- Rust vulnerabilities: **Block on HIGH/CRITICAL**
- Secret detection: **Block immediately**
- SAST findings: **Review required**
- License compliance: **Informational**

#### Stage 5: Package

Creates distribution packages for all supported platforms.

| Job | Platform | Format | Triggers |
|-----|----------|--------|----------|
| `package:deb` | Linux | .deb | main, tags |
| `package:msi` | Windows | .msi | main, tags |
| `package:container:ai-jail` | Linux | OCI image | main, tags |
| `package:office-addin` | Cross-platform | .tgz | main, tags |
| `package:checksums` | All | SHA256SUMS | main, tags |

**Package Naming:**
- DEB: `academic-workflow-suite_${VERSION}_amd64.deb`
- MSI: `AcademicWorkflowSuite-${VERSION}.msi`
- Container: `registry.gitlab.com/org/project/ai-jail:${VERSION}`
- Office: `office-addin-${VERSION}.tgz`

#### Stage 6: Deploy

Deployment to staging and production environments.

| Job | Environment | Trigger | Protection |
|-----|-------------|---------|------------|
| `deploy:staging` | Staging | Manual | None |
| `deploy:production` | Production | Manual | Protected |
| `deploy:release` | GitHub/GitLab | Manual (tags) | Protected |

**Environments:**
- **Staging:** `https://staging.academic-workflow.example.com`
- **Production:** `https://academic-workflow.example.com`

**Protection Rules:**
- Production deploys require maintainer approval
- Only runs on `main` branch or tags
- Requires all tests to pass

### GitHub Actions (Mirror)

The GitHub Actions workflow provides similar functionality with platform-specific features:

#### Matrix Builds

Parallel builds across multiple platforms:

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest, macos-latest]
    component: [core, ai-jail]
```

**Benefits:**
- Cross-platform testing
- Native builds for each OS
- Parallel execution (faster CI)

#### Key Differences from GitLab CI

| Feature | GitLab CI | GitHub Actions |
|---------|-----------|----------------|
| Matrix builds | Manual | Native support |
| Caching | Custom paths | Actions cache |
| Artifacts | Built-in | actions/upload-artifact |
| Container registry | GitLab Registry | GitHub Container Registry (ghcr.io) |
| Security | Semgrep | CodeQL + Semgrep |

## Caching Strategy

### Rust (Cargo)

```yaml
cache:
  key:
    files:
      - Cargo.lock
  paths:
    - .cargo/
    - target/
```

**Benefits:**
- Incremental compilation
- Dependency reuse
- ~70% faster builds

### Elixir (Mix)

```yaml
cache:
  key:
    files:
      - mix.lock
  paths:
    - .mix/
    - .hex/
    - deps/
    - _build/
```

**Benefits:**
- Compiled dependencies
- ~60% faster builds

### Node.js (npm)

```yaml
cache:
  key:
    files:
      - package-lock.json
  paths:
    - node_modules/
    - .npm/
```

**Benefits:**
- Module reuse
- ~80% faster installs

## Artifacts

### Build Artifacts (1 week retention)

- Rust binaries: `components/*/target/release/*`
- Elixir releases: `components/backend/_build/prod/`
- Office add-in: `components/office-addin/dist/`

### Test Reports (30 days retention)

- JUnit XML reports
- Coverage reports (Cobertura XML)
- Integration test logs

### Packages (1 month retention)

- Debian packages (.deb)
- Windows installers (.msi)
- Container images (OCI)
- Office add-in packages (.tgz)

## Environment Variables

### Build Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `VERSION` | Package version | `0.1.0` |
| `MIX_ENV` | Elixir environment | `test` |
| `NODE_ENV` | Node environment | `test` |
| `RUST_BACKTRACE` | Rust error traces | `1` |

### Secret Variables (Protected)

| Variable | Purpose | Required |
|----------|---------|----------|
| `CODECOV_TOKEN` | Coverage upload | Optional |
| `CI_REGISTRY_USER` | Container registry | Production |
| `CI_REGISTRY_PASSWORD` | Registry auth | Production |
| `STAGING_SERVER` | Staging SSH | Deploy |
| `STAGING_SSH_KEY` | Staging auth | Deploy |
| `PROD_SERVER` | Production SSH | Deploy |
| `PROD_SSH_KEY` | Production auth | Deploy |

## Pipeline Triggers

### Automatic Triggers

1. **Push to any branch** → Full pipeline (lint, build, test, security)
2. **Merge request** → Full pipeline + additional checks
3. **Tag (v*.*.*)** → Full pipeline + package + release

### Manual Triggers

1. **Staging deployment** → After successful build
2. **Production deployment** → After successful build (protected)
3. **Release creation** → On tags only

## Workflow Rules

```yaml
workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS'
      when: never  # Avoid duplicate pipelines
    - if: '$CI_COMMIT_BRANCH'
    - if: '$CI_COMMIT_TAG'
```

**Effects:**
- Runs on MR events
- Runs on branch pushes (if no open MR)
- Runs on tag pushes
- Prevents duplicate pipelines

## Parallel Execution

Jobs run in parallel where possible:

```
Lint Stage (7 jobs in parallel)
  ├── lint:rust:clippy
  ├── lint:rust:fmt
  ├── lint:elixir:format
  ├── lint:elixir:credo
  ├── lint:rescript
  ├── lint:shell
  └── lint:yaml

Build Stage (4 jobs in parallel)
  ├── build:rust:core
  ├── build:rust:ai-jail
  ├── build:elixir:backend
  └── build:office-addin
```

**Benefits:**
- Faster feedback
- Efficient resource usage
- Early failure detection

## Fail-Fast Strategy

Critical jobs block the pipeline:

1. **Rust clippy errors** → Block
2. **Rust formatting errors** → Block
3. **Shell script errors** → Block
4. **Test failures** → Block
5. **AI isolation failures** → **CRITICAL BLOCK**

Non-critical jobs warn but don't block:

1. Credo warnings
2. YAML linting
3. License compliance

## Security Scanning

### SAST (Static Application Security Testing)

**Semgrep Rules:**
- `p/security-audit` - General security patterns
- `p/secrets` - Secret detection
- `p/owasp-top-ten` - OWASP vulnerabilities

**Language Coverage:**
- Rust (security patterns)
- Elixir (Phoenix patterns)
- JavaScript/TypeScript (XSS, injection)
- YAML (misconfigurations)

### Dependency Scanning

**Rust (cargo-audit):**
- Checks RustSec Advisory Database
- Blocks on HIGH/CRITICAL vulnerabilities
- Reports available fixes

**Elixir (mix hex.audit):**
- Checks Hex package security
- Reports outdated packages
- Suggests updates

**Node.js (npm audit):**
- Checks npm registry advisories
- Reports severity levels
- Suggests fixes

### Secret Detection

Custom script checks for:
- Hardcoded passwords
- API keys
- Private keys
- Tokens
- Credentials in URLs

### Container Scanning

**Trivy (if available):**
- Scans base images
- Checks for CVEs
- Reports HIGH/CRITICAL vulnerabilities

## Best Practices

### For Developers

1. **Run locally before push:**
   ```bash
   ./scripts/ci/build-all.sh --release
   ./scripts/ci/test-integration.sh
   ```

2. **Fix linting issues:**
   ```bash
   cargo fmt --all
   cargo clippy --fix
   mix format
   ```

3. **Check security:**
   ```bash
   cargo audit
   npm audit
   ```

4. **Test changes:**
   - Run relevant unit tests
   - Test integration points
   - Verify AI jail isolation

### For Maintainers

1. **Review security findings** before merging
2. **Check test coverage** trends
3. **Monitor build performance** (cache hit rates)
4. **Update dependencies** regularly
5. **Rotate secrets** periodically

### For CI/CD

1. **Keep pipelines fast** (<15 minutes ideal)
2. **Use caching** effectively
3. **Parallelize** where possible
4. **Fail fast** on critical issues
5. **Archive artifacts** appropriately

## Monitoring

### Pipeline Metrics

- **Success rate** (target: >95%)
- **Average duration** (target: <15 min)
- **Cache hit rate** (target: >80%)
- **Test coverage** (target: >80%)

### Key Indicators

- ✅ **Green:** All jobs passed
- ⚠️ **Yellow:** Non-critical warnings
- ❌ **Red:** Critical failures
- ⏸️ **Blue:** Manual intervention needed

## Troubleshooting

### Common Issues

#### Cache Not Working

```bash
# Clear cache (GitLab CI/CD Settings)
# Or force rebuild without cache
git commit --allow-empty -m "chore: rebuild cache"
```

#### Artifacts Not Found

```bash
# Check artifact paths in job output
# Verify artifact retention hasn't expired
# Check dependencies between jobs
```

#### Test Failures

```bash
# Download artifacts locally
# Review test logs
# Run tests locally with same environment
```

#### Deployment Issues

```bash
# Check environment variables are set
# Verify SSH keys are configured
# Test connectivity manually
# Review deployment logs
```

### Getting Help

1. Check pipeline logs in GitLab/GitHub
2. Review artifact outputs
3. Consult `scripts/ci/README.md`
4. Check component-specific documentation
5. Contact maintainers

## Maintenance

### Regular Tasks

**Weekly:**
- Review security scan results
- Update dependencies (via Dependabot)
- Check pipeline performance

**Monthly:**
- Rotate credentials
- Update base images
- Review and update CI scripts
- Archive old artifacts

**Quarterly:**
- Update CI/CD tools
- Review pipeline architecture
- Optimize caching strategy
- Update documentation

## Resources

- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Scripts README](../scripts/ci/README.md)
- [Project CLAUDE.md](../CLAUDE.md)

## Version History

- **v1.0** (2025-11-22) - Initial comprehensive CI/CD pipeline
  - 6-stage GitLab CI pipeline
  - GitHub Actions mirror with matrix builds
  - Security scanning (SAST, dependency, secrets)
  - Multi-platform packaging
  - Automated deployments
