;; SPDX-License-Identifier: AGPL-3.0-or-later
;; ECOSYSTEM.scm - Ecosystem position for academic-workflow-suite
;; Media-Type: application/vnd.ecosystem+scm

(ecosystem
  (version "1.0")
  (name "Academic Workflow Suite")
  (type "privacy-first-ai-education-tool")
  (purpose "Reduce TMA marking time for OU Associate Lecturers while maintaining GDPR compliance and student privacy through local-first AI assistance.")

  (position-in-ecosystem
    (category "Education Technology")
    (subcategory "AI-Assisted Assessment")
    (unique-value
      "First open-source TMA marking assistant with mathematically guaranteed privacy via SHA3-512 anonymization and network-isolated AI inference."))

  (related-projects
    (sibling-standard
      (bunsenite
        (relationship "shares cryptographic infrastructure")
        (description "Nickel-based configuration management with post-quantum crypto"))
      (januskey
        (relationship "authentication and key management")
        (description "Post-quantum authentication standard"))
      (rhodium-standard-repositories
        (relationship "repository governance patterns")
        (description "Standard templates for hyperpolymath repositories")))

    (potential-consumer
      (moodle
        (relationship "LMS integration target")
        (description "Open-source learning management system for OU")
        (integration-status "planned for v0.2.0"))
      (turnitin
        (relationship "plagiarism detection integration")
        (description "Academic integrity platform")
        (integration-status "planned for v0.3.0")))

    (inspiration
      (llama-cpp
        (relationship "AI inference runtime")
        (description "Local LLM inference engine"))
      (onnx-runtime
        (relationship "AI model runtime")
        (description "Cross-platform ML inference engine"))
      (lmdb
        (relationship "storage backend")
        (description "Lightning Memory-Mapped Database for event sourcing"))))

  (what-this-is
    "An open-source, privacy-first AI assistant for marking Tutor-Marked Assignments"
    "A local-first application that never sends student data to cloud services"
    "An event-sourced system with complete audit trail for GDPR compliance"
    "A Microsoft Word add-in with AI-powered feedback suggestions"
    "A CLI tool for batch processing multiple TMAs"
    "A GDPR-compliant solution approved for university use")

  (what-this-is-not
    "Not a replacement for tutor judgment - AI assists, tutors decide"
    "Not a cloud service - all processing happens locally"
    "Not an automated grading system - human remains in the loop"
    "Not a plagiarism detection tool - that integration is planned separately"
    "Not a student-facing application - designed for tutors only"
    "Not affiliated with The Open University - independent open-source project"))
