# Threat Model - Academic Workflow Suite

## Overview

This document outlines the threat model for the Academic Workflow Suite, identifying potential security threats, attack vectors, and mitigation strategies.

## System Architecture

The Academic Workflow Suite consists of:

1. **Core Processing Engine** (Rust)
   - Assignment processing
   - AI grading
   - Feedback generation

2. **API Layer** (Elixir/Phoenix)
   - REST API endpoints
   - Authentication
   - Authorization

3. **Data Layer**
   - PostgreSQL database
   - File storage
   - Audit logs

4. **Container Environment**
   - Docker containers
   - Network isolation
   - Resource limits

## Assets

### Critical Assets

1. **Student Data**
   - Student IDs (hashed)
   - Submissions
   - Grades
   - Feedback
   - **Impact if compromised**: High - Privacy violation, GDPR breach

2. **Academic Integrity**
   - Grading algorithms
   - AI models
   - Assessment criteria
   - **Impact if compromised**: Critical - Unfair grading, loss of trust

3. **System Availability**
   - Processing capacity
   - API availability
   - Database integrity
   - **Impact if compromised**: Medium - Service disruption

4. **Audit Trail**
   - Operation logs
   - Access logs
   - Change history
   - **Impact if compromised**: High - Loss of accountability

## Threat Actors

### 1. Malicious Students
- **Motivation**: Grade manipulation, unauthorized access
- **Capability**: Low to Medium
- **Access**: Limited (authenticated users)

### 2. Insider Threats (Faculty/Staff)
- **Motivation**: Data theft, grade manipulation
- **Capability**: Medium to High
- **Access**: Elevated privileges

### 3. External Attackers
- **Motivation**: Data breach, system disruption
- **Capability**: Medium to High
- **Access**: None (must breach perimeter)

### 4. Automated Attacks
- **Motivation**: Exploitation at scale
- **Capability**: Variable
- **Access**: API endpoints

## Threat Scenarios

### T1: SQL Injection

**Threat**: Attacker injects malicious SQL to access or modify database

**Attack Vector**:
- User input fields
- API parameters
- Search queries

**Likelihood**: Medium
**Impact**: Critical

**Mitigation**:
- ✅ Use parameterized queries exclusively
- ✅ Input validation and sanitization
- ✅ Principle of least privilege for database users
- ✅ Regular SQL injection testing
- ✅ Web Application Firewall (WAF)

### T2: Cross-Site Scripting (XSS)

**Threat**: Attacker injects malicious JavaScript into web pages

**Attack Vector**:
- User-generated content
- Feedback comments
- Profile information

**Likelihood**: Medium
**Impact**: High

**Mitigation**:
- ✅ Output encoding/escaping
- ✅ Content Security Policy (CSP)
- ✅ HTTPOnly and Secure cookie flags
- ✅ Input validation
- ✅ Regular XSS testing

### T3: Authentication Bypass

**Threat**: Attacker gains unauthorized access

**Attack Vector**:
- JWT manipulation
- Session fixation
- Credential stuffing
- Brute force

**Likelihood**: Medium
**Impact**: Critical

**Mitigation**:
- ✅ Strong password requirements
- ✅ Multi-factor authentication (MFA)
- ✅ Rate limiting
- ✅ Secure session management
- ✅ JWT signature verification
- ✅ Account lockout policies

### T4: Container Escape

**Threat**: Attacker escapes container to access host system

**Attack Vector**:
- Privileged containers
- Docker socket exposure
- Kernel exploits
- Capability abuse

**Likelihood**: Low
**Impact**: Critical

**Mitigation**:
- ✅ Never run privileged containers
- ✅ Never expose Docker socket
- ✅ Use AppArmor/SELinux
- ✅ Drop all unnecessary capabilities
- ✅ Read-only root filesystem
- ✅ Non-root user execution
- ✅ Regular security updates

### T5: Data Exfiltration

**Threat**: Attacker steals sensitive student data

**Attack Vector**:
- Network access
- API abuse
- Database dump
- Log leakage

**Likelihood**: Medium
**Impact**: Critical

**Mitigation**:
- ✅ Network isolation (--network=none)
- ✅ Data encryption at rest
- ✅ Encryption in transit (TLS)
- ✅ Access logging and monitoring
- ✅ Data anonymization (hashed student IDs)
- ✅ Principle of least privilege
- ✅ Regular access audits

### T6: PII Leakage

**Threat**: Personal information exposed in logs or outputs

**Attack Vector**:
- Application logs
- Error messages
- AI-generated feedback
- Database exports

**Likelihood**: High
**Impact**: High

**Mitigation**:
- ✅ Automatic PII detection in CI/CD
- ✅ Hash all student IDs before logging
- ✅ Structured logging with PII filtering
- ✅ Output validation for AI content
- ✅ Regular PII leakage scans
- ✅ Log sanitization

### T7: Denial of Service (DoS)

**Threat**: System becomes unavailable due to resource exhaustion

**Attack Vector**:
- API flooding
- Resource-intensive requests
- Algorithmic complexity attacks
- Storage exhaustion

**Likelihood**: Medium
**Impact**: Medium

**Mitigation**:
- ✅ Rate limiting
- ✅ Request size limits
- ✅ Timeout enforcement
- ✅ Resource quotas
- ✅ Input validation
- ✅ Caching strategies
- ✅ Load balancing

### T8: Supply Chain Attack

**Threat**: Compromised dependencies introduce vulnerabilities

**Attack Vector**:
- Malicious npm/cargo packages
- Compromised package repositories
- Dependency confusion

**Likelihood**: Low
**Impact**: Critical

**Mitigation**:
- ✅ Dependency vulnerability scanning (cargo-audit, npm audit)
- ✅ License compliance checks
- ✅ Dependency pinning
- ✅ Private package registry
- ✅ Code review for dependencies
- ✅ Regular updates

### T9: Privilege Escalation

**Threat**: User gains higher privileges than authorized

**Attack Vector**:
- SUID binaries
- Sudo misconfiguration
- Capability abuse
- Path manipulation

**Likelihood**: Low
**Impact**: High

**Mitigation**:
- ✅ Remove unnecessary SUID binaries
- ✅ Minimal sudo permissions
- ✅ Drop capabilities
- ✅ Non-root execution
- ✅ Immutable filesystem where possible
- ✅ Regular privilege audits

### T10: Grade Manipulation

**Threat**: Unauthorized modification of student grades

**Attack Vector**:
- Direct database access
- API manipulation
- Logic bugs
- Insider threat

**Likelihood**: Medium
**Impact**: Critical

**Mitigation**:
- ✅ Comprehensive audit logging
- ✅ Access control enforcement
- ✅ Grade change approval workflow
- ✅ Database integrity constraints
- ✅ Anomaly detection
- ✅ Regular audits

## Security Controls Matrix

| Threat | Prevention | Detection | Response |
|--------|-----------|-----------|----------|
| SQL Injection | Parameterized queries, Input validation | WAF logs, IDS | Block request, Alert admin |
| XSS | Output encoding, CSP | Content scanning | Sanitize content, Alert |
| Auth Bypass | MFA, Rate limiting | Failed login monitoring | Lock account, Alert |
| Container Escape | Restricted capabilities, AppArmor | Host monitoring, IDS | Kill container, Investigate |
| Data Exfiltration | Network isolation, Encryption | Access logging, DLP | Block transfer, Investigate |
| PII Leakage | Hashing, Validation | PII detection scans | Redact, Rotate secrets |
| DoS | Rate limiting, Resource limits | Traffic monitoring | Throttle, Block IP |
| Supply Chain | Dependency scanning | Vulnerability alerts | Update, Patch |
| Privilege Escalation | Least privilege | Privilege monitoring | Terminate process, Alert |
| Grade Manipulation | Access control, Audit logs | Anomaly detection | Revert, Investigate |

## Assumptions

1. The underlying host OS is secure and patched
2. Physical security of servers is maintained
3. Personnel have received security training
4. Backups are secure and tested
5. Certificate management is properly handled

## Out of Scope

The following are considered out of scope for this threat model:

- Physical attacks on servers
- Social engineering of administrators
- Attacks on the network infrastructure
- Compromise of the development environment
- Third-party service vulnerabilities (we don't use third-party services)

## Security Testing Cadence

- **Automated**: Every commit (CI/CD pipeline)
- **Penetration Testing**: Quarterly
- **Dependency Scanning**: Weekly
- **Threat Model Review**: Bi-annually
- **Security Audit**: Annually

## Incident Response

See [INCIDENT_RESPONSE.md](./INCIDENT_RESPONSE.md) for detailed incident response procedures.

## Updates

This threat model is a living document and should be updated when:
- New features are added
- Architecture changes
- New threats are identified
- Security incidents occur
- Annually as part of security review

**Last Updated**: 2025-01-22
**Next Review**: 2025-07-22
