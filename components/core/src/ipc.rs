//! IPC Communication with AI Jail
//!
//! Provides stdin/stdout communication protocol for interacting with
//! the isolated AI processing jail.

use crate::feedback::CriterionScore;
use crate::tma::RubricCriterion;
use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::io::{BufRead, BufReader, Write};
use std::process::{Child, ChildStdin, ChildStdout, Command, Stdio};
use thiserror::Error;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader as AsyncBufReader};

/// Errors that can occur during IPC communication
#[derive(Debug, Error)]
pub enum IPCError {
    #[error("Failed to spawn AI jail process: {0}")]
    SpawnError(String),

    #[error("Failed to write to stdin: {0}")]
    WriteError(String),

    #[error("Failed to read from stdout: {0}")]
    ReadError(String),

    #[error("Failed to serialize message: {0}")]
    SerializationError(String),

    #[error("Failed to deserialize message: {0}")]
    DeserializationError(String),

    #[error("AI jail process crashed")]
    ProcessCrashed,

    #[error("Timeout waiting for response")]
    Timeout,

    #[error("Invalid message format")]
    InvalidMessage,
}

/// IPC message types
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", content = "payload")]
pub enum IPCMessage {
    /// Request feedback generation
    FeedbackRequest {
        request_id: String,
        content: String,
        rubric: String,
        criteria: Vec<RubricCriterion>,
    },

    /// Response with generated feedback
    FeedbackResponse {
        request_id: String,
        feedback: String,
        scores: Vec<CriterionScore>,
        overall_grade: f32,
    },

    /// Health check ping
    Ping {
        timestamp: i64,
    },

    /// Health check pong
    Pong {
        timestamp: i64,
    },

    /// Error message
    Error {
        message: String,
    },

    /// Shutdown request
    Shutdown,

    /// Acknowledgment
    Ack {
        request_id: String,
    },
}

/// Synchronous IPC client for communicating with AI jail
pub struct IPCClient {
    stdin: Option<ChildStdin>,
    stdout: Option<BufReader<ChildStdout>>,
    process: Option<Child>,
}

impl IPCClient {
    /// Create a new IPC client by spawning the AI jail process
    ///
    /// # Arguments
    ///
    /// * `jail_command` - Command to execute the AI jail (e.g., "firejail", "bwrap")
    /// * `jail_args` - Arguments for the jail command
    /// * `ai_script` - Path to the AI processing script
    pub fn spawn(jail_command: &str, jail_args: &[String], ai_script: &str) -> Result<Self> {
        let mut cmd = Command::new(jail_command);
        cmd.args(jail_args)
            .arg(ai_script)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped());

        let mut process = cmd
            .spawn()
            .map_err(|e| IPCError::SpawnError(e.to_string()))?;

        let stdin = process.stdin.take();
        let stdout = process.stdout.take().map(BufReader::new);

        Ok(Self {
            stdin,
            stdout,
            process: Some(process),
        })
    }

    /// Send a message to the AI jail
    pub fn send(&mut self, message: &IPCMessage) -> Result<()> {
        let stdin = self
            .stdin
            .as_mut()
            .ok_or_else(|| IPCError::WriteError("stdin not available".to_string()))?;

        let json = serde_json::to_string(message)
            .map_err(|e| IPCError::SerializationError(e.to_string()))?;

        writeln!(stdin, "{}", json)
            .map_err(|e| IPCError::WriteError(e.to_string()))?;

        stdin
            .flush()
            .map_err(|e| IPCError::WriteError(e.to_string()))?;

        Ok(())
    }

    /// Receive a message from the AI jail (blocking)
    pub fn receive(&mut self) -> Result<IPCMessage> {
        let stdout = self
            .stdout
            .as_mut()
            .ok_or_else(|| IPCError::ReadError("stdout not available".to_string()))?;

        let mut line = String::new();
        stdout
            .read_line(&mut line)
            .map_err(|e| IPCError::ReadError(e.to_string()))?;

        if line.is_empty() {
            return Err(IPCError::ProcessCrashed.into());
        }

        let message: IPCMessage = serde_json::from_str(&line)
            .map_err(|e| IPCError::DeserializationError(e.to_string()))?;

        Ok(message)
    }

    /// Send a ping and wait for pong (health check)
    pub fn ping(&mut self) -> Result<()> {
        let timestamp = chrono::Utc::now().timestamp();
        let ping = IPCMessage::Ping { timestamp };

        self.send(&ping)?;

        match self.receive()? {
            IPCMessage::Pong { .. } => Ok(()),
            IPCMessage::Error { message } => {
                anyhow::bail!("Ping failed: {}", message)
            }
            _ => Err(IPCError::InvalidMessage.into()),
        }
    }

    /// Shutdown the AI jail process
    pub fn shutdown(mut self) -> Result<()> {
        if let Some(stdin) = self.stdin.as_mut() {
            let shutdown = IPCMessage::Shutdown;
            let json = serde_json::to_string(&shutdown)
                .map_err(|e| IPCError::SerializationError(e.to_string()))?;
            let _ = writeln!(stdin, "{}", json);
            let _ = stdin.flush();
        }

        if let Some(mut process) = self.process.take() {
            let _ = process.wait();
        }

        Ok(())
    }
}

/// Async IPC client for tokio-based applications
pub struct AsyncIPCClient {
    stdin: Option<tokio::process::ChildStdin>,
    stdout: Option<AsyncBufReader<tokio::process::ChildStdout>>,
    process: Option<tokio::process::Child>,
}

impl AsyncIPCClient {
    /// Create a new async IPC client by spawning the AI jail process
    pub fn spawn(jail_command: &str, jail_args: &[String], ai_script: &str) -> Result<Self> {
        let mut cmd = tokio::process::Command::new(jail_command);
        cmd.args(jail_args)
            .arg(ai_script)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped());

        let mut process = cmd
            .spawn()
            .map_err(|e| IPCError::SpawnError(e.to_string()))?;

        let stdin = process.stdin.take();
        let stdout = process.stdout.take().map(AsyncBufReader::new);

        Ok(Self {
            stdin,
            stdout,
            process: Some(process),
        })
    }

    /// Send a message to the AI jail (async)
    pub async fn send(&mut self, message: &IPCMessage) -> Result<()> {
        let stdin = self
            .stdin
            .as_mut()
            .ok_or_else(|| IPCError::WriteError("stdin not available".to_string()))?;

        let json = serde_json::to_string(message)
            .map_err(|e| IPCError::SerializationError(e.to_string()))?;

        let data = format!("{}\n", json);
        stdin
            .write_all(data.as_bytes())
            .await
            .map_err(|e| IPCError::WriteError(e.to_string()))?;

        stdin
            .flush()
            .await
            .map_err(|e| IPCError::WriteError(e.to_string()))?;

        Ok(())
    }

    /// Receive a message from the AI jail (async)
    pub async fn receive(&mut self) -> Result<IPCMessage> {
        let stdout = self
            .stdout
            .as_mut()
            .ok_or_else(|| IPCError::ReadError("stdout not available".to_string()))?;

        let mut line = String::new();
        let bytes_read = stdout
            .read_line(&mut line)
            .await
            .map_err(|e| IPCError::ReadError(e.to_string()))?;

        if bytes_read == 0 {
            return Err(IPCError::ProcessCrashed.into());
        }

        let message: IPCMessage = serde_json::from_str(&line)
            .map_err(|e| IPCError::DeserializationError(e.to_string()))?;

        Ok(message)
    }

    /// Send a ping and wait for pong (health check)
    pub async fn ping(&mut self) -> Result<()> {
        let timestamp = chrono::Utc::now().timestamp();
        let ping = IPCMessage::Ping { timestamp };

        self.send(&ping).await?;

        match self.receive().await? {
            IPCMessage::Pong { .. } => Ok(()),
            IPCMessage::Error { message } => {
                anyhow::bail!("Ping failed: {}", message)
            }
            _ => Err(IPCError::InvalidMessage.into()),
        }
    }

    /// Shutdown the AI jail process
    pub async fn shutdown(mut self) -> Result<()> {
        if let Some(stdin) = self.stdin.as_mut() {
            let shutdown = IPCMessage::Shutdown;
            let json = serde_json::to_string(&shutdown)
                .map_err(|e| IPCError::SerializationError(e.to_string()))?;
            let data = format!("{}\n", json);
            let _ = stdin.write_all(data.as_bytes()).await;
            let _ = stdin.flush().await;
        }

        if let Some(mut process) = self.process.take() {
            let _ = process.wait().await;
        }

        Ok(())
    }
}

/// Builder for creating IPC clients with custom configuration
pub struct IPCClientBuilder {
    jail_command: String,
    jail_args: Vec<String>,
    ai_script: String,
}

impl IPCClientBuilder {
    /// Create a new IPC client builder
    pub fn new(ai_script: impl Into<String>) -> Self {
        Self {
            jail_command: "firejail".to_string(),
            jail_args: vec![
                "--quiet".to_string(),
                "--private".to_string(),
                "--net=none".to_string(),
            ],
            ai_script: ai_script.into(),
        }
    }

    /// Set the jail command (default: "firejail")
    pub fn jail_command(mut self, command: impl Into<String>) -> Self {
        self.jail_command = command.into();
        self
    }

    /// Add a jail argument
    pub fn jail_arg(mut self, arg: impl Into<String>) -> Self {
        self.jail_args.push(arg.into());
        self
    }

    /// Set all jail arguments
    pub fn jail_args(mut self, args: Vec<String>) -> Self {
        self.jail_args = args;
        self
    }

    /// Build a synchronous IPC client
    pub fn build_sync(self) -> Result<IPCClient> {
        IPCClient::spawn(&self.jail_command, &self.jail_args, &self.ai_script)
    }

    /// Build an async IPC client
    pub fn build_async(self) -> Result<AsyncIPCClient> {
        AsyncIPCClient::spawn(&self.jail_command, &self.jail_args, &self.ai_script)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ipc_message_serialization() {
        let msg = IPCMessage::Ping {
            timestamp: 123456,
        };

        let json = serde_json::to_string(&msg).unwrap();
        let deserialized: IPCMessage = serde_json::from_str(&json).unwrap();

        match deserialized {
            IPCMessage::Ping { timestamp } => assert_eq!(timestamp, 123456),
            _ => panic!("Wrong message type"),
        }
    }

    #[test]
    fn test_feedback_request_serialization() {
        let msg = IPCMessage::FeedbackRequest {
            request_id: "req123".to_string(),
            content: "test content".to_string(),
            rubric: "test rubric".to_string(),
            criteria: vec![],
        };

        let json = serde_json::to_string(&msg).unwrap();
        assert!(json.contains("FeedbackRequest"));
        assert!(json.contains("req123"));

        let deserialized: IPCMessage = serde_json::from_str(&json).unwrap();
        match deserialized {
            IPCMessage::FeedbackRequest { request_id, .. } => {
                assert_eq!(request_id, "req123");
            }
            _ => panic!("Wrong message type"),
        }
    }

    #[test]
    fn test_feedback_response_serialization() {
        let msg = IPCMessage::FeedbackResponse {
            request_id: "req123".to_string(),
            feedback: "Good work".to_string(),
            scores: vec![],
            overall_grade: 85.0,
        };

        let json = serde_json::to_string(&msg).unwrap();
        let deserialized: IPCMessage = serde_json::from_str(&json).unwrap();

        match deserialized {
            IPCMessage::FeedbackResponse { overall_grade, .. } => {
                assert_eq!(overall_grade, 85.0);
            }
            _ => panic!("Wrong message type"),
        }
    }

    #[test]
    fn test_error_message_serialization() {
        let msg = IPCMessage::Error {
            message: "Something went wrong".to_string(),
        };

        let json = serde_json::to_string(&msg).unwrap();
        let deserialized: IPCMessage = serde_json::from_str(&json).unwrap();

        match deserialized {
            IPCMessage::Error { message } => {
                assert_eq!(message, "Something went wrong");
            }
            _ => panic!("Wrong message type"),
        }
    }

    #[test]
    fn test_ipc_builder() {
        let builder = IPCClientBuilder::new("/path/to/ai/script.py")
            .jail_command("bwrap")
            .jail_arg("--unshare-all")
            .jail_arg("--die-with-parent");

        assert_eq!(builder.jail_command, "bwrap");
        assert_eq!(builder.jail_args.len(), 5); // 3 default + 2 added
        assert_eq!(builder.ai_script, "/path/to/ai/script.py");
    }

    #[test]
    fn test_shutdown_message() {
        let msg = IPCMessage::Shutdown;
        let json = serde_json::to_string(&msg).unwrap();
        assert!(json.contains("Shutdown"));
    }

    #[test]
    fn test_ack_message() {
        let msg = IPCMessage::Ack {
            request_id: "req123".to_string(),
        };

        let json = serde_json::to_string(&msg).unwrap();
        let deserialized: IPCMessage = serde_json::from_str(&json).unwrap();

        match deserialized {
            IPCMessage::Ack { request_id } => {
                assert_eq!(request_id, "req123");
            }
            _ => panic!("Wrong message type"),
        }
    }
}
