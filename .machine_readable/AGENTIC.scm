;; SPDX-License-Identifier: AGPL-3.0-or-later
;; AGENTIC.scm - AI agent interaction patterns for academic-workflow-suite

(define agentic-config
  `((version . "1.0.0")
    (claude-code
      ((model . "claude-opus-4-5-20251101")
       (tools . ("read" "edit" "bash" "grep" "glob"))
       (permissions . "read-all")))

    (patterns
      ((code-review
         (style . "thorough")
         (focus-areas
           "Privacy vulnerabilities"
           "Student data handling"
           "Cryptographic implementation"
           "Event sourcing correctness"
           "IPC protocol safety"))
       (refactoring
         (style . "conservative")
         (priorities
           "Maintain privacy guarantees"
           "Preserve audit trail"
           "No behavioral changes without tests"))
       (testing
         (style . "comprehensive")
         (requirements
           "Property-based tests for crypto"
           "Integration tests for IPC"
           "E2E tests for document handling"))))

    (constraints
      ((languages
         (allowed
           "Rust" "ReScript" "Elixir" "Bash" "Nickel")
         (banned
           "TypeScript" "Go" "Python" "Makefile"))
       (security
         "Never log student IDs"
         "Always anonymize before AI processing"
         "Network isolation must be verified"
         "Event store must be append-only")
       (architecture
         "Prefer local-first solutions"
         "Avoid cloud dependencies"
         "Keep AI in isolated container")))

    (interaction-guidelines
      ((document-handling
         "Parse documents using Office.js APIs"
         "Extract student ID from metadata"
         "Anonymize before analysis request")
       (feedback-generation
         "Use rubric as primary context"
         "Generate constructive suggestions"
         "Allow tutor override always")
       (audit-trail
         "Log all analysis requests"
         "Record all tutor edits"
         "Never delete events")))))
