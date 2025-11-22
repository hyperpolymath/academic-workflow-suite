# AI Jail - Network-Isolated AI Inference Container

The AI Jail is a secure, network-isolated container for running AI inference on academic TMA (Tutor-Marked Assignment) submissions. It uses the Candle ML framework to run Mistral 7B locally without any network access.

## Architecture

```
┌─────────────────────────────────────────────┐
│          Podman Container (no network)      │
│  ┌───────────────────────────────────────┐  │
│  │         AI Jail Binary                │  │
│  │                                       │  │
│  │  ┌─────────────┐  ┌───────────────┐  │  │
│  │  │   Model     │  │   Inference   │  │  │
│  │  │   Loader    │──│    Engine     │  │  │
│  │  └─────────────┘  └───────────────┘  │  │
│  │                                       │  │
│  │  ┌─────────────────────────────────┐  │  │
│  │  │   stdin/stdout IPC Protocol    │  │  │
│  │  └─────────────────────────────────┘  │  │
│  └───────────────────────────────────────┘  │
│                                             │
│  Volume: /models (read-only)               │
│    └── mistral-7b/                         │
│        ├── model.safetensors               │
│        └── tokenizer.json                  │
└─────────────────────────────────────────────┘
         ▲                    │
         │ JSON Request       │ JSON Response
         │                    ▼
   ┌─────────────────────────────────┐
   │     Orchestrator Process        │
   └─────────────────────────────────┘
```

## Features

- **Network Isolation**: Runs in Podman container with `--network=none`
- **Secure Communication**: stdin/stdout only, no sockets or HTTP servers
- **Memory Efficient**: 4-bit quantization to fit Mistral 7B in 8GB VRAM
- **Pure Rust**: No Python dependencies, fast startup time
- **Candle ML**: Uses HuggingFace's Candle framework for inference

## Requirements

### Build Requirements

- Rust 1.75 or later
- Podman or Docker
- ~10GB disk space for model files

### Runtime Requirements

- 8GB RAM (minimum)
- RTX 3080 or similar GPU (8GB VRAM) - optional, CPU fallback available
- Model files (Mistral 7B in safetensors format)

## Quick Start

### 1. Build the Binary

```bash
cd components/ai-jail
cargo build --release
```

### 2. Download Model Files

```bash
# Create models directory
mkdir -p /models/mistral-7b

# Download Mistral 7B (example using huggingface-cli)
# You'll need to download:
# - model.safetensors (or split files)
# - tokenizer.json
# - config.json

huggingface-cli download mistralai/Mistral-7B-v0.1 \
  --local-dir /models/mistral-7b \
  --include "*.safetensors" "*.json"
```

### 3. Build Container Image

```bash
podman build -t ai-jail:latest -f Containerfile .
```

### 4. Run the Container

```bash
# Run with network isolation
podman run --rm -i \
  --network=none \
  --security-opt=no-new-privileges \
  --cap-drop=ALL \
  -v /models:/models:ro \
  ai-jail:latest
```

## Usage

### Input Format (stdin)

```json
{
  "tma_content": "Discuss the impact of climate change on global biodiversity.",
  "rubric": "Award 10 marks for comprehensive discussion covering at least 3 ecosystems.",
  "question_number": 1,
  "student_answer": "Climate change affects many animals and plants...",
  "max_tokens": 512,
  "temperature": 0.7,
  "top_p": 0.9
}
```

### Output Format (stdout)

**Success Response:**
```json
{
  "status": "success",
  "feedback": "The student's answer demonstrates a basic understanding...",
  "confidence": 0.85,
  "rubric_alignment": 0.72,
  "tokens_generated": 247,
  "inference_time_ms": 3421
}
```

**Error Response:**
```json
{
  "status": "error",
  "error_type": "inference_error",
  "message": "Model failed to generate output",
  "details": "..."
}
```

## Configuration

Environment variables:

- `MODEL_PATH`: Path to model.safetensors (default: `/models/mistral-7b/model.safetensors`)
- `TOKENIZER_PATH`: Path to tokenizer.json (default: `/models/mistral-7b/tokenizer.json`)
- `QUANTIZATION`: Quantization mode: `none`, `q8`, `q4` (default: `q4`)
- `RUST_LOG`: Log level: `error`, `warn`, `info`, `debug`, `trace` (default: `info`)

## Memory Usage

| Quantization | Model Size | VRAM Usage | Inference Speed |
|--------------|------------|------------|-----------------|
| None (FP16)  | ~14 GB     | ~14 GB     | Fast            |
| Q8           | ~7 GB      | ~7 GB      | Fast            |
| Q4           | ~3.5 GB    | ~4 GB      | Medium          |

The default Q4 configuration fits comfortably in 8GB VRAM with room for context.

## Testing

```bash
# Run unit tests
cargo test

# Run integration tests
cargo test --test test_isolation

# Run specific test
cargo test test_stdin_stdout_protocol
```

### Manual Testing

```bash
# Start the binary
cargo run --release

# In another terminal, send a request
echo '{
  "tma_content": "Test question",
  "rubric": "Award points for accuracy",
  "question_number": 1,
  "max_tokens": 100
}' | nc localhost 8080
```

## Security Features

1. **Network Isolation**: Container runs with `--network=none`
2. **No New Privileges**: `--security-opt=no-new-privileges`
3. **Dropped Capabilities**: `--cap-drop=ALL`
4. **Non-root User**: Runs as `aijail` user (UID 1000)
5. **Read-only Model Mount**: Models mounted as `:ro`
6. **No Filesystem Write**: Container filesystem is read-only except /tmp

## Performance Optimization

### For RTX 3080 (8GB VRAM)

```bash
# Use Q4 quantization
export QUANTIZATION=q4

# Enable flash attention (if supported)
export USE_FLASH_ATTN=true

# Limit max tokens for faster inference
export DEFAULT_MAX_TOKENS=512
```

### For CPU-only Systems

```bash
# Candle will automatically fall back to CPU
# Consider using Q8 or Q4 for better performance
export QUANTIZATION=q4
```

## Troubleshooting

### Out of Memory Errors

```bash
# Use more aggressive quantization
export QUANTIZATION=q4

# Reduce max tokens
export DEFAULT_MAX_TOKENS=256
```

### Model Loading Fails

```bash
# Check model files exist
ls -lh /models/mistral-7b/

# Verify permissions
podman run --rm -v /models:/models:ro debian:bookworm-slim ls -la /models/mistral-7b/

# Check logs
RUST_LOG=debug cargo run
```

### Container Won't Start

```bash
# Check Podman version
podman --version

# Verify container builds
podman build -t ai-jail:latest -f Containerfile .

# Test without network isolation first
podman run --rm -i -v /models:/models:ro ai-jail:latest
```

## Development

### Project Structure

```
ai-jail/
├── Cargo.toml                 # Dependencies and metadata
├── Containerfile              # Container image definition
├── README.md                  # This file
├── src/
│   ├── main.rs               # Entry point and IPC handling
│   ├── model.rs              # Model loading with Candle
│   ├── inference.rs          # Text generation engine
│   └── protocol.rs           # Request/response definitions
└── tests/
    └── test_isolation.rs     # Integration tests
```

### Adding Features

1. Update `protocol.rs` for new request/response fields
2. Implement logic in `inference.rs`
3. Add tests in `tests/`
4. Update this README

### Code Style

```bash
# Format code
cargo fmt

# Run linter
cargo clippy

# Check for issues
cargo clippy -- -D warnings
```

## License

GPL-3.0 - See LICENSE file in repository root.

## Contributing

This is part of the Academic Workflow Suite. See the main repository for contribution guidelines.

## Related Components

- **Orchestrator**: Manages AI jail containers and routes requests
- **Anonymizer**: Removes PII before sending to AI jail
- **Audit Logger**: Records all AI interactions for compliance
- **API Gateway**: Provides REST API for TMA grading

## References

- [Candle ML Framework](https://github.com/huggingface/candle)
- [Mistral 7B Model](https://mistral.ai/)
- [Podman Documentation](https://docs.podman.io/)
