# AI Jail Development Guide

This document provides guidance for developers working on the AI Jail component.

## Development Environment Setup

### Prerequisites

1. **Rust Toolchain** (1.75 or later)
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   rustup update
   ```

2. **Podman or Docker**
   ```bash
   # Fedora/RHEL
   sudo dnf install podman

   # Ubuntu/Debian
   sudo apt install podman

   # macOS
   brew install podman
   ```

3. **Development Tools**
   ```bash
   # Install clippy and rustfmt
   rustup component add clippy rustfmt

   # Install cargo-watch for auto-recompilation
   cargo install cargo-watch

   # Install cargo-edit for dependency management
   cargo install cargo-edit
   ```

### Model Files

For development, you'll need Mistral 7B model files:

```bash
# Create models directory
mkdir -p /models/mistral-7b

# Download from HuggingFace (requires huggingface-cli)
pip install huggingface-hub
huggingface-cli download mistralai/Mistral-7B-v0.1 \
  --local-dir /models/mistral-7b \
  --include "*.safetensors" "tokenizer.json" "config.json"
```

For testing without full model, you can use a mock:
```bash
# Set environment to skip actual model loading in tests
export SKIP_MODEL_LOAD=1
cargo test
```

## Project Structure

```
ai-jail/
├── src/
│   ├── main.rs           # Entry point, IPC handling, startup
│   ├── model.rs          # Model loading, configuration, Candle integration
│   ├── inference.rs      # Text generation, sampling, logits processing
│   └── protocol.rs       # Request/response types, validation
├── tests/
│   └── test_isolation.rs # Integration tests for security and isolation
├── examples/
│   ├── sample_request.json
│   └── sample_response.json
├── Cargo.toml            # Dependencies and metadata
├── Containerfile         # Multi-stage container build
├── build.sh             # Container build script
├── run.sh               # Container run script
├── test.sh              # Test runner script
└── README.md            # User documentation
```

## Development Workflow

### 1. Local Development

```bash
# Watch for changes and auto-rebuild
cargo watch -x 'build'

# Watch and run tests
cargo watch -x 'test'

# Watch and run specific test
cargo watch -x 'test test_protocol'
```

### 2. Testing

```bash
# Run all tests
./test.sh

# Run specific test suite
cargo test --lib              # Unit tests only
cargo test --test test_isolation  # Integration tests

# Run with verbose output
cargo test -- --nocapture

# Run ignored tests (require model files)
cargo test -- --ignored
```

### 3. Manual Testing

Terminal 1 - Start the binary:
```bash
RUST_LOG=debug cargo run --release
```

Terminal 2 - Send requests:
```bash
# Send sample request
cat examples/sample_request.json

# Or use a custom request
echo '{
  "tma_content": "Test",
  "rubric": "Test rubric",
  "question_number": 1,
  "max_tokens": 50
}'
```

### 4. Container Development

```bash
# Build container
./build.sh

# Run container interactively
./run.sh

# Run with custom models directory
MODELS_DIR=/path/to/models ./run.sh

# Test container isolation
podman run --rm -i \
  --network=none \
  -v /models:/models:ro \
  ai-jail:latest
```

## Code Style Guidelines

### Rust Conventions

1. **Formatting**: Use `cargo fmt` before committing
   ```bash
   cargo fmt
   ```

2. **Linting**: Pass all clippy checks
   ```bash
   cargo clippy -- -D warnings
   ```

3. **Documentation**: Add doc comments to public items
   ```rust
   /// Load a Mistral 7B model from disk
   ///
   /// # Arguments
   ///
   /// * `config` - Model configuration
   ///
   /// # Returns
   ///
   /// Loaded model or error
   pub fn load(config: ModelConfig) -> Result<Self> {
       // ...
   }
   ```

4. **Error Handling**: Use `anyhow::Result` with context
   ```rust
   self.model.forward(&input_tensor, position)
       .context("Model forward pass failed")?
   ```

5. **Testing**: Add tests for new functionality
   ```rust
   #[cfg(test)]
   mod tests {
       use super::*;

       #[test]
       fn test_validation() {
           // ...
       }
   }
   ```

### Module Organization

- `protocol.rs`: Pure data structures, no I/O
- `model.rs`: Model loading only, no inference logic
- `inference.rs`: Text generation, no IPC concerns
- `main.rs`: IPC, orchestration, error handling

## Performance Optimization

### Profiling

```bash
# Install flamegraph
cargo install flamegraph

# Profile the binary
sudo cargo flamegraph --bin ai-jail

# View flamegraph.svg in browser
```

### Memory Profiling

```bash
# Use heaptrack (Linux)
heaptrack target/release/ai-jail

# Or valgrind
valgrind --tool=massif target/release/ai-jail
```

### Optimization Tips

1. **Quantization**: Use Q4 for 8GB VRAM
   ```bash
   export QUANTIZATION=q4
   ```

2. **Batch Size**: Keep batch size = 1 for latency
3. **Max Tokens**: Limit to 512 for faster responses
4. **Flash Attention**: Enable if GPU supports it

## Debugging

### Debug Builds

```bash
# Build with debug symbols
cargo build

# Run with debugger
rust-gdb target/debug/ai-jail
```

### Logging

```bash
# Set log level
export RUST_LOG=debug
cargo run

# Module-specific logging
export RUST_LOG=ai_jail::inference=trace
cargo run

# Log to file
cargo run 2> debug.log
```

### Common Issues

1. **Out of Memory**
   - Use Q4 quantization
   - Reduce max_tokens
   - Check VRAM with `nvidia-smi`

2. **Slow Inference**
   - Verify GPU is being used
   - Check if flash attention is enabled
   - Profile with flamegraph

3. **Model Loading Fails**
   - Verify model files exist
   - Check file permissions
   - Ensure correct safetensors format

## Adding New Features

### 1. New Protocol Fields

Edit `src/protocol.rs`:

```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InferenceRequest {
    // ... existing fields

    /// New field
    #[serde(skip_serializing_if = "Option::is_none")]
    pub new_field: Option<String>,
}
```

Add validation:
```rust
impl InferenceRequest {
    pub fn validate(&self) -> Result<(), String> {
        // ... existing validation

        if let Some(ref field) = self.new_field {
            if field.is_empty() {
                return Err("New field cannot be empty".to_string());
            }
        }

        Ok(())
    }
}
```

Add tests:
```rust
#[test]
fn test_new_field_validation() {
    // ...
}
```

### 2. New Sampling Parameters

Edit `src/inference.rs`:

```rust
pub struct SamplingParams {
    // ... existing fields

    /// New parameter
    pub new_param: f64,
}
```

Update logic:
```rust
impl LogitsProcessor {
    pub fn sample(&mut self, logits: &Tensor) -> Result<u32> {
        // Apply new parameter
        // ...
    }
}
```

### 3. New Model Types

Edit `src/model.rs`:

```rust
pub enum ModelType {
    Mistral7B,
    Llama2_7B,  // New model
}

impl LoadedModel {
    pub fn load(config: ModelConfig) -> Result<Self> {
        match config.model_type {
            ModelType::Mistral7B => Self::load_mistral(config),
            ModelType::Llama2_7B => Self::load_llama2(config),
        }
    }
}
```

## Security Considerations

### Network Isolation

Always run with `--network=none`:
```bash
podman run --network=none ai-jail:latest
```

### Filesystem Access

Mount models read-only:
```bash
-v /models:/models:ro
```

### Capabilities

Drop all capabilities:
```bash
--cap-drop=ALL
```

### User Permissions

Run as non-root:
```bash
USER aijail  # In Containerfile
```

## Release Process

### 1. Version Bump

Edit `Cargo.toml`:
```toml
[package]
version = "0.2.0"  # Increment version
```

### 2. Update Changelog

Document changes in README.md or CHANGELOG.md

### 3. Run Full Test Suite

```bash
./test.sh
cargo test -- --ignored  # Run all tests including those needing models
```

### 4. Build Release

```bash
cargo build --release --locked
strip target/release/ai-jail
```

### 5. Build Container

```bash
./build.sh
podman tag ai-jail:latest ai-jail:0.2.0
```

### 6. Tag Release

```bash
git tag v0.2.0
git push origin v0.2.0
```

## Troubleshooting Development Issues

### Cargo Build Fails

```bash
# Clean and rebuild
cargo clean
cargo build

# Update dependencies
cargo update

# Check for conflicts
cargo tree
```

### Tests Fail

```bash
# Run single test with output
cargo test test_name -- --nocapture

# Run with backtrace
RUST_BACKTRACE=1 cargo test

# Update test snapshots (if using insta)
cargo insta review
```

### Container Build Fails

```bash
# Check Podman version
podman --version

# Clean build cache
podman system prune -a

# Build with no cache
podman build --no-cache -t ai-jail:latest .
```

## Resources

- [Candle Documentation](https://github.com/huggingface/candle)
- [Rust Book](https://doc.rust-lang.org/book/)
- [Podman Documentation](https://docs.podman.io/)
- [Mistral AI](https://mistral.ai/)

## Getting Help

- Check existing issues in the repository
- Review logs with `RUST_LOG=debug`
- Ask in project discussions
- File a bug report with full context
