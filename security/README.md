# Security Testing Infrastructure

Comprehensive security testing suite for the Academic Workflow Suite, ensuring university-grade security standards.

## Overview

This directory contains automated security testing tools covering:

- **Dependency auditing** - Vulnerability scanning across all ecosystems
- **License compliance** - GPL compatibility verification
- **Secret scanning** - Detection of hardcoded credentials
- **Penetration testing** - API fuzzing, injection tests, auth bypass
- **Container security** - Escape attempts, privilege escalation
- **Privacy testing** - PII detection, anonymization verification
- **GDPR compliance** - Data flow audit, retention policies
- **Static analysis** - Clippy, Semgrep, CodeQL
- **Dynamic analysis** - Fuzzing, memory safety, sanitizers
- **Security reporting** - Aggregated security reports

## Quick Start

### Run All Security Tests

```bash
# Run complete security audit
./run_all_security_tests.sh

# Generate security report
python3 ./reporting/generate_security_report.py
```

### Run Specific Test Categories

```bash
# Dependency and license audits
./audit-scripts/dependency-audit.sh
./audit-scripts/license-check.sh
./audit-scripts/secret-scan.sh

# Penetration testing
./penetration-testing/api-fuzzing/sql_injection_tests.sh
./penetration-testing/api-fuzzing/xss_tests.sh
./penetration-testing/api-fuzzing/auth_bypass_tests.sh

# Container security
./penetration-testing/container-escape/escape_attempts.sh
./penetration-testing/container-escape/privilege_escalation.sh
./penetration-testing/container-escape/network_isolation_verify.sh

# Privacy and GDPR
./privacy-testing/pii-detection/anonymization_verification.sh
./compliance/gdpr/data_flow_audit.sh
```

## Directory Structure

```
security/
├── audit-scripts/              # Dependency, license, and secret scanning
│   ├── dependency-audit.sh     # Rust, Elixir, Node.js vulnerability scanning
│   ├── license-check.sh        # GPL compatibility verification
│   └── secret-scan.sh          # Hardcoded secret detection
│
├── penetration-testing/        # Security penetration tests
│   ├── api-fuzzing/           # API security testing
│   │   ├── fuzz_api.py        # Atheris-based API fuzzing
│   │   ├── sql_injection_tests.sh
│   │   ├── xss_tests.sh
│   │   └── auth_bypass_tests.sh
│   └── container-escape/      # Container breakout tests
│       ├── escape_attempts.sh
│       ├── privilege_escalation.sh
│       ├── network_isolation_verify.sh
│       └── filesystem_access.sh
│
├── privacy-testing/           # Privacy and PII protection
│   └── pii-detection/
│       ├── pii_leakage_tests.rs
│       ├── anonymization_verification.sh
│       ├── output_validation_tests.rs
│       └── audit_trail_verification.sh
│
├── compliance/                # Regulatory compliance
│   └── gdpr/
│       ├── data_flow_audit.sh
│       ├── retention_policy_check.sh
│       ├── right_to_erasure_test.sh
│       └── data_portability_test.sh
│
├── static-analysis/          # Static code analysis
│   ├── run_clippy.sh         # Rust linting
│   ├── run_semgrep.sh        # SAST scanning
│   ├── run_codeql.sh         # GitHub security analysis
│   └── custom_rules.yaml     # Custom security rules
│
├── dynamic-analysis/         # Runtime security testing
│   ├── fuzz_core.sh         # Fuzzing tests
│   ├── memory_safety.sh     # Memory leak detection
│   ├── race_condition_tests.sh
│   └── sanitizer_tests.sh   # ASan/TSan/MSan
│
├── reporting/               # Security reporting
│   └── generate_security_report.py
│
├── policies/               # Security policies
│   ├── SECURITY_POLICY.md
│   ├── THREAT_MODEL.md
│   └── INCIDENT_RESPONSE.md
│
└── README.md              # This file
```

## Test Descriptions

### 1. Audit Scripts

#### Dependency Audit (`dependency-audit.sh`)

Scans for known vulnerabilities in dependencies across all ecosystems.

**Checks:**
- Rust: `cargo audit`
- Elixir: `mix hex.audit`
- Node.js: `npm audit`

**Exit Codes:**
- `0`: No vulnerabilities
- `1`: Critical or high severity vulnerabilities found

**Example:**
```bash
./audit-scripts/dependency-audit.sh
# Report: security/reports/dependency-audit/audit_TIMESTAMP.json
```

#### License Check (`license-check.sh`)

Verifies all dependencies use GPL-compatible licenses.

**Checks:**
- MIT, Apache-2.0, BSD licenses (compatible)
- AGPL, proprietary licenses (flagged)
- Unknown licenses (warned)

**Example:**
```bash
./audit-scripts/license-check.sh
# Report: security/reports/license-audit/license_TIMESTAMP.txt
```

#### Secret Scan (`secret-scan.sh`)

Detects hardcoded secrets, API keys, and credentials.

**Tools Used:**
- Pattern matching (regex)
- Gitleaks (if available)
- TruffleHog (if available)

**Detects:**
- AWS keys
- GitHub tokens
- API keys
- Passwords
- Private keys
- Database credentials

**Example:**
```bash
./audit-scripts/secret-scan.sh
# Report: security/reports/secret-scan/secrets_TIMESTAMP.txt
```

### 2. Penetration Testing

#### API Fuzzing (`fuzz_api.py`)

Automated fuzzing of API endpoints using Atheris.

**Tests:**
- SQL injection payloads
- XSS payloads
- Path traversal
- Large payload DoS
- Malformed requests

**Usage:**
```bash
# Manual mode (recommended for CI)
python3 ./penetration-testing/api-fuzzing/fuzz_api.py --manual

# Continuous fuzzing mode
python3 ./penetration-testing/api-fuzzing/fuzz_api.py
```

#### SQL Injection Tests (`sql_injection_tests.sh`)

Comprehensive SQL injection testing.

**Tests:**
- Classic SQL injection
- Blind SQL injection
- Time-based SQL injection
- UNION-based injection
- Error-based injection

**Integration:**
- sqlmap (if available)

**Example:**
```bash
API_BASE_URL=http://localhost:8000 \
  ./penetration-testing/api-fuzzing/sql_injection_tests.sh
```

#### XSS Tests (`xss_tests.sh`)

Cross-site scripting vulnerability testing.

**Tests:**
- Reflected XSS
- Stored XSS
- DOM-based XSS
- Filter bypass techniques
- Polyglot payloads

**Example:**
```bash
./penetration-testing/api-fuzzing/xss_tests.sh
```

#### Authentication Bypass (`auth_bypass_tests.sh`)

Tests authentication and authorization mechanisms.

**Tests:**
- Unauthenticated access
- Invalid tokens
- Parameter manipulation
- HTTP method bypass
- IDOR vulnerabilities
- Session fixation
- JWT vulnerabilities
- Rate limiting

### 3. Container Security

#### Container Escape Tests (`escape_attempts.sh`)

Tests for container breakout vulnerabilities.

**Checks:**
- Privileged mode
- Docker socket exposure
- Dangerous capabilities (CAP_SYS_ADMIN)
- Host path mounts
- Kernel access
- AppArmor/SELinux profiles

**Should be run inside container:**
```bash
docker exec <container> ./security/penetration-testing/container-escape/escape_attempts.sh
```

#### Privilege Escalation (`privilege_escalation.sh`)

Tests for privilege escalation vectors.

**Checks:**
- SUID binaries
- Writable privileged files
- Sudo permissions
- Cron job manipulation
- Docker group membership
- /etc/passwd writability

#### Network Isolation (`network_isolation_verify.sh`)

Verifies network is properly disabled.

**Tests:**
- Network interface check
- External connectivity attempts
- DNS resolution
- HTTP/HTTPS access
- Localhost verification

**Expected:** All external access should fail.

#### Filesystem Access (`filesystem_access.sh`)

Tests filesystem access boundaries.

**Checks:**
- Read-only root filesystem
- Sensitive path mounts
- World-writable files
- noexec on writable partitions
- Symlink protection

### 4. Privacy Testing

#### PII Leakage Tests (`pii_leakage_tests.rs`)

Rust-based PII detection in code and outputs.

**Detects:**
- Email addresses
- Phone numbers
- Social Security Numbers
- Student IDs
- Credit card numbers
- IP addresses

**Build and run:**
```bash
cd privacy-testing/pii-detection
rustc pii_leakage_tests.rs
./pii_leakage_tests
```

#### Anonymization Verification (`anonymization_verification.sh`)

Verifies student IDs are properly hashed.

**Checks:**
- Plain-text IDs in logs
- Proper SHA-256 hash format
- Deterministic hashing
- PII in database exports

#### Output Validation (`output_validation_tests.rs`)

Validates AI-generated content doesn't contain PII.

**Tests:**
- Feedback text validation
- Automated PII detection
- Batch output processing

### 5. GDPR Compliance

#### Data Flow Audit (`data_flow_audit.sh`)

Maps all data flows in the system.

**Documents:**
- Data collection points
- Processing activities
- Storage locations
- Data transfers (none - network disabled)

#### Retention Policy Check (`retention_policy_check.sh`)

Verifies data retention compliance.

**Policies:**
- Student records: 7 years
- Audit logs: 2 years
- Temporary data: 30 days

#### Right to Erasure (`right_to_erasure_test.sh`)

Tests GDPR "right to be forgotten" implementation.

**Verifies:**
- Data deletion from primary storage
- Backup removal
- Log anonymization
- Audit trail maintenance

#### Data Portability (`data_portability_test.sh`)

Tests GDPR data export capabilities.

**Verifies:**
- JSON export format
- Data completeness
- Machine-readable format
- PII anonymization

### 6. Static Analysis

#### Clippy (`run_clippy.sh`)

Rust linter with strict security rules.

**Checks:**
- Security anti-patterns
- Unwrap/expect usage
- Panic conditions
- Missing error handling
- Code quality

**Usage:**
```bash
cd ../../  # Project root
./security/static-analysis/run_clippy.sh
```

#### Semgrep (`run_semgrep.sh`)

SAST (Static Application Security Testing).

**Rules:**
- OWASP Top 10
- Secret detection
- Custom security rules
- Language-specific patterns

**Installation:**
```bash
pip install semgrep
```

#### CodeQL (`run_codeql.sh`)

GitHub's semantic code analysis.

**Note:** Typically run in GitHub Actions.

### 7. Dynamic Analysis

#### Fuzzing (`fuzz_core.sh`)

Fuzzing with cargo-fuzz.

**Requires:**
```bash
cargo install cargo-fuzz
```

#### Memory Safety (`memory_safety.sh`)

Valgrind-based memory leak detection.

**Requires:**
```bash
apt-get install valgrind
```

#### Race Conditions (`race_condition_tests.sh`)

ThreadSanitizer for concurrency bugs.

**Requires:** Nightly Rust

#### Sanitizers (`sanitizer_tests.sh`)

Runs all sanitizers:
- AddressSanitizer (ASan)
- ThreadSanitizer (TSan)
- MemorySanitizer (MSan)

### 8. Security Reporting

#### Generate Security Report (`generate_security_report.py`)

Aggregates all test results into comprehensive reports.

**Outputs:**
- HTML report (visual)
- JSON report (machine-readable)
- Console summary

**Installation:**
```bash
pip install jinja2
```

**Usage:**
```bash
python3 ./reporting/generate_security_report.py
# Output: /tmp/security_report_TIMESTAMP.html
#         /tmp/security_report_TIMESTAMP.json
```

## CI/CD Integration

### GitLab CI Example

```yaml
security_audit:
  stage: test
  script:
    - ./security/audit-scripts/dependency-audit.sh
    - ./security/audit-scripts/license-check.sh
    - ./security/audit-scripts/secret-scan.sh
    - python3 ./security/reporting/generate_security_report.py
  artifacts:
    reports:
      - /tmp/security_report_*.html
    when: always
  allow_failure: false
```

### GitHub Actions Example

```yaml
name: Security Audit

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Run Security Tests
        run: |
          ./security/audit-scripts/dependency-audit.sh
          ./security/audit-scripts/secret-scan.sh

      - name: Generate Report
        run: |
          pip install jinja2
          python3 ./security/reporting/generate_security_report.py

      - name: Upload Report
        uses: actions/upload-artifact@v2
        with:
          name: security-report
          path: /tmp/security_report_*.html
```

## Security Standards

This testing infrastructure ensures compliance with:

- **OWASP Top 10** - Web application security risks
- **GDPR** - Privacy and data protection
- **CIS Docker Benchmark** - Container security
- **NIST Cybersecurity Framework** - Security controls
- **Academic Data Privacy** - Student information protection

## Exit Codes

All scripts use consistent exit codes:

- `0` - All tests passed
- `1` - Critical/High severity issues found
- `2` - Medium/Low severity issues or warnings

## Troubleshooting

### Common Issues

**"Tool not found" errors:**
```bash
# Install required tools
cargo install cargo-audit cargo-license cargo-fuzz
pip install atheris semgrep jinja2
apt-get install valgrind gitleaks
```

**Permission denied:**
```bash
chmod +x security/**/*.sh
```

**Container tests fail:**
```bash
# Run inside container
docker exec <container_name> /path/to/test.sh
```

## Best Practices

1. **Run before every commit**
   ```bash
   ./security/audit-scripts/dependency-audit.sh
   ./security/audit-scripts/secret-scan.sh
   ```

2. **Weekly comprehensive scan**
   ```bash
   ./run_all_security_tests.sh
   python3 ./security/reporting/generate_security_report.py
   ```

3. **Before production deployment**
   - Run all penetration tests
   - Verify container security
   - Check GDPR compliance
   - Generate and review security report

4. **After dependency updates**
   ```bash
   ./security/audit-scripts/dependency-audit.sh
   ./security/audit-scripts/license-check.sh
   ```

## Security Policies

See the `policies/` directory for:

- [SECURITY_POLICY.md](./policies/SECURITY_POLICY.md) - Vulnerability disclosure
- [THREAT_MODEL.md](./policies/THREAT_MODEL.md) - Threat analysis
- [INCIDENT_RESPONSE.md](./policies/INCIDENT_RESPONSE.md) - Incident procedures

## Reporting Vulnerabilities

If you discover a security vulnerability, please follow our [Security Policy](./policies/SECURITY_POLICY.md).

**DO NOT** open public issues for security vulnerabilities.

Contact: security@academic-workflow-suite.example.com

## License

The security testing infrastructure is part of the Academic Workflow Suite and follows the same license (GPL-3.0).

## Maintenance

**Regular Updates:**
- Security tools: Monthly
- Test payloads: Quarterly
- Threat model: Bi-annually
- Policies: Annually

**Monitoring:**
- Dependency vulnerabilities: Continuous
- New attack vectors: Continuous
- Security advisories: Continuous

## Resources

- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [GDPR Guide](https://gdpr.eu/)

## Support

For questions about security testing:
- Documentation: This README
- Issues: GitHub Issues (non-security)
- Security: security@academic-workflow-suite.example.com

---

**Last Updated:** 2025-01-22
**Maintained by:** Security Team
