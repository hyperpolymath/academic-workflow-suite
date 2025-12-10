;; Academic-Workflow-Suite - Guix Package Definition
;; Run: guix shell -D -f guix.scm

(use-modules (guix packages)
             (guix gexp)
             (guix git-download)
             (guix build-system gnu)
             ((guix licenses) #:prefix license:)
             (gnu packages base))

(define-public academic_workflow_suite
  (package
    (name "Academic-Workflow-Suite")
    (version "0.1.0")
    (source (local-file "." "Academic-Workflow-Suite-checkout"
                        #:recursive? #t
                        #:select? (git-predicate ".")))
    (build-system gnu-build-system)
    (synopsis "Guix channel/infrastructure")
    (description "Guix channel/infrastructure - part of the RSR ecosystem.")
    (home-page "https://github.com/hyperpolymath/Academic-Workflow-Suite")
    (license license:agpl3+)))

;; Return package for guix shell
academic_workflow_suite
