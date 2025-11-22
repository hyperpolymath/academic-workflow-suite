# Architecture Documentation

**Technical architecture of the Academic Workflow Suite**

This document provides a comprehensive technical overview of AWS's architecture, design patterns, and implementation details.

---

## Table of Contents

- [System Overview](#system-overview)
- [Architectural Principles](#architectural-principles)
- [Component Architecture](#component-architecture)
- [Event Sourcing Design](#event-sourcing-design)
- [Privacy Architecture](#privacy-architecture)
- [AI Isolation Design](#ai-isolation-design)
- [Database Schema](#database-schema)
- [API Specifications](#api-specifications)
- [Data Flow](#data-flow)
- [Security Model](#security-model)
- [Performance Considerations](#performance-considerations)
- [Deployment Architecture](#deployment-architecture)

---

## System Overview

AWS is built as a **privacy-first, event-sourced, microservices-inspired** system with strict isolation boundaries.

### High-Level Architecture

```
┌───────────────────────────────────────────────────────────────────┐
│                         USER ENVIRONMENT                           │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │              Presentation Layer                              │ │
│  │  ┌────────────────────────────────────────────────────────┐  │ │
│  │  │  Microsoft Word + AWS Office Add-in (ReScript)         │  │ │
│  │  │  - Task pane UI                                        │  │ │
│  │  │  - Document manipulation (Office.js)                   │  │ │
│  │  │  - Client-side state management                        │  │ │
│  │  └────────────────────┬───────────────────────────────────┘  │ │
│  └───────────────────────┼──────────────────────────────────────┘ │
│                          │                                         │
│                          │ HTTPS/TLS 1.3 (localhost:8080)          │
│                          │                                         │
│  ┌───────────────────────▼──────────────────────────────────────┐ │
│  │              Application Layer (Rust)                        │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │ │
│  │  │  REST API    │  │  Business    │  │  Anonymization   │   │ │
│  │  │  (Actix-Web) │  │  Logic       │  │  Engine          │   │ │
│  │  └──────────────┘  └──────────────┘  └──────────────────┘   │ │
│  └───────────────────────┬──────────────────────────────────────┘ │
│                          │                                         │
│  ┌───────────────────────▼──────────────────────────────────────┐ │
│  │              Persistence Layer                               │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │ │
│  │  │  Event Store │  │  Read Models │  │  File Storage    │   │ │
│  │  │  (LMDB)      │  │  (In-Memory) │  │  (File System)   │   │ │
│  │  └──────────────┘  └──────────────┘  └──────────────────┘   │ │
│  └───────────────────────┬──────────────────────────────────────┘ │
│                          │                                         │
│                          │ Unix Socket (IPC)                       │
│                          │                                         │
│  ┌───────────────────────▼──────────────────────────────────────┐ │
│  │              AI Isolation Layer                              │ │
│  │  ┌────────────────────────────────────────────────────────┐  │ │
│  │  │  Sandboxed Container (gVisor/Firecracker)             │  │ │
│  │  │  ┌──────────┐  ┌───────────┐  ┌───────────────────┐  │  │ │
│  │  │  │ AI Model │  │ Inference │  │ No Network Access │  │  │ │
│  │  │  │ (ONNX)   │  │ Engine    │  │ No PII            │  │  │ │
│  │  │  └──────────┘  └───────────┘  └───────────────────┘  │  │ │
│  │  └────────────────────────────────────────────────────────┘  │ │
│  └──────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
                          │
                          │ HTTPS (Optional)
                          │
            ┌─────────────▼────────────────┐
            │   Backend Services (Optional) │
            │   - Rubric repository         │
            │   - Update server             │
            │   - No student data           │
            └───────────────────────────────┘
```

### Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | ReScript, Office.js, Webpack | Office add-in UI |
| **API** | Rust, Actix-Web, Tokio | REST API server |
| **Business Logic** | Rust | Core domain logic |
| **Persistence** | LMDB (via Heed) | Event store |
| **AI Runtime** | ONNX Runtime, llama.cpp | ML inference |
| **Isolation** | Docker/Podman, gVisor | Sandboxing |
| **Crypto** | SHA3 (FIPS 202) | Hashing |

---

## Architectural Principles

### 1. Privacy by Design

**Principle**: Student data never reaches AI systems in identifiable form.

**Implementation**:
- Cryptographic one-way hashing at the boundary
- AI jail receives only anonymized data
- No network access from AI jail
- Audit trail of all data access

### 2. Event Sourcing

**Principle**: All state changes captured as immutable events.

**Benefits**:
- Complete audit trail
- Time-travel debugging
- Replay capability
- GDPR compliance (right to explanation)

### 3. Local-First

**Principle**: Core functionality works offline.

**Implementation**:
- All student data stored locally
- AI models run on-device
- Optional backend for updates only
- No cloud dependency

### 4. Fail-Safe

**Principle**: Tutor override at every decision point.

**Implementation**:
- AI provides suggestions, not decisions
- All AI output is editable
- Manual mode always available
- Graceful degradation without AI

### 5. Separation of Concerns

**Principle**: Clear boundaries between components.

**Implementation**:
- Office add-in: UI only
- Core engine: Business logic
- AI jail: Isolated inference
- Backend: Shared resources (optional)

---

## Component Architecture

### 1. Office Add-in

**Technology**: ReScript → JavaScript, Office.js

**Responsibilities**:
- Render UI in Word task pane
- Parse Word document structure
- Display feedback and scores
- Insert comments into document
- Handle user interactions

**Architecture**:

```
Office Add-in (ReScript)
├── UI Components
│   ├── TaskPane.res           # Main UI
│   ├── RubricSelector.res     # Rubric selection
│   ├── FeedbackEditor.res     # Feedback editing
│   └── ProgressIndicator.res  # Analysis progress
├── State Management
│   ├── AppState.res           # Application state
│   ├── Actions.res            # State transitions
│   └── Reducers.res           # State update logic
├── API Client
│   ├── CoreClient.res         # HTTP client for Core API
│   ├── RequestTypes.res       # Request/response types
│   └── ErrorHandling.res      # Error handling
├── Office Integration
│   ├── DocumentParser.res     # Parse Word documents
│   ├── CommentInserter.res    # Insert Word comments
│   └── ExportHandler.res      # Export marked documents
└── Utils
    ├── Validation.res         # Input validation
    └── Formatting.res         # Text formatting
```

**Communication**:

```
Word Add-in
     │
     │ HTTP POST /api/analyze
     │ { "document": "...", "rubric_id": "..." }
     ▼
Core Engine
     │
     │ 200 OK
     │ { "feedback": [...], "scores": {...} }
     ▼
Word Add-in
```

### 2. Core Engine

**Technology**: Rust, Actix-Web, Tokio

**Responsibilities**:
- REST API server
- Event store management
- Business logic (rubric evaluation)
- Student ID anonymization
- AI jail orchestration

**Architecture**:

```
Core Engine (Rust)
├── HTTP Server (Actix-Web)
│   ├── routes/
│   │   ├── analyze.rs         # POST /api/analyze
│   │   ├── rubrics.rs         # GET/POST /api/rubrics
│   │   ├── exports.rs         # POST /api/export
│   │   └── health.rs          # GET /health
│   └── middleware/
│       ├── auth.rs            # Authentication (future)
│       ├── logging.rs         # Request logging
│       └── error_handler.rs   # Error handling
├── Domain Logic
│   ├── anonymization/
│   │   ├── hasher.rs          # SHA3-512 hashing
│   │   └── mapper.rs          # Hash ↔ ID mapping
│   ├── rubric/
│   │   ├── model.rs           # Rubric data structures
│   │   ├── evaluator.rs       # Scoring logic
│   │   └── repository.rs      # Rubric storage
│   └── feedback/
│       ├── generator.rs       # Feedback generation
│       └── editor.rs          # Feedback editing
├── Event Store
│   ├── store.rs               # LMDB wrapper
│   ├── events.rs              # Event definitions
│   ├── projections.rs         # Read model builders
│   └── snapshots.rs           # Snapshot management
├── AI Jail Client
│   ├── client.rs              # Unix socket client
│   ├── protocol.rs            # IPC protocol
│   └── sandbox.rs             # Container management
└── Utils
    ├── config.rs              # Configuration management
    └── logging.rs             # Structured logging
```

**Event Flow**:

```
1. User Action (e.g., "Analyze Document")
         ↓
2. API Handler receives HTTP request
         ↓
3. Command created (e.g., AnalyzeDocument)
         ↓
4. Business logic processes command
         ↓
5. Events emitted (e.g., DocumentAnalyzed)
         ↓
6. Events persisted to LMDB
         ↓
7. Read models updated (in-memory projections)
         ↓
8. HTTP response sent to client
```

### 3. AI Jail

**Technology**: Rust, ONNX Runtime, Docker/gVisor

**Responsibilities**:
- Run AI inference in isolation
- Receive anonymized data only
- No network access
- Limited filesystem access

**Architecture**:

```
AI Jail (Sandboxed Container)
├── Container Runtime
│   ├── gVisor (recommended)       # Lightweight VM isolation
│   └── Docker/Podman              # Container runtime
├── Inference Engine
│   ├── onnx_runtime.rs            # ONNX inference
│   ├── llama_cpp.rs               # LLM inference (optional)
│   └── model_loader.rs            # Model initialization
├── IPC Server
│   ├── unix_socket_server.rs     # Listens on Unix socket
│   ├── protocol_handler.rs       # Request/response handling
│   └── timeout_manager.rs        # Request timeout handling
├── Models (Read-Only)
│   ├── rubric_classifier.onnx    # Rubric criterion matching
│   ├── feedback_generator.onnx   # Feedback generation
│   └── config.json               # Model metadata
└── Security
    ├── no_network.rs              # Network blocking
    ├── filesystem_jail.rs         # Filesystem restrictions
    └── memory_limit.rs            # Memory constraints
```

**Isolation Guarantees**:

```
┌─────────────────────────────────────────────┐
│  AI Jail Container                          │
│  ┌───────────────────────────────────────┐  │
│  │  Restrictions:                        │  │
│  │  ✗ No network access (iptables DROP)  │  │
│  │  ✗ No disk writes (read-only FS)      │  │
│  │  ✗ Limited memory (4 GB max)          │  │
│  │  ✗ Limited CPU (2 cores max)          │  │
│  │  ✗ No GPU access                      │  │
│  │  ✗ No system calls (seccomp filter)   │  │
│  └───────────────────────────────────────┘  │
│                                             │
│  Allowed:                                   │
│  ✓ Unix socket IPC (to Core)                │
│  ✓ Read AI models (read-only mount)         │
│  ✓ In-memory computation                    │
└─────────────────────────────────────────────┘
```

### 4. Backend (Optional)

**Technology**: Rust, Actix-Web, PostgreSQL (for future features)

**Responsibilities**:
- Serve rubric repository
- Distribute software updates
- Collect anonymous usage stats (opt-in)
- **Never stores student data**

**Architecture**:

```
Backend Services (Cloud)
├── Rubric Repository
│   ├── GET /rubrics/{module}/{assignment}
│   └── POST /rubrics (by module coordinators)
├── Update Server
│   ├── GET /updates/latest
│   └── GET /updates/download/{version}
└── Telemetry (Opt-In)
    └── POST /telemetry/anonymous
        # No student data, only:
        # - AWS version
        # - OS type
        # - Feature usage counts
```

---

## Event Sourcing Design

### Event Store Structure

AWS uses **event sourcing** as the primary persistence mechanism.

**Why Event Sourcing?**

1. **Audit Trail**: Every action is recorded
2. **Temporal Queries**: "What was the state on Nov 15?"
3. **Debugging**: Replay events to reproduce bugs
4. **GDPR Compliance**: Prove how decisions were made
5. **Undo/Redo**: Natural support for undo operations

### Event Types

```rust
#[derive(Serialize, Deserialize, Clone)]
enum Event {
    // Document Events
    DocumentLoaded {
        document_id: Uuid,
        student_id_hash: Hash,  // SHA3-512 hash, not plaintext!
        module: String,
        assignment: String,
        timestamp: DateTime<Utc>,
    },

    // Anonymization Events
    StudentIdAnonymized {
        original_id: String,     // Stored separately, encrypted
        hash: Hash,              // SHA3-512 hash
        salt: [u8; 32],          // Random salt
        timestamp: DateTime<Utc>,
    },

    // AI Analysis Events
    AnalysisRequested {
        document_id: Uuid,
        student_id_hash: Hash,
        rubric_id: Uuid,
        timestamp: DateTime<Utc>,
    },

    AnalysisCompleted {
        document_id: Uuid,
        student_id_hash: Hash,
        ai_suggestions: Vec<Suggestion>,
        scores: HashMap<CriterionId, Score>,
        duration_ms: u64,
        timestamp: DateTime<Utc>,
    },

    // Feedback Events
    FeedbackEdited {
        document_id: Uuid,
        criterion_id: CriterionId,
        original_text: String,   // AI suggestion
        edited_text: String,     // Tutor's version
        tutor_id: String,
        timestamp: DateTime<Utc>,
    },

    FeedbackInserted {
        document_id: Uuid,
        timestamp: DateTime<Utc>,
    },

    // Export Events
    DocumentExported {
        document_id: Uuid,
        format: ExportFormat,    // PDF, Word, Text
        destination: PathBuf,
        timestamp: DateTime<Utc>,
    },
}
```

### Event Stream Example

```
Time     | Event                        | Details
---------|------------------------------|----------------------------
14:32:01 | DocumentLoaded               | TM112-TMA01, Hash: 7f3a2b...
14:32:02 | StudentIdAnonymized          | A1234567 → 7f3a2b...
14:32:15 | RubricLoaded                 | TM112-TMA01-Official
14:32:18 | AnalysisRequested            | Document: uuid-123
14:32:47 | AnalysisCompleted            | 4 suggestions, 29 seconds
14:35:22 | FeedbackEdited               | Criterion: Understanding
         |                              | AI: "Good work" → "Excellent"
14:35:45 | FeedbackEdited               | Criterion: Analysis
         |                              | AI suggestion rejected
14:36:10 | FeedbackInserted             | Into Word document
14:36:32 | DocumentExported             | Format: PDF
```

### LMDB Schema

```
Database: event_store.lmdb

Key-Value Store:

# Events (append-only)
Key: event:{sequence_number}
Value: Event (serialized with bincode)

Example:
event:1 → DocumentLoaded { ... }
event:2 → StudentIdAnonymized { ... }
event:3 → AnalysisRequested { ... }

# Indices for fast queries
Key: document:{document_id}
Value: [event_seq_1, event_seq_2, ...]

Key: student_hash:{hash}
Value: [event_seq_1, event_seq_2, ...]

Key: timestamp:{yyyymmdd}:{sequence}
Value: event_sequence_number

# Snapshots (for performance)
Key: snapshot:{document_id}:{version}
Value: DocumentSnapshot (reconstructed state)

# Metadata
Key: meta:last_sequence
Value: 12345 (u64)

Key: meta:version
Value: "0.1.0" (String)
```

### Event Replay

To reconstruct state:

```rust
fn rebuild_document_state(document_id: Uuid) -> Document {
    let events = event_store.get_events_for_document(document_id);
    let mut state = DocumentState::new();

    for event in events {
        state = apply_event(state, event);
    }

    state.into_document()
}

fn apply_event(mut state: DocumentState, event: Event) -> DocumentState {
    match event {
        Event::DocumentLoaded { module, assignment, .. } => {
            state.module = module;
            state.assignment = assignment;
        }
        Event::AnalysisCompleted { ai_suggestions, scores, .. } => {
            state.suggestions = ai_suggestions;
            state.scores = scores;
        }
        Event::FeedbackEdited { criterion_id, edited_text, .. } => {
            state.feedback.insert(criterion_id, edited_text);
        }
        // ... other events
    }
    state
}
```

### Projections (Read Models)

For performance, maintain in-memory projections:

```rust
struct DocumentProjection {
    documents: HashMap<Uuid, DocumentState>,
}

impl DocumentProjection {
    fn handle_event(&mut self, event: &Event) {
        match event {
            Event::DocumentLoaded { document_id, .. } => {
                self.documents.insert(*document_id, DocumentState::new());
            }
            Event::FeedbackEdited { document_id, criterion_id, edited_text, .. } => {
                if let Some(doc) = self.documents.get_mut(document_id) {
                    doc.feedback.insert(*criterion_id, edited_text.clone());
                }
            }
            // ... other events
        }
    }
}
```

---

## Privacy Architecture

### Anonymization Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  Step 1: Tutor opens TMA document                               │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Student ID: A1234567                                     │  │
│  │  Name: Jane Smith                                         │  │
│  │  Module: TM112                                            │  │
│  │  Essay: "In this assignment, I will discuss..."          │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│  Step 2: Core Engine extracts identifiers                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Student ID: A1234567                                     │  │
│  │  Name: Jane Smith                                         │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│  Step 3: Anonymization (SHA3-512 with salt)                     │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Input: "A1234567" + salt (32 random bytes)               │  │
│  │         ↓ SHA3-512                                        │  │
│  │  Hash: 7f3a2b9c8e1d4a5c6f8b9e2d3c4a5b6c7d8e9f0a1b2c...   │  │
│  │                                                           │  │
│  │  Mapping stored (encrypted):                              │  │
│  │  Hash → Student ID (for re-association later)            │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│  Step 4: AI Jail receives anonymized data                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Hash: 7f3a2b9c8e1d4a5c6f8b9e2d3c4a5b6c7d8e9f0a1b2c...   │  │
│  │  Essay: "In this assignment, I will discuss..."          │  │
│  │  Rubric: [Understanding: 30 marks, Analysis: 30 marks]   │  │
│  │                                                           │  │
│  │  ❌ No student ID                                         │  │
│  │  ❌ No name                                               │  │
│  │  ❌ No network access                                     │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│  Step 5: AI analysis (cannot re-identify)                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  AI Model analyzes essay against rubric                  │  │
│  │  Generates feedback for Hash: 7f3a2b9c...                │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│  Step 6: Core Engine re-associates                              │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Hash: 7f3a2b9c... → Student ID: A1234567                │  │
│  │  Feedback: "Good understanding..."                        │  │
│  │  Scores: [Understanding: 24/30, Analysis: 22/30]         │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│  Step 7: Tutor reviews in Word add-in                           │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Student: A1234567 - Jane Smith                           │  │
│  │  Suggested Feedback: "Good understanding..."              │  │
│  │  Tutor edits and finalizes                                │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Cryptographic Details

```rust
use sha3::{Sha3_512, Digest};

fn anonymize_student_id(student_id: &str, salt: &[u8; 32]) -> Hash {
    let mut hasher = Sha3_512::new();
    hasher.update(student_id.as_bytes());
    hasher.update(salt);
    let result = hasher.finalize();

    Hash {
        algorithm: "SHA3-512",
        value: result.to_vec(),
    }
}

// Salt generation (cryptographically secure)
use rand::rngs::OsRng;
use rand::RngCore;

fn generate_salt() -> [u8; 32] {
    let mut salt = [0u8; 32];
    OsRng.fill_bytes(&mut salt);
    salt
}
```

**Why SHA3-512?**

- **One-way**: Cannot reverse hash to get student ID
- **Collision-resistant**: Virtually impossible for two IDs to have same hash
- **FIPS 202 compliant**: Standardized cryptographic hash
- **512 bits = 2^512 possible outputs**: Infeasible to brute force

**Attack Resistance**:

| Attack Type | Mitigation |
|-------------|------------|
| Rainbow Table | Salt prevents precomputed hash tables |
| Brute Force | 2^512 search space (universe has ~2^266 atoms) |
| Side Channel | Constant-time hashing implementation |
| Timing Attack | No early exit, constant execution time |

---

## AI Isolation Design

### Container-Based Isolation

```
┌─────────────────────────────────────────────────────────────┐
│  Host Operating System                                      │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  gVisor (User-Space Kernel)                           │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │  AI Jail Container                              │  │  │
│  │  │  ┌───────────────────────────────────────────┐  │  │  │
│  │  │  │  AI Inference Process                     │  │  │  │
│  │  │  │  - Reads AI model (read-only)             │  │  │  │
│  │  │  │  - Processes anonymized data              │  │  │  │
│  │  │  │  - Returns feedback via Unix socket       │  │  │  │
│  │  │  └───────────────────────────────────────────┘  │  │  │
│  │  │                                                 │  │  │
│  │  │  Network: ✗ Disabled (iptables DROP all)       │  │  │
│  │  │  Filesystem: ✗ Read-only (except /tmp)         │  │  │
│  │  │  System Calls: ✗ Filtered (seccomp)            │  │  │
│  │  │  Memory: ✓ Limited (4 GB max, cgroup)          │  │  │
│  │  │  CPU: ✓ Limited (2 cores, cgroup)              │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Security Controls

**1. Network Isolation**

```dockerfile
# Dockerfile for AI Jail
FROM rust:1.75-slim

# Disable networking entirely
RUN iptables -P INPUT DROP && \
    iptables -P FORWARD DROP && \
    iptables -P OUTPUT DROP

# Allow only Unix socket communication
VOLUME /var/run/aws-jail.sock
```

**2. Filesystem Restrictions**

```yaml
# Docker Compose configuration
services:
  ai-jail:
    image: aws-ai-jail:latest
    volumes:
      - ./models:/models:ro          # Read-only AI models
      - ./jail.sock:/run/jail.sock   # Unix socket for IPC
    read_only: true                   # Read-only root filesystem
    tmpfs:
      - /tmp:size=1G,mode=1777       # Small temp space
```

**3. System Call Filtering (seccomp)**

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "syscalls": [
    {
      "names": ["read", "write", "open", "close", "mmap", "brk"],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

Only essential system calls allowed:
- `read`, `write`: File I/O
- `mmap`, `brk`: Memory allocation
- No `socket`, `connect`, `sendto` (network)
- No `execve`, `fork` (process creation)

**4. Resource Limits (cgroups)**

```bash
# Memory limit: 4 GB
docker run --memory=4g --memory-swap=4g aws-ai-jail

# CPU limit: 2 cores
docker run --cpus=2 aws-ai-jail

# No GPU access
docker run --gpus=0 aws-ai-jail
```

### IPC Protocol

Communication via Unix domain socket:

```rust
// Core → AI Jail: Request
struct AnalysisRequest {
    request_id: Uuid,
    student_hash: Hash,        // Anonymized!
    essay_text: String,
    rubric: Rubric,
    timeout_ms: u64,
}

// AI Jail → Core: Response
struct AnalysisResponse {
    request_id: Uuid,
    student_hash: Hash,        // Same hash, no re-identification
    feedback: Vec<Suggestion>,
    scores: HashMap<CriterionId, f64>,
    confidence: f64,
}
```

**Protocol Flow**:

```
Core Engine                          AI Jail
     │                                   │
     │ 1. Open Unix socket               │
     │────────────────────────────────►  │
     │                                   │
     │ 2. Send AnalysisRequest           │
     │    (with anonymized data)         │
     │────────────────────────────────►  │
     │                                   │
     │                                   │ 3. Load AI model
     │                                   │    (from read-only FS)
     │                                   │
     │                                   │ 4. Run inference
     │                                   │    (in-memory only)
     │                                   │
     │ 5. Receive AnalysisResponse       │
     │◄────────────────────────────────  │
     │                                   │
     │ 6. Close socket                   │
     │────────────────────────────────►  │
     │                                   │
     │                                   │ 7. Container destroyed
     │                                   │    (no persistent state)
```

---

## Database Schema

### LMDB Event Store

```
Database Structure:

┌─────────────────────────────────────────────────────────┐
│  event_store.lmdb                                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Table: events (main event log)                         │
│  ┌────────────────┬─────────────────────────────────┐  │
│  │ Key            │ Value                           │  │
│  ├────────────────┼─────────────────────────────────┤  │
│  │ event:0000001  │ DocumentLoaded { ... }          │  │
│  │ event:0000002  │ StudentIdAnonymized { ... }     │  │
│  │ event:0000003  │ AnalysisRequested { ... }       │  │
│  │ ...            │ ...                             │  │
│  └────────────────┴─────────────────────────────────┘  │
│                                                         │
│  Table: document_index                                  │
│  ┌────────────────────────┬───────────────────────┐    │
│  │ Key                    │ Value                 │    │
│  ├────────────────────────┼───────────────────────┤    │
│  │ doc:uuid-123           │ [1, 2, 5, 8, 12]      │    │
│  │ doc:uuid-456           │ [3, 4, 6, 9]          │    │
│  └────────────────────────┴───────────────────────┘    │
│                                                         │
│  Table: student_hash_index                              │
│  ┌────────────────────────┬───────────────────────┐    │
│  │ Key                    │ Value                 │    │
│  ├────────────────────────┼───────────────────────┤    │
│  │ hash:7f3a2b...         │ [1, 2, 3, 5]          │    │
│  │ hash:9e1d4c...         │ [4, 6, 7]             │    │
│  └────────────────────────┴───────────────────────┘    │
│                                                         │
│  Table: snapshots (performance optimization)            │
│  ┌────────────────────────┬───────────────────────┐    │
│  │ Key                    │ Value                 │    │
│  ├────────────────────────┼───────────────────────┤    │
│  │ snap:uuid-123:v5       │ DocumentSnapshot      │    │
│  │ snap:uuid-456:v3       │ DocumentSnapshot      │    │
│  └────────────────────────┴───────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### In-Memory Projections

For fast queries, maintain in-memory views:

```rust
struct InMemoryProjections {
    // Active documents
    documents: HashMap<Uuid, DocumentState>,

    // Rubrics
    rubrics: HashMap<String, Rubric>,  // module-assignment → Rubric

    // Hash mappings (encrypted at rest)
    hash_to_student_id: HashMap<Hash, String>,

    // Statistics
    stats: MarkingStatistics,
}

struct DocumentState {
    document_id: Uuid,
    student_id_hash: Hash,
    module: String,
    assignment: String,
    rubric_id: Uuid,
    suggestions: Vec<Suggestion>,
    feedback: HashMap<CriterionId, String>,
    scores: HashMap<CriterionId, f64>,
    status: DocumentStatus,
    created_at: DateTime<Utc>,
    updated_at: DateTime<Utc>,
}
```

---

## API Specifications

See [API_REFERENCE.md](API_REFERENCE.md) for complete OpenAPI 3.0 specification.

### Core Endpoints

```
POST   /api/documents/load        Load a document for marking
POST   /api/analyze                Analyze document with AI
GET    /api/rubrics               List available rubrics
GET    /api/rubrics/{id}          Get specific rubric
POST   /api/feedback/edit         Edit AI-suggested feedback
POST   /api/export                Export marked document
GET    /health                    Health check
GET    /metrics                   Prometheus metrics (future)
```

### Example: Analyze Endpoint

**Request**:

```http
POST /api/analyze HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "document_id": "550e8400-e29b-41d4-a716-446655440000",
  "student_id": "A1234567",
  "module": "TM112",
  "assignment": "TMA01",
  "rubric_id": "123e4567-e89b-12d3-a456-426614174000",
  "essay_text": "In this assignment, I will discuss..."
}
```

**Response**:

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "document_id": "550e8400-e29b-41d4-a716-446655440000",
  "student_id_hash": "7f3a2b9c8e1d4a5c...",
  "analysis": {
    "suggestions": [
      {
        "criterion_id": "understanding",
        "score": 24.0,
        "max_score": 30.0,
        "feedback": "You demonstrate a solid understanding...",
        "confidence": 0.85
      },
      {
        "criterion_id": "analysis",
        "score": 22.0,
        "max_score": 30.0,
        "feedback": "Your critical analysis shows...",
        "confidence": 0.78
      }
    ],
    "total_score": 78.0,
    "total_possible": 100.0,
    "grade": "B+",
    "duration_ms": 2847
  },
  "privacy": {
    "student_id_anonymized": true,
    "ai_received_pii": false,
    "hash_algorithm": "SHA3-512"
  }
}
```

---

## Data Flow

### Complete Marking Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Tutor opens TMA in Word                                      │
│    ↓                                                             │
│ 2. AWS Add-in loads document                                    │
│    │ POST /api/documents/load                                   │
│    │ { "student_id": "A1234567", "content": "..." }             │
│    ↓                                                             │
│ 3. Core Engine processes                                        │
│    ├─ Anonymizes student ID (SHA3-512)                          │
│    ├─ Stores event: DocumentLoaded                              │
│    └─ Returns: { "document_id": "uuid-123", "hash": "7f3a..." } │
│    ↓                                                             │
│ 4. Tutor selects rubric and clicks "Analyze"                    │
│    │ POST /api/analyze                                          │
│    │ { "document_id": "uuid-123", "rubric_id": "uuid-456" }     │
│    ↓                                                             │
│ 5. Core Engine prepares anonymized data                         │
│    ├─ Fetches rubric                                            │
│    ├─ Creates AnalysisRequest                                   │
│    └─ Stores event: AnalysisRequested                           │
│    ↓                                                             │
│ 6. AI Jail receives request (Unix socket)                       │
│    ├─ Loads AI model                                            │
│    ├─ Runs inference on anonymized data                         │
│    └─ Returns suggestions and scores                            │
│    ↓                                                             │
│ 7. Core Engine receives AI response                             │
│    ├─ Re-associates hash with document ID                       │
│    ├─ Stores event: AnalysisCompleted                           │
│    └─ Returns to add-in                                         │
│    ↓                                                             │
│ 8. Add-in displays suggestions to tutor                         │
│    ↓                                                             │
│ 9. Tutor edits feedback                                         │
│    │ POST /api/feedback/edit                                    │
│    │ { "criterion_id": "...", "new_text": "..." }               │
│    ├─ Stores event: FeedbackEdited                              │
│    ↓                                                             │
│ 10. Tutor clicks "Insert Feedback"                              │
│     ├─ Add-in inserts comments into Word doc                    │
│     └─ Stores event: FeedbackInserted                           │
│     ↓                                                            │
│ 11. Tutor exports marked TMA                                    │
│     │ POST /api/export { "format": "pdf" }                      │
│     ├─ Generates PDF with feedback                              │
│     └─ Stores event: DocumentExported                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Security Model

See [SECURITY.md](SECURITY.md) for detailed security documentation.

### Threat Model

| Threat | Mitigation |
|--------|------------|
| AI re-identifies students | One-way hashing (SHA3-512), no reverse possible |
| Network exfiltration | AI jail has zero network access |
| Disk persistence of PII | AI jail filesystem is read-only |
| Memory scraping | Container destroyed after each use |
| Timing attacks | Constant-time hashing |
| Malicious AI model | Model signature verification |

### Defense in Depth

```
Layer 1: Anonymization (SHA3-512 hashing)
         ↓
Layer 2: Network isolation (iptables DROP)
         ↓
Layer 3: Filesystem restrictions (read-only)
         ↓
Layer 4: System call filtering (seccomp)
         ↓
Layer 5: Container isolation (gVisor)
         ↓
Layer 6: Resource limits (cgroups)
         ↓
Layer 7: Audit logging (every action)
```

---

## Performance Considerations

### Optimization Strategies

1. **Event Store Performance**
   - LMDB provides near-RAM speeds for reads
   - Snapshots reduce event replay time
   - In-memory projections for active documents

2. **AI Inference Performance**
   - Model preloading (lazy initialization)
   - Batching multiple analyses
   - Hardware acceleration (future: GPU support)

3. **Network Performance**
   - HTTP/2 for add-in ↔ core communication
   - Compression for large documents
   - WebSocket for real-time updates (future)

### Benchmarks (Reference Hardware: M1 MacBook Pro, 16 GB)

| Operation | Time | Notes |
|-----------|------|-------|
| Document load | 50-100 ms | Parse + anonymize |
| AI analysis | 10-30 seconds | Depends on essay length |
| Feedback edit | < 10 ms | In-memory update |
| Export to PDF | 200-500 ms | Depends on document size |
| Event store write | < 5 ms | LMDB transaction |
| Event replay | 10-50 ms | 1000 events |

---

## Deployment Architecture

### Single-User Deployment

```
┌─────────────────────────────────────────┐
│  Tutor's Laptop                         │
│  ┌───────────────────────────────────┐  │
│  │  Microsoft Word + AWS Add-in      │  │
│  └─────────────┬─────────────────────┘  │
│                │ localhost:8080         │
│  ┌─────────────▼─────────────────────┐  │
│  │  AWS Core Engine                  │  │
│  │  ~/.aws/data/ (LMDB)              │  │
│  └─────────────┬─────────────────────┘  │
│                │ Unix socket            │
│  ┌─────────────▼─────────────────────┐  │
│  │  AI Jail (Docker container)       │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Multi-User Deployment (Future)

```
┌────────────┐  ┌────────────┐  ┌────────────┐
│ Tutor 1    │  │ Tutor 2    │  │ Tutor 3    │
│ Word+AWS   │  │ Word+AWS   │  │ Word+AWS   │
└─────┬──────┘  └─────┬──────┘  └─────┬──────┘
      │               │               │
      │ HTTPS         │ HTTPS         │ HTTPS
      │               │               │
      └───────────────┼───────────────┘
                      │
            ┌─────────▼──────────┐
            │  Shared Backend    │
            │  (Rubric Repo)     │
            │  No Student Data   │
            └────────────────────┘
```

---

## Conclusion

AWS's architecture prioritizes **privacy**, **security**, and **auditability** while delivering a seamless user experience. The combination of event sourcing, AI isolation, and local-first design ensures that student data remains protected while still benefiting from AI assistance.

For implementation details, see:
- [API Reference](API_REFERENCE.md)
- [Security](SECURITY.md)
- [Development Guide](DEVELOPMENT.md)

---

**Last Updated**: 2025-11-22
**Architecture Version**: 0.1.0
