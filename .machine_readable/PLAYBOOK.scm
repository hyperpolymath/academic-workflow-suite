;; SPDX-License-Identifier: AGPL-3.0-or-later
;; PLAYBOOK.scm - Operational runbook for academic-workflow-suite

(define playbook
  `((version . "1.0.0")

    (procedures
      ((build
         ((rust-core
            (command . "cargo build --release -p aws-core")
            (artifacts . "target/release/aws-core")
            (dependencies . ("rustc >= 1.75" "cargo")))
          (office-addin
            (command . "cd components/office-addin && npm run build")
            (artifacts . "components/office-addin/dist/")
            (dependencies . ("node >= 18" "npm")))
          (ai-jail
            (command . "cd components/ai-jail && ./build.sh")
            (artifacts . "ai-jail.tar.gz")
            (dependencies . ("docker" "buildah")))
          (backend
            (command . "cd components/backend && mix compile")
            (artifacts . "_build/prod/")
            (dependencies . ("elixir >= 1.14" "erlang >= 26")))))

       (test
         ((unit
            (command . "just test-unit")
            (coverage-threshold . 80))
          (integration
            (command . "just test-integration")
            (requires . ("docker" "ai-jail container")))
          (e2e
            (command . "just test-e2e")
            (requires . ("word" "office-addin installed")))
          (property
            (command . "cargo test --features proptest")
            (focus . "crypto and validation modules"))
          (security
            (command . "just security-scan")
            (tools . ("cargo-audit" "trivy" "trufflehog")))))

       (release
         ((steps
            "1. Update VERSION file"
            "2. Run full test suite"
            "3. Build all components"
            "4. Create signed containers"
            "5. Generate SBOM"
            "6. Tag release"
            "7. Push to registries")
          (command . "just release")
          (artifacts
            "aws-core binary"
            "office-addin package"
            "ai-jail container"
            "backend container")))

       (deploy
         ((local
            (steps
              "1. Start core engine: aws-core start"
              "2. Install Office add-in via manifest.xml"
              "3. Pull AI jail container"
              "4. Configure rubrics directory"))
          (docker-compose
            (command . "docker-compose up -d")
            (components . ("core" "ai-jail" "backend")))
          (verification
            (health-check . "aws-core doctor")
            (smoke-test . "aws-core test --quick"))))

       (rollback
         ((steps
            "1. Stop current services: aws-core stop"
            "2. Restore previous binary: aws-core rollback"
            "3. Verify event store integrity"
            "4. Start services: aws-core start"
            "5. Run health check")
          (notes
            "Event store is append-only - no data loss on rollback"
            "Office add-in may need manifest update")))

       (debug
         ((logs
            (core . "aws-core logs --follow")
            (ai-jail . "docker logs -f aws-ai-jail")
            (backend . "docker logs -f aws-backend"))
          (health
            (command . "aws-core doctor")
            (checks
              "Core engine status"
              "AI jail container status"
              "Event store integrity"
              "IPC socket health"))
          (tracing
            (command . "aws-core trace --request-id <id>")
            (purpose . "Follow request through system"))))))

    (alerts
      ((ai-jail-down
         (severity . "critical")
         (impact . "AI analysis unavailable")
         (resolution
           "1. Check docker/podman status"
           "2. Restart container: docker restart aws-ai-jail"
           "3. Verify network isolation: aws-core doctor"))
       (event-store-full
         (severity . "high")
         (impact . "Cannot save new events")
         (resolution
           "1. Check disk space"
           "2. Archive old events: aws-core archive --before 90d"
           "3. Expand LMDB map size"))
       (ipc-timeout
         (severity . "medium")
         (impact . "AI responses slow or failing")
         (resolution
           "1. Check AI jail resource usage"
           "2. Restart if memory exhausted"
           "3. Consider model size reduction"))))

    (contacts
      ((maintainers
         (primary . "AWS Core Team")
         (email . "maintainers@aws-edu.org"))
       (security
         (team . "AWS Security Team")
         (email . "security@aws-edu.org")
         (pgp . "https://aws-edu.org/pgp-key.asc"))
       (community
         (forum . "https://discuss.aws-edu.org")
         (discord . "https://discord.gg/aws-edu")
         (github . "https://github.com/academic-workflow-suite"))))))
