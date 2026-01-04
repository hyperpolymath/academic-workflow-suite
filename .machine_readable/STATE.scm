;;  SPDX-License-Identifier: AGPL-3.0-or-later
;; STATE.scm - Project state for academic-workflow-suite
;; Media-Type: application/vnd.state+scm

(state
  (metadata
    (version "0.1.0")
    (schema-version "1.0")
    (created "2025-11-22")
    (updated "2026-01-04")
    (project "academic-workflow-suite")
    (repo "github.com/hyperpolymath/academic-workflow-suite"))

  (project-context
    (name "Academic Workflow Suite")
    (tagline "Privacy-First AI-Assisted TMA Marking for OU Associate Lecturers")
    (tech-stack
      (primary
        (backend "Rust (Actix-Web, Tokio)")
        (frontend "ReScript (Office.js)")
        (database "LMDB (via Heed)")
        (ai-runtime "ONNX Runtime, llama.cpp")
        (optional-backend "Elixir/Phoenix")
        (containerization "Docker/Podman, gVisor"))
      (cryptography
        (hashing "SHA3-512 (FIPS 202), BLAKE3")
        (encryption "AES-256-GCM")
        (post-quantum "Dilithium5, Kyber-1024"))))

  (current-position
    (phase "beta")
    (overall-completion 65)
    (components
      (core-engine
        (status "functional")
        (completion 80)
        (features
          "Event sourcing with LMDB"
          "TMA parsing and processing"
          "SHA3-512 anonymization"
          "IPC communication with AI jail"))
      (office-addin
        (status "functional")
        (completion 70)
        (features
          "Task pane UI in Word"
          "Document manipulation via Office.js"
          "Feedback insertion"
          "Rubric-based scoring"))
      (ai-jail
        (status "functional")
        (completion 75)
        (features
          "Network-isolated container"
          "ONNX Runtime inference"
          "Unix socket IPC"
          "gVisor sandboxing"))
      (backend
        (status "scaffolded")
        (completion 40)
        (features
          "Phoenix framework setup"
          "Rubric repository API"
          "Optional cloud sync"))
      (cli
        (status "functional")
        (completion 70)
        (features
          "Start/stop services"
          "Batch processing"
          "Configuration management"
          "Health diagnostics"))
      (shared-library
        (status "stable")
        (completion 85)
        (features
          "Cryptographic primitives"
          "Validation utilities"
          "Sanitization"
          "Logging infrastructure")))
    (working-features
      "TMA document loading and parsing"
      "Student ID anonymization (SHA3-512)"
      "AI-assisted feedback generation"
      "Rubric-based scoring"
      "Event sourcing audit trail"
      "PDF/DOCX export"
      "CLI interface"
      "Network-isolated AI inference"))

  (route-to-mvp
    (milestones
      (v0.1.0
        (name "Initial Beta Release")
        (status "completed")
        (items
          "Core engine with event sourcing"
          "Office Add-in for Word"
          "AI isolation with Docker/gVisor"
          "SHA3-512 anonymization"
          "LMDB event store"
          "Basic rubric support"
          "CLI interface"
          "Documentation"))
      (v0.2.0
        (name "Moodle Integration")
        (status "in-progress")
        (target "Q1 2026")
        (items
          "Direct submission download from Moodle"
          "Automated grade upload"
          "Batch processing improvements"
          "Advanced analytics dashboard"))
      (v0.3.0
        (name "Collaboration Features")
        (status "planned")
        (target "Q2 2026")
        (items
          "Collaborative marking"
          "Plagiarism detection (Turnitin API)"
          "Grade moderation"
          "Student progress tracking"))
      (v1.0.0
        (name "Production Release")
        (status "planned")
        (target "2026")
        (items
          "Browser extension"
          "Automated grading for objective questions"
          "Research analytics"))))

  (blockers-and-issues
    (critical)
    (high
      (moodle-api
        (description "Moodle LMS API integration pending")
        (impact "Cannot auto-download submissions")))
    (medium
      (mobile-app
        (description "Mobile app development not started")
        (impact "No on-the-go review capability")))
    (low
      (multilingual
        (description "AI models English-only")
        (impact "Limited to English TMAs"))))

  (critical-next-actions
    (immediate
      "Complete Moodle OAuth integration"
      "Implement batch download API")
    (this-week
      "Design analytics dashboard wireframes"
      "Write integration tests for Moodle API")
    (this-month
      "Release v0.2.0 beta"
      "Begin mobile app architecture"))

  (session-history
    (session
      (date "2026-01-04")
      (accomplishments
        "Populated SCM files with comprehensive project metadata"
        "Documented architecture and component status"))))
