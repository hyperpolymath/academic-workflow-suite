#!/usr/bin/env bash

# Shell Completion Generator for AWS CLI
# Generates shell completions for bash, zsh, fish, and PowerShell

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}"
BINARY_NAME="aws"

echo "Generating shell completions for AWS CLI..."
echo

# Build the CLI in release mode
echo "Building CLI..."
cd "${SCRIPT_DIR}/.."
cargo build --release

BINARY_PATH="target/release/${BINARY_NAME}"

if [ ! -f "${BINARY_PATH}" ]; then
    echo "Error: Binary not found at ${BINARY_PATH}"
    exit 1
fi

echo "Binary built successfully"
echo

# Generate completions using clap_complete
# Note: This requires adding clap_complete to the build dependencies

# Create a temporary program to generate completions
cat > /tmp/generate_completions.rs << 'EOF'
use clap::CommandFactory;
use clap_complete::{generate_to, shells::*};
use std::env;
use std::path::PathBuf;

include!("../src/main.rs");

fn main() -> std::io::Result<()> {
    let mut cmd = Cli::command();
    let bin_name = "aws";
    let outdir: PathBuf = match env::args().nth(1) {
        Some(dir) => dir.into(),
        None => ".".into(),
    };

    generate_to(Bash, &mut cmd, bin_name, &outdir)?;
    generate_to(Zsh, &mut cmd, bin_name, &outdir)?;
    generate_to(Fish, &mut cmd, bin_name, &outdir)?;
    generate_to(PowerShell, &mut cmd, bin_name, &outdir)?;

    println!("Completions generated in {:?}", outdir);
    Ok(())
}
EOF

# Alternative: Manual completion files

echo "Generating Bash completion..."
cat > "${OUTPUT_DIR}/${BINARY_NAME}.bash" << 'EOF'
# Bash completion for AWS CLI

_aws_completions() {
    local cur prev opts commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Top-level commands
    commands="init start stop status mark batch feedback config login sync update doctor help"

    # Global options
    opts="--verbose --no-color --config --format --help --version"

    if [ $COMP_CWORD -eq 1 ]; then
        COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
        return 0
    fi

    case "${prev}" in
        init)
            opts="--name --yes --help"
            ;;
        start)
            opts="--detach --help"
            ;;
        stop)
            opts="--force --help"
            ;;
        status)
            opts="--detailed --help"
            ;;
        mark)
            opts="--student --assignment --interactive --help"
            COMPREPLY=( $(compgen -f -- ${cur}) )
            return 0
            ;;
        batch)
            opts="--pattern --concurrency --help"
            COMPREPLY=( $(compgen -d -- ${cur}) )
            return 0
            ;;
        feedback)
            opts="--edit --output --help"
            ;;
        config)
            local config_cmds="show set get reset edit"
            COMPREPLY=( $(compgen -W "${config_cmds}" -- ${cur}) )
            return 0
            ;;
        login)
            opts="--username --url --save --help"
            ;;
        sync)
            opts="--download --upload --dry-run --help"
            ;;
        update)
            opts="--version --check --help"
            ;;
        doctor)
            opts="--fix --help"
            ;;
        --config|--output)
            COMPREPLY=( $(compgen -f -- ${cur}) )
            return 0
            ;;
        --format)
            COMPREPLY=( $(compgen -W "text json" -- ${cur}) )
            return 0
            ;;
        *)
            ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
}

complete -F _aws_completions aws
EOF

echo "✓ Bash completion: ${OUTPUT_DIR}/${BINARY_NAME}.bash"

echo "Generating Zsh completion..."
cat > "${OUTPUT_DIR}/_${BINARY_NAME}" << 'EOF'
#compdef aws

# Zsh completion for AWS CLI

_aws() {
    local line state

    _arguments -C \
        '1: :->command' \
        '*::arg:->args' \
        '--verbose[Enable verbose output]' \
        '--no-color[Disable colored output]' \
        '--config[Path to configuration file]:file:_files' \
        '--format[Output format]:format:(text json)' \
        '(- *)--help[Show help]' \
        '(- *)--version[Show version]'

    case $state in
        command)
            local commands=(
                'init:Initialize AWS in current directory'
                'start:Start AWS services'
                'stop:Stop AWS services'
                'status:Show service status'
                'mark:Mark a TMA'
                'batch:Batch mark multiple TMAs'
                'feedback:View or edit feedback'
                'config:Manage configuration'
                'login:Login to Moodle'
                'sync:Sync with Moodle'
                'update:Update AWS'
                'doctor:Diagnose issues'
                'help:Show help'
            )
            _describe 'command' commands
            ;;
        args)
            case $line[1] in
                init)
                    _arguments \
                        '--name[Project name]:name:' \
                        '--yes[Skip interactive prompts]' \
                        '--help[Show help]'
                    ;;
                start)
                    _arguments \
                        '--detach[Run in detached mode]' \
                        '--help[Show help]' \
                        '*:services:'
                    ;;
                stop)
                    _arguments \
                        '--force[Force stop]' \
                        '--help[Show help]' \
                        '*:services:'
                    ;;
                status)
                    _arguments \
                        '--detailed[Show detailed status]' \
                        '--help[Show help]'
                    ;;
                mark)
                    _arguments \
                        '--student[Student ID]:student:' \
                        '--assignment[Assignment ID]:assignment:' \
                        '--interactive[Interactive mode]' \
                        '--help[Show help]' \
                        ':file:_files'
                    ;;
                batch)
                    _arguments \
                        '--pattern[File pattern]:pattern:' \
                        '--concurrency[Max concurrent jobs]:number:' \
                        '--help[Show help]' \
                        ':directory:_directories'
                    ;;
                feedback)
                    _arguments \
                        '--edit[Edit feedback]' \
                        '--output[Export to file]:file:_files' \
                        '--help[Show help]' \
                        ':id:'
                    ;;
                config)
                    local config_commands=(
                        'show:Show current configuration'
                        'set:Set a configuration value'
                        'get:Get a configuration value'
                        'reset:Reset to defaults'
                        'edit:Edit interactively'
                    )
                    _describe 'config command' config_commands
                    ;;
                login)
                    _arguments \
                        '--username[Moodle username]:username:' \
                        '--url[Moodle URL]:url:' \
                        '--save[Save credentials]' \
                        '--help[Show help]'
                    ;;
                sync)
                    _arguments \
                        '--download[Download assignments]' \
                        '--upload[Upload feedback]' \
                        '--dry-run[Dry run mode]' \
                        '--help[Show help]'
                    ;;
                update)
                    _arguments \
                        '--version[Update to version]:version:' \
                        '--check[Check without installing]' \
                        '--help[Show help]'
                    ;;
                doctor)
                    _arguments \
                        '--fix[Auto-fix issues]' \
                        '--help[Show help]'
                    ;;
            esac
            ;;
    esac
}

_aws "$@"
EOF

echo "✓ Zsh completion: ${OUTPUT_DIR}/_${BINARY_NAME}"

echo "Generating Fish completion..."
cat > "${OUTPUT_DIR}/${BINARY_NAME}.fish" << 'EOF'
# Fish completion for AWS CLI

# Global options
complete -c aws -s v -l verbose -d 'Enable verbose output'
complete -c aws -l no-color -d 'Disable colored output'
complete -c aws -s c -l config -r -d 'Path to configuration file'
complete -c aws -l format -a 'text json' -d 'Output format'
complete -c aws -s h -l help -d 'Show help'
complete -c aws -l version -d 'Show version'

# Commands
complete -c aws -f -n '__fish_use_subcommand' -a 'init' -d 'Initialize AWS'
complete -c aws -f -n '__fish_use_subcommand' -a 'start' -d 'Start services'
complete -c aws -f -n '__fish_use_subcommand' -a 'stop' -d 'Stop services'
complete -c aws -f -n '__fish_use_subcommand' -a 'status' -d 'Show status'
complete -c aws -f -n '__fish_use_subcommand' -a 'mark' -d 'Mark a TMA'
complete -c aws -f -n '__fish_use_subcommand' -a 'batch' -d 'Batch mark TMAs'
complete -c aws -f -n '__fish_use_subcommand' -a 'feedback' -d 'View/edit feedback'
complete -c aws -f -n '__fish_use_subcommand' -a 'config' -d 'Manage configuration'
complete -c aws -f -n '__fish_use_subcommand' -a 'login' -d 'Login to Moodle'
complete -c aws -f -n '__fish_use_subcommand' -a 'sync' -d 'Sync with Moodle'
complete -c aws -f -n '__fish_use_subcommand' -a 'update' -d 'Update AWS'
complete -c aws -f -n '__fish_use_subcommand' -a 'doctor' -d 'Diagnose issues'
complete -c aws -f -n '__fish_use_subcommand' -a 'help' -d 'Show help'

# init subcommand
complete -c aws -f -n '__fish_seen_subcommand_from init' -s n -l name -d 'Project name'
complete -c aws -f -n '__fish_seen_subcommand_from init' -s y -l yes -d 'Skip prompts'

# start subcommand
complete -c aws -f -n '__fish_seen_subcommand_from start' -s d -l detach -d 'Detached mode'

# stop subcommand
complete -c aws -f -n '__fish_seen_subcommand_from stop' -s f -l force -d 'Force stop'

# status subcommand
complete -c aws -f -n '__fish_seen_subcommand_from status' -s d -l detailed -d 'Detailed status'

# mark subcommand
complete -c aws -f -n '__fish_seen_subcommand_from mark' -s s -l student -d 'Student ID'
complete -c aws -f -n '__fish_seen_subcommand_from mark' -s a -l assignment -d 'Assignment ID'
complete -c aws -f -n '__fish_seen_subcommand_from mark' -s i -l interactive -d 'Interactive mode'

# batch subcommand
complete -c aws -f -n '__fish_seen_subcommand_from batch' -s p -l pattern -d 'File pattern'
complete -c aws -f -n '__fish_seen_subcommand_from batch' -s c -l concurrency -d 'Max concurrent'

# feedback subcommand
complete -c aws -f -n '__fish_seen_subcommand_from feedback' -s e -l edit -d 'Edit feedback'
complete -c aws -f -n '__fish_seen_subcommand_from feedback' -s o -l output -r -d 'Export to file'

# config subcommand
complete -c aws -f -n '__fish_seen_subcommand_from config' -a 'show' -d 'Show configuration'
complete -c aws -f -n '__fish_seen_subcommand_from config' -a 'set' -d 'Set value'
complete -c aws -f -n '__fish_seen_subcommand_from config' -a 'get' -d 'Get value'
complete -c aws -f -n '__fish_seen_subcommand_from config' -a 'reset' -d 'Reset to defaults'
complete -c aws -f -n '__fish_seen_subcommand_from config' -a 'edit' -d 'Edit interactively'

# login subcommand
complete -c aws -f -n '__fish_seen_subcommand_from login' -s u -l username -d 'Username'
complete -c aws -f -n '__fish_seen_subcommand_from login' -l url -d 'Moodle URL'
complete -c aws -f -n '__fish_seen_subcommand_from login' -s s -l save -d 'Save credentials'

# sync subcommand
complete -c aws -f -n '__fish_seen_subcommand_from sync' -s d -l download -d 'Download assignments'
complete -c aws -f -n '__fish_seen_subcommand_from sync' -s u -l upload -d 'Upload feedback'
complete -c aws -f -n '__fish_seen_subcommand_from sync' -s n -l dry-run -d 'Dry run'

# update subcommand
complete -c aws -f -n '__fish_seen_subcommand_from update' -s v -l version -d 'Version'
complete -c aws -f -n '__fish_seen_subcommand_from update' -s c -l check -d 'Check only'

# doctor subcommand
complete -c aws -f -n '__fish_seen_subcommand_from doctor' -s f -l fix -d 'Auto-fix issues'
EOF

echo "✓ Fish completion: ${OUTPUT_DIR}/${BINARY_NAME}.fish"

echo "Generating PowerShell completion..."
cat > "${OUTPUT_DIR}/_${BINARY_NAME}.ps1" << 'EOF'
# PowerShell completion for AWS CLI

Register-ArgumentCompleter -Native -CommandName aws -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $commands = @(
        [CompletionResult]::new('init', 'init', [CompletionResultType]::ParameterValue, 'Initialize AWS')
        [CompletionResult]::new('start', 'start', [CompletionResultType]::ParameterValue, 'Start services')
        [CompletionResult]::new('stop', 'stop', [CompletionResultType]::ParameterValue, 'Stop services')
        [CompletionResult]::new('status', 'status', [CompletionResultType]::ParameterValue, 'Show status')
        [CompletionResult]::new('mark', 'mark', [CompletionResultType]::ParameterValue, 'Mark a TMA')
        [CompletionResult]::new('batch', 'batch', [CompletionResultType]::ParameterValue, 'Batch mark TMAs')
        [CompletionResult]::new('feedback', 'feedback', [CompletionResultType]::ParameterValue, 'View/edit feedback')
        [CompletionResult]::new('config', 'config', [CompletionResultType]::ParameterValue, 'Manage config')
        [CompletionResult]::new('login', 'login', [CompletionResultType]::ParameterValue, 'Login to Moodle')
        [CompletionResult]::new('sync', 'sync', [CompletionResultType]::ParameterValue, 'Sync with Moodle')
        [CompletionResult]::new('update', 'update', [CompletionResultType]::ParameterValue, 'Update AWS')
        [CompletionResult]::new('doctor', 'doctor', [CompletionResultType]::ParameterValue, 'Diagnose issues')
        [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Show help')
    )

    $commands | Where-Object { $_.CompletionText -like "$wordToComplete*" }
}
EOF

echo "✓ PowerShell completion: ${OUTPUT_DIR}/_${BINARY_NAME}.ps1"

echo
echo "Shell completions generated successfully!"
echo
echo "Installation instructions:"
echo
echo "Bash:"
echo "  sudo cp ${OUTPUT_DIR}/${BINARY_NAME}.bash /etc/bash_completion.d/${BINARY_NAME}"
echo "  Or add to ~/.bashrc:"
echo "  source ${OUTPUT_DIR}/${BINARY_NAME}.bash"
echo
echo "Zsh:"
echo "  Copy ${OUTPUT_DIR}/_${BINARY_NAME} to a directory in your \$fpath"
echo "  Example: cp ${OUTPUT_DIR}/_${BINARY_NAME} ~/.zsh/completion/"
echo "  Then run: compinit"
echo
echo "Fish:"
echo "  cp ${OUTPUT_DIR}/${BINARY_NAME}.fish ~/.config/fish/completions/"
echo
echo "PowerShell:"
echo "  Add to your PowerShell profile:"
echo "  . ${OUTPUT_DIR}/_${BINARY_NAME}.ps1"
echo
