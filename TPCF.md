# Tri-Perimeter Contribution Framework (TPCF)

**Version**: 1.0
**Status**: Active
**Project**: Academic Workflow Suite
**Current Level**: Perimeter 2 (Trusted Contributors)

---

## Overview

The **Tri-Perimeter Contribution Framework (TPCF)** is a graduated trust model for open-source governance that balances openness with security. It defines three concentric perimeters of contribution access, each with increasing trust requirements and capabilities.

### Rationale

Traditional open-source models face a tension:
- **Fully open**: Anyone can contribute, but security risks increase
- **Closed core**: Secure but limits community growth and innovation

TPCF resolves this by creating graduated trust zones:
- **Perimeter 3 (Sandbox)**: Open community participation
- **Perimeter 2 (Trusted)**: Proven contributors with expanded access
- **Perimeter 1 (Core)**: Maintainers with full control

This enables **safe openness**: newcomers can contribute safely in sandboxed areas, while critical systems require demonstrated trust.

---

## Three Perimeters

### Perimeter 3: Community Sandbox (Open)

**Trust Level**: None required (anonymous welcome)
**Access**: Read all, write limited
**Security**: Sandboxed, high scrutiny

#### What You Can Do

✅ **Issues & Discussions**
- Report bugs
- Request features
- Ask questions
- Participate in design discussions

✅ **Documentation Contributions**
- Fix typos
- Improve clarity
- Add examples
- Translate content

✅ **Test Contributions**
- Add test cases
- Report test failures
- Improve test coverage

✅ **Community Support**
- Answer questions in discussions
- Help other users
- Share use cases

#### What You Cannot Do

❌ **Direct Code Changes**
- No direct commits to core components
- No merge privileges
- No release permissions

❌ **Security-Sensitive Changes**
- No cryptography modifications
- No authentication/authorization changes
- No privacy-critical alterations

#### Contribution Process

1. **Fork** the repository
2. **Make changes** in your fork
3. **Submit PR** with detailed description
4. **Automated checks** run (CI/CD)
5. **Maintainer review** (Perimeter 1/2)
6. **Feedback** and requested changes
7. **Approval** and merge by maintainer

#### Security Measures

- All PRs from Perimeter 3 reviewed by 2+ Perimeter 1 maintainers
- Automated security scanning (Clippy, cargo-audit, Semgrep)
- Test suite must pass (100% coverage maintained)
- GPG-signed commits encouraged
- CLA/DCO required for legal clarity

---

### Perimeter 2: Trusted Contributors

**Trust Level**: Demonstrated expertise (3+ merged PRs, 6+ months)
**Access**: Write to non-critical components
**Security**: Reviewed, moderate scrutiny

#### How to Qualify

**Automatic Criteria** (all must be met):
1. **3+ merged pull requests** to main branch
2. **6+ months** of sustained contribution
3. **Zero Code of Conduct violations**
4. **High-quality code** (passes review on first/second iteration)

**Discretionary Criteria** (2+ recommended):
- Domain expertise in relevant technology (Rust, Elixir, ReScript)
- Security awareness (threat modeling, secure coding)
- Community leadership (mentoring, support)
- Documentation excellence

#### Additional Privileges

✅ **Component Ownership**
- Assigned ownership of specific subsystems
- Review PRs for your component
- Propose architectural changes
- Backport fixes to release branches

✅ **Reduced Review Burden**
- Single maintainer review (instead of 2)
- Trusted for documentation changes
- Can approve Perimeter 3 PRs (with supervision)

✅ **Release Participation**
- Test release candidates
- Contribute to release notes
- Participate in release planning

#### Responsibilities

- **Code Quality**: Maintain high standards in contributions
- **Security Vigilance**: Report vulnerabilities immediately
- **Mentorship**: Help Perimeter 3 contributors improve
- **Code Review**: Review others' PRs constructively
- **Availability**: Respond to component issues within 7 days

#### Revocation

Perimeter 2 status may be revoked if:
- Inactivity for 12+ months
- Code of Conduct violation
- Security incident caused by negligence
- Repeated low-quality contributions

Revocation process:
1. Private notification from maintainers
2. 30-day grace period to respond
3. Decision by Perimeter 1 consensus
4. Optional appeal to steering committee

---

### Perimeter 1: Core Maintainers

**Trust Level**: Full trust (maintainer status)
**Access**: All repositories, all permissions
**Security**: Highest scrutiny, accountability

#### How to Qualify

**By Invitation Only** - Criteria:
1. **Perimeter 2 status** for 12+ months
2. **Deep technical expertise** in core systems
3. **Sustained contribution** (regular commits, reviews)
4. **Security track record** (no vulnerabilities introduced)
5. **Community leadership** (mentorship, conflict resolution)
6. **Consensus approval** from existing Perimeter 1 maintainers

#### Full Privileges

✅ **Repository Control**
- Merge to main branch
- Create releases
- Manage branches and tags
- Configure CI/CD

✅ **Governance Participation**
- Vote on project direction
- Approve/reject feature proposals
- Select new maintainers
- Modify TPCF itself

✅ **Security Authority**
- Access to security vulnerability reports
- Emergency patch deployment
- Security disclosure coordination

✅ **Community Moderation**
- Enforce Code of Conduct
- Ban abusive users
- Resolve disputes

#### Responsibilities

- **Availability**: Respond to critical issues within 24 hours
- **Code Review**: Review PRs from all perimeters
- **Release Management**: Coordinate releases, ensure quality
- **Security Response**: Handle vulnerabilities, coordinate patches
- **Community Leadership**: Set tone, resolve conflicts, mentor
- **Transparency**: Document decisions, communicate clearly

#### Accountability

Perimeter 1 maintainers are accountable to:
- **Community**: Via public roadmap, transparent decision-making
- **Security**: Via responsible disclosure, timely patches
- **Legal**: Via compliance with licenses, data protection laws
- **Ethics**: Via Code of Conduct, community health

#### Stepping Down

Maintainers may step down gracefully:
1. Notify other maintainers privately (2+ weeks notice)
2. Transfer active responsibilities
3. Move to Emeritus Maintainer status
4. Public announcement (optional)

---

## TPCF Compliance: Academic Workflow Suite

### Current Configuration

**Overall Level**: Perimeter 2 (Trusted Contributors)

| Component | Perimeter Level | Rationale |
|-----------|----------------|-----------|
| **Core Engine (Rust)** | Perimeter 1 | Cryptography, anonymization (high security) |
| **AI Jail (Rust)** | Perimeter 1 | Network isolation, security-critical |
| **Backend (Elixir)** | Perimeter 2 | Business logic, lower risk |
| **Office Add-in (ReScript)** | Perimeter 2 | Frontend, sandboxed by browser |
| **Documentation** | Perimeter 3 | Open contribution, low risk |
| **Tests** | Perimeter 3 | Open contribution, validated by CI |
| **Examples** | Perimeter 3 | Educational, non-critical |
| **Configuration** | Perimeter 2 | Affects behavior but not security-critical |

### Escalation Paths

**Perimeter 3 → Perimeter 2**: After 3+ merged PRs, 6+ months
**Perimeter 2 → Perimeter 1**: By invitation, consensus vote

### Security Measures by Perimeter

| Security Control | P3 | P2 | P1 |
|------------------|----|----|---- |
| **2-person review** | ✅ Required | ❌ Not required | ❌ Not required |
| **GPG signing** | Encouraged | ✅ Required | ✅ Required |
| **Security training** | Recommended | ✅ Required | ✅ Required |
| **Background check** | ❌ | ❌ | Optional (for sensitive data access) |
| **Audit logging** | ✅ All actions | ✅ All actions | ✅ All actions |

---

## Governance

### Decision-Making

**Perimeter 1 Decisions** (Consensus):
- Major architectural changes
- New maintainer selection
- TPCF modifications
- Security policy changes

**Perimeter 2 Decisions** (Component-level):
- Component refactoring
- Dependency updates
- Feature implementation

**Perimeter 3 Input** (Advisory):
- Feature requests
- Bug reports
- Use case discussions

### Conflict Resolution

1. **Discussion**: Try to resolve via respectful dialogue
2. **Mediation**: Neutral Perimeter 1 maintainer mediates
3. **Vote**: Perimeter 1 consensus vote (if no resolution)
4. **Appeal**: Steering committee (if established)

### Code of Conduct Enforcement

Violations handled by Perimeter 1 maintainers:
1. **Warning**: First offense (minor)
2. **Temporary Ban**: Repeat or moderate offense (7-30 days)
3. **Permanent Ban**: Severe or repeated violations
4. **Appeal**: Via conduct@academic-workflow-suite.org

---

## Comparison to Other Models

### vs. Fully Open (e.g., Linux Kernel)

| Aspect | Fully Open | TPCF |
|--------|-----------|------|
| **Barrier to entry** | Low | Low (P3) |
| **Security review** | High scrutiny all | Graduated by perimeter |
| **Maintainer burden** | Very high | Moderate |
| **Trust requirement** | Earned over time | Explicit levels |

### vs. Closed Core (e.g., GitLab)

| Aspect | Closed Core | TPCF |
|--------|-------------|------|
| **Community contribution** | Limited | Open (P3) |
| **Innovation** | Company-driven | Community + Core |
| **Security** | Proprietary | Transparent |
| **Trust model** | Employee-based | Merit-based |

### TPCF Advantages

✅ **Graduated trust**: Newcomers welcome, critical systems protected
✅ **Explicit expectations**: Clear path to maintainer status
✅ **Security-conscious**: Defense-in-depth by design
✅ **Community growth**: Open Perimeter 3 drives adoption
✅ **Sustainable**: Reduces maintainer burnout

---

## Implementation Checklist

### Project Setup

- [x] TPCF.md created (this document)
- [x] MAINTAINERS.md lists Perimeter 1
- [ ] CONTRIBUTING.md references TPCF
- [x] CODE_OF_CONDUCT.md enforced
- [ ] CI/CD enforces perimeter rules

### GitHub/GitLab Configuration

- [ ] Branch protection rules:
  - `main`: Perimeter 1 only
  - `develop`: Perimeter 2+
  - `sandbox/*`: Perimeter 3
- [ ] CODEOWNERS file by component
- [ ] Issue templates for Perimeter 3
- [ ] PR templates with perimeter checklist

### Documentation

- [ ] Badge in README.md: "TPCF Perimeter 2"
- [ ] Contribution guide explains perimeters
- [ ] Onboarding doc for Perimeter 2/3

### Legal

- [ ] CLA or DCO for all contributors
- [ ] License compatibility verified (AGPL-3.0)
- [ ] Privacy policy for contributor data

---

## Future Enhancements

### Automated Perimeter Tracking

Develop tooling to:
- Track contributor status automatically
- Notify when Perimeter 2 criteria met
- Generate perimeter reports

### Perimeter 2.5 (Specialized Trust)

Add intermediate level:
- **Domain Experts**: Specific expertise (e.g., cryptography)
- **Limited Scope**: Write access to specific directories only
- **No Merge**: Can approve, but not merge

### Steering Committee

As project grows:
- **Composition**: 5-7 Perimeter 1 maintainers
- **Role**: Governance oversight, conflict resolution
- **Elections**: Annual, by Perimeter 2+ vote

---

## References

- **Contributor Covenant**: Code of Conduct model
- **Apache Foundation**: Meritocracy-based governance
- **Kubernetes**: SIG structure inspiration
- **Signal Protocol**: Security-conscious development
- **TPCF Origin**: Academic Workflow Suite innovation

---

## Contact

- **TPCF Questions**: governance@academic-workflow-suite.org
- **Perimeter 2 Nomination**: maintainers@academic-workflow-suite.org
- **Security Concerns**: security@academic-workflow-suite.org

---

**Last Updated**: 2025-11-22
**Version**: 1.0
**Status**: Active
**Review Cycle**: Annual (November)
