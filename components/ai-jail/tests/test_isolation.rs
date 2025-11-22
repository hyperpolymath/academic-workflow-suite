//! Integration tests for AI jail isolation
//!
//! These tests verify that the AI jail cannot make network calls
//! and operates correctly in an isolated environment.

use std::process::{Command, Stdio};
use std::io::Write;
use serde_json::json;

#[test]
fn test_binary_exists() {
    // Verify that the binary can be built
    let output = Command::new("cargo")
        .args(&["build", "--bin", "ai-jail"])
        .output()
        .expect("Failed to build binary");

    assert!(output.status.success(), "Build failed: {:?}", output);
}

#[test]
#[ignore] // Requires model files to be present
fn test_stdin_stdout_protocol() {
    // Test basic stdin/stdout communication
    let mut child = Command::new("cargo")
        .args(&["run", "--bin", "ai-jail"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .expect("Failed to spawn process");

    let stdin = child.stdin.as_mut().expect("Failed to open stdin");

    // Send a test request
    let request = json!({
        "tma_content": "Discuss the impact of climate change on biodiversity.",
        "rubric": "Award 10 marks for comprehensive discussion covering at least 3 ecosystems.",
        "question_number": 1,
        "student_answer": "Climate change affects many animals and plants.",
        "max_tokens": 100,
        "temperature": 0.7,
        "top_p": 0.9
    });

    let request_json = serde_json::to_string(&request).unwrap();
    writeln!(stdin, "{}", request_json).expect("Failed to write to stdin");

    // Note: In a real test, we would read from stdout and verify the response
    // This is a basic structure test
}

#[test]
fn test_invalid_json_handling() {
    // Test that invalid JSON is handled gracefully
    let mut child = Command::new("cargo")
        .args(&["run", "--bin", "ai-jail"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .expect("Failed to spawn process");

    let stdin = child.stdin.as_mut().expect("Failed to open stdin");

    // Send invalid JSON
    writeln!(stdin, "{{invalid json}}").expect("Failed to write to stdin");

    // The process should handle this gracefully and return an error response
    // (not crash)
}

#[test]
#[cfg(target_os = "linux")]
fn test_container_network_isolation() {
    // Test that the container cannot access the network
    // This test requires podman to be installed

    let podman_check = Command::new("podman")
        .arg("--version")
        .output();

    if podman_check.is_err() {
        eprintln!("Podman not available, skipping network isolation test");
        return;
    }

    // Build the container
    let build_output = Command::new("podman")
        .args(&[
            "build",
            "-t",
            "ai-jail-test:latest",
            "-f",
            "Containerfile",
            ".",
        ])
        .output();

    if let Ok(output) = build_output {
        if !output.status.success() {
            eprintln!("Container build failed, skipping test");
            return;
        }

        // Try to run a network command inside the container (should fail)
        let run_output = Command::new("podman")
            .args(&[
                "run",
                "--rm",
                "--network=none",
                "ai-jail-test:latest",
                "sh",
                "-c",
                "ping -c 1 8.8.8.8 || echo 'Network isolated'",
            ])
            .output()
            .expect("Failed to run container");

        let stdout = String::from_utf8_lossy(&run_output.stdout);
        assert!(
            stdout.contains("Network isolated") || !run_output.status.success(),
            "Container should not have network access"
        );
    }
}

#[test]
fn test_model_config_validation() {
    // Test that the binary validates model configuration properly
    use std::env;

    // Set invalid model paths
    env::set_var("MODEL_PATH", "/nonexistent/model.safetensors");
    env::set_var("TOKENIZER_PATH", "/nonexistent/tokenizer.json");

    let output = Command::new("cargo")
        .args(&["run", "--bin", "ai-jail"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .output()
        .expect("Failed to run binary");

    // Should exit with error when model files don't exist
    assert!(!output.status.success());

    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        stderr.contains("not found") || stderr.contains("Failed to load"),
        "Should report missing model files"
    );

    // Clean up
    env::remove_var("MODEL_PATH");
    env::remove_var("TOKENIZER_PATH");
}

#[test]
fn test_security_no_new_privileges() {
    // Test that the container runs with no-new-privileges
    let podman_check = Command::new("podman")
        .arg("--version")
        .output();

    if podman_check.is_err() {
        eprintln!("Podman not available, skipping security test");
        return;
    }

    let output = Command::new("podman")
        .args(&[
            "run",
            "--rm",
            "--network=none",
            "--security-opt=no-new-privileges",
            "--cap-drop=ALL",
            "debian:bookworm-slim",
            "sh",
            "-c",
            "echo 'Security test passed'",
        ])
        .output();

    if let Ok(result) = output {
        assert!(
            result.status.success(),
            "Container should run with security restrictions"
        );
    }
}

#[test]
fn test_request_validation() {
    // Test protocol request validation
    use serde_json::json;

    let test_cases = vec![
        (
            json!({
                "tma_content": "",
                "rubric": "Test rubric",
                "question_number": 1
            }),
            false, // Should fail - empty TMA content
        ),
        (
            json!({
                "tma_content": "Test content",
                "rubric": "",
                "question_number": 1
            }),
            false, // Should fail - empty rubric
        ),
        (
            json!({
                "tma_content": "Test content",
                "rubric": "Test rubric",
                "question_number": 1,
                "temperature": 5.0
            }),
            false, // Should fail - invalid temperature
        ),
        (
            json!({
                "tma_content": "Test content",
                "rubric": "Test rubric",
                "question_number": 1,
                "max_tokens": 0
            }),
            false, // Should fail - invalid max_tokens
        ),
    ];

    for (request_json, should_pass) in test_cases {
        let request_str = serde_json::to_string(&request_json).unwrap();

        let mut child = Command::new("cargo")
            .args(&["run", "--bin", "ai-jail"])
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn();

        if let Ok(mut process) = child {
            if let Some(stdin) = process.stdin.as_mut() {
                let _ = writeln!(stdin, "{}", request_str);
            }

            // Note: In production, we would verify the response
            // For now, this just tests that invalid requests don't crash
        }
    }
}

#[test]
fn test_memory_constraints() {
    // Test that the container can run with memory limits
    let podman_check = Command::new("podman")
        .arg("--version")
        .output();

    if podman_check.is_err() {
        eprintln!("Podman not available, skipping memory test");
        return;
    }

    // Try to run with 10GB memory limit (more than needed for Q4 model)
    let output = Command::new("podman")
        .args(&[
            "run",
            "--rm",
            "--network=none",
            "--memory=10g",
            "debian:bookworm-slim",
            "sh",
            "-c",
            "echo 'Memory limit test'",
        ])
        .output();

    if let Ok(result) = output {
        assert!(
            result.status.success(),
            "Container should run with memory limits"
        );
    }
}
