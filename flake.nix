{
  description = "Academic Workflow Suite - Privacy-first AI-assisted TMA marking";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        # Rust toolchain
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" "clippy" ];
        };

        # Build inputs common to all components
        commonBuildInputs = with pkgs; [
          pkg-config
          openssl
          sqlite
          lmdb
        ];

        # Rust core engine
        coreEngine = pkgs.rustPlatform.buildRustPackage rec {
          pname = "aws-core";
          version = "0.1.0";
          src = ./components/core;

          cargoLock = {
            lockFile = ./components/core/Cargo.lock;
          };

          nativeBuildInputs = commonBuildInputs;

          meta = with pkgs.lib; {
            description = "Academic Workflow Suite - Core Engine";
            homepage = "https://github.com/Hyperpolymath/academic-workflow-suite";
            license = licenses.agpl3Plus;
            maintainers = [ ];
            platforms = platforms.unix;
          };
        };

        # AI Jail
        aiJail = pkgs.rustPlatform.buildRustPackage rec {
          pname = "aws-ai-jail";
          version = "0.1.0";
          src = ./components/ai-jail;

          cargoLock = {
            lockFile = ./components/ai-jail/Cargo.lock;
          };

          nativeBuildInputs = commonBuildInputs;

          meta = with pkgs.lib; {
            description = "Academic Workflow Suite - AI Jail";
            homepage = "https://github.com/Hyperpolymath/academic-workflow-suite";
            license = licenses.agpl3Plus;
            maintainers = [ ];
            platforms = platforms.unix;
          };
        };

        # Shared libraries
        sharedLibs = pkgs.rustPlatform.buildRustPackage rec {
          pname = "aws-shared";
          version = "0.1.0";
          src = ./components/shared;

          cargoLock = {
            lockFile = ./components/shared/Cargo.lock;
          };

          nativeBuildInputs = commonBuildInputs;

          meta = with pkgs.lib; {
            description = "Academic Workflow Suite - Shared Libraries";
            homepage = "https://github.com/Hyperpolymath/academic-workflow-suite";
            license = licenses.agpl3Plus;
            maintainers = [ ];
            platforms = platforms.unix;
          };
        };

        # CLI tool
        cliTool = pkgs.rustPlatform.buildRustPackage rec {
          pname = "aws-cli";
          version = "0.1.0";
          src = ./cli;

          cargoLock = {
            lockFile = ./cli/Cargo.lock;
          };

          nativeBuildInputs = commonBuildInputs;

          meta = with pkgs.lib; {
            description = "Academic Workflow Suite - CLI Tool";
            homepage = "https://github.com/Hyperpolymath/academic-workflow-suite";
            license = licenses.agpl3Plus;
            maintainers = [ ];
            platforms = platforms.unix;
          };
        };

        # Development shell
        devShell = pkgs.mkShell {
          name = "aws-dev-shell";

          buildInputs = with pkgs; [
            # Rust
            rustToolchain
            cargo-watch
            cargo-edit
            cargo-audit
            cargo-outdated
            cargo-tarpaulin  # Code coverage

            # Elixir
            beam.packages.erlang
            elixir
            elixir_ls

            # Node.js
            nodejs_20
            nodePackages.npm

            # Database tools
            postgresql
            lmdb

            # Container tools
            docker
            podman
            docker-compose

            # Development tools
            just
            git
            gnumake
            shellcheck
            yamllint
            tokei  # Code statistics

            # Security tools
            semgrep
            trivy

            # Documentation
            mdbook

            # System dependencies
            pkg-config
            openssl
            sqlite
            lmdb
          ];

          shellHook = ''
            echo "🚀 Academic Workflow Suite Development Environment"
            echo ""
            echo "Available commands:"
            echo "  just --list     # Show all available tasks"
            echo "  just build      # Build all components"
            echo "  just test       # Run all tests"
            echo "  just dev        # Start development environment"
            echo ""
            echo "Component versions:"
            echo "  Rust:    $(rustc --version)"
            echo "  Elixir:  $(elixir --version | head -1)"
            echo "  Node.js: $(node --version)"
            echo ""
            echo "Documentation: https://github.com/Hyperpolymath/academic-workflow-suite/tree/main/docs"
            echo ""
          '';

          # Environment variables
          RUST_BACKTRACE = "1";
          RUST_LOG = "info";
          DATABASE_URL = "postgres://localhost/aws_dev";
          MIX_ENV = "dev";
          NODE_ENV = "development";
        };

        # Docker image for AI jail
        dockerImage = pkgs.dockerTools.buildImage {
          name = "aws-ai-jail";
          tag = "latest";

          contents = [ aiJail ];

          config = {
            Cmd = [ "${aiJail}/bin/aws-ai-jail" ];
            ExposedPorts = { };
            Env = [
              "RUST_LOG=info"
            ];
            Labels = {
              "org.opencontainers.image.title" = "Academic Workflow Suite - AI Jail";
              "org.opencontainers.image.version" = "0.1.0";
              "org.opencontainers.image.licenses" = "AGPL-3.0";
              "org.opencontainers.image.source" = "https://github.com/Hyperpolymath/academic-workflow-suite";
            };
          };
        };

      in
      {
        # Packages
        packages = {
          inherit coreEngine aiJail sharedLibs cliTool dockerImage;
          default = cliTool;
        };

        # Development shell
        devShells.default = devShell;

        # Apps
        apps = {
          core = {
            type = "app";
            program = "${coreEngine}/bin/aws-core";
          };
          cli = {
            type = "app";
            program = "${cliTool}/bin/aws";
          };
          ai-jail = {
            type = "app";
            program = "${aiJail}/bin/aws-ai-jail";
          };
        };

        # Checks (run with `nix flake check`)
        checks = {
          # Rust tests
          core-tests = coreEngine.overrideAttrs (old: {
            doCheck = true;
            checkPhase = ''
              cargo test --release
            '';
          });

          ai-jail-tests = aiJail.overrideAttrs (old: {
            doCheck = true;
            checkPhase = ''
              cargo test --release
            '';
          });

          shared-tests = sharedLibs.overrideAttrs (old: {
            doCheck = true;
            checkPhase = ''
              cargo test --release
            '';
          });

          # Formatting checks
          rust-fmt = pkgs.runCommand "check-rust-fmt" {
            nativeBuildInputs = [ rustToolchain ];
          } ''
            cd ${./components/core}
            cargo fmt --check
            touch $out
          '';

          # Clippy checks
          rust-clippy = pkgs.runCommand "check-rust-clippy" {
            nativeBuildInputs = [ rustToolchain ] ++ commonBuildInputs;
          } ''
            cd ${./components/core}
            cargo clippy -- -D warnings
            touch $out
          '';

          # Security audit
          rust-audit = pkgs.runCommand "check-rust-audit" {
            nativeBuildInputs = [ rustToolchain pkgs.cargo-audit ];
          } ''
            cd ${./components/core}
            cargo audit
            touch $out
          '';
        };

        # Hydra jobs (for continuous integration)
        hydraJobs = {
          inherit coreEngine aiJail sharedLibs cliTool dockerImage;
        };

        # Formatter for `nix fmt`
        formatter = pkgs.nixpkgs-fmt;
      }
    );

  # NixOS module (optional)
  nixosModules.default = { config, lib, pkgs, ... }:
    with lib;
    let
      cfg = config.services.academic-workflow-suite;
    in
    {
      options.services.academic-workflow-suite = {
        enable = mkEnableOption "Academic Workflow Suite";

        package = mkOption {
          type = types.package;
          default = self.packages.${pkgs.system}.coreEngine;
          description = "The Academic Workflow Suite package to use";
        };

        dataDir = mkOption {
          type = types.str;
          default = "/var/lib/aws";
          description = "Directory to store AWS data";
        };

        user = mkOption {
          type = types.str;
          default = "aws";
          description = "User account under which AWS runs";
        };

        group = mkOption {
          type = types.str;
          default = "aws";
          description = "Group under which AWS runs";
        };
      };

      config = mkIf cfg.enable {
        users.users.${cfg.user} = {
          isSystemUser = true;
          group = cfg.group;
          home = cfg.dataDir;
          createHome = true;
        };

        users.groups.${cfg.group} = { };

        systemd.services.academic-workflow-suite = {
          description = "Academic Workflow Suite";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];

          serviceConfig = {
            Type = "simple";
            User = cfg.user;
            Group = cfg.group;
            ExecStart = "${cfg.package}/bin/aws-core start";
            Restart = "on-failure";
            RestartSec = "5s";

            # Security hardening
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            NoNewPrivileges = true;
            ReadWritePaths = [ cfg.dataDir ];
          };
        };
      };
    };
}
