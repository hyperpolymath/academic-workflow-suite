;; SPDX-License-Identifier: AGPL-3.0-or-later
;; META.scm - Meta-level information for academic-workflow-suite
;; Media-Type: application/meta+scheme

(meta
  (architecture-decisions
    (adr-001
      (status "accepted")
      (date "2025-06-15")
      (title "Event Sourcing for Audit Trail")
      (context "GDPR requires complete audit trail of data processing. Universities need proof of compliance for student data handling.")
      (decision "Use event sourcing with LMDB as the primary storage pattern. All state changes recorded as immutable events.")
      (consequences
        (positive
          "Complete audit trail for GDPR compliance"
          "Time-travel debugging"
          "Reproducible past decisions"
          "Support for right to explanation")
        (negative
          "Increased storage requirements"
          "Complexity in event replay"
          "Migration challenges for schema evolution")))

    (adr-002
      (status "accepted")
      (date "2025-06-20")
      (title "SHA3-512 for Student ID Anonymization")
      (context "AI cannot see student PII. Need cryptographically strong irreversible anonymization.")
      (decision "Use SHA3-512 (FIPS 202) with random salt for student ID hashing. 2^512 search space makes brute-force infeasible.")
      (consequences
        (positive
          "Mathematical guarantee of irreversibility"
          "FIPS compliant for government/university requirements"
          "Constant-time implementation prevents timing attacks")
        (negative
          "Cannot recover original ID from hash alone"
          "Requires secure salt storage")))

    (adr-003
      (status "accepted")
      (date "2025-07-01")
      (title "Network-Isolated AI Container")
      (context "AI inference must not be able to exfiltrate student data. Even if AI is compromised, data must remain protected.")
      (decision "Run AI in Docker container with iptables DROP all, read-only filesystem, seccomp filtering, memory limits, gVisor sandboxing, Unix socket IPC only.")
      (consequences
        (positive
          "Zero network exfiltration risk"
          "Defense in depth"
          "Auditable security boundary")
        (negative
          "Cannot use cloud AI APIs"
          "Must bundle AI model locally"
          "Higher disk space requirements")))

    (adr-004
      (status "accepted")
      (date "2025-07-15")
      (title "ReScript for Office Add-in Frontend")
      (context "Office.js add-ins require JavaScript. TypeScript is banned per RSR policy. Need type-safe frontend code.")
      (decision "Use ReScript compiling to ES6 modules. Provides type safety without TypeScript dependency.")
      (consequences
        (positive
          "Type safety comparable to TypeScript"
          "Clean JavaScript output"
          "RSR compliant")
        (negative
          "Smaller community than TypeScript"
          "Learning curve for new contributors")))

    (adr-005
      (status "accepted")
      (date "2025-08-01")
      (title "Local-First Architecture")
      (context "Student data must never leave the tutor machine. Cloud services introduce privacy and compliance risks.")
      (decision "All core functionality runs locally. Optional backend (rubric repository, updates) never receives student data.")
      (consequences
        (positive
          "Complete data sovereignty"
          "Works offline"
          "No cloud vendor lock-in")
        (negative
          "No collaborative features in v1"
          "Manual updates required"
          "Higher local resource requirements")))

    (adr-006
      (status "accepted")
      (date "2025-09-01")
      (title "Post-Quantum Cryptography Support")
      (context "Quantum computers may break current cryptography. Academic data may need protection for decades.")
      (decision "Include post-quantum algorithms: Dilithium5 (ML-DSA-87) for signatures, Kyber-1024 (ML-KEM-1024) for key exchange.")
      (consequences
        (positive
          "Future-proof against quantum attacks"
          "Compliance with emerging standards")
        (negative
          "Larger key/signature sizes"
          "Performance overhead"))))

  (development-practices
    (code-style
      (rust "rustfmt + clippy (strict mode)")
      (rescript "ReScript formatter")
      (elixir "mix format + credo")
      (yaml "yamllint"))
    (security
      (principle "Defense in depth")
      (practices
        "Dependency scanning (Dependabot, cargo-audit)"
        "Container scanning (Trivy)"
        "Static analysis (Clippy, Credo)"
        "Property-based testing"
        "Continuous fuzzing"))
    (testing
      (unit "Comprehensive unit tests for all modules")
      (integration "Cross-component integration tests")
      (e2e "End-to-end tests with real Office documents")
      (property "Property-based testing with proptest/quickcheck")
      (fuzzing "cargo-fuzz for Rust components"))
    (versioning "SemVer")
    (documentation "AsciiDoc")
    (branching "main for stable, feature branches for development")
    (ci-cd "GitHub Actions with SHA-pinned dependencies"))

  (design-rationale
    (why-event-sourcing
      "GDPR Article 17 (Right to Erasure) and Article 22 (Right to Explanation) require complete audit trails. Event sourcing provides this by default while also enabling time-travel debugging and replay capabilities.")
    (why-lmdb
      "Lightning Memory-Mapped Database provides ACID transactions with excellent read performance. Perfect for event stores where writes are append-only and reads dominate.")
    (why-rust
      "Memory safety without garbage collection. Critical for security-sensitive code handling student data. Also provides excellent FFI for WASM/NIF.")
    (why-local-first
      "University data protection policies prohibit sending student PII to cloud services. Local-first architecture ensures compliance regardless of institution-specific policies.")
    (why-agpl
      "AGPL ensures the software remains free and open. If anyone modifies AWS for a web service, they must share improvements with the community.")))
