# AWAP Backend Architecture

## Overview

The AWAP (Academic Workflow Automation Platform) backend is a Phoenix-based Elixir application that serves as the orchestration layer for TMA (Tutor Marked Assignment) processing. It integrates multiple subsystems: Moodle LMS, Rust core engine, and AI feedback containers.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Phoenix Application                          │
│                   AwapBackend.Application                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   HTTP API   │  │  Telemetry   │  │   PubSub     │          │
│  │   Endpoint   │  │  Metrics     │  │   Events     │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Core Engine Worker Pool                      │   │
│  │  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐        │   │
│  │  │Worker 1│  │Worker 2│  │Worker N│  │Registry│        │   │
│  │  └────────┘  └────────┘  └────────┘  └────────┘        │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              AI Jail Manager                              │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐         │   │
│  │  │Container 1 │  │Container 2 │  │Container N │         │   │
│  │  │(Podman)    │  │(Podman)    │  │(Podman)    │         │   │
│  │  └────────────┘  └────────────┘  └────────────┘         │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Moodle      │  │ Core Bridge  │  │ Event Store  │          │
│  │  Sync        │  │ (Rust NIF)   │  │ Connection   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
   ┌─────────┐          ┌─────────┐         ┌─────────┐
   │ Moodle  │          │  Rust   │         │ Event   │
   │  LMS    │          │  Core   │         │ Store   │
   └─────────┘          └─────────┘         └─────────┘
```

## Core Components

### 1. Phoenix Endpoint (`AwapBackendWeb.Endpoint`)

**Location**: `/home/user/academic-workflow-suite/components/backend/lib/awap_backend_web/endpoint.ex`

**Responsibilities**:
- HTTP request handling
- WebSocket connections
- Static file serving
- Request logging and telemetry

**Key Features**:
- JSON API endpoints
- CORS support
- Request ID tracking
- Session management

### 2. API Controllers

#### TMA Controller (`AwapBackendWeb.API.TMAController`)

**Location**: `/home/user/academic-workflow-suite/components/backend/lib/awap_backend_web/controllers/api/tma_controller.ex`

**Endpoints**:
```
POST   /api/tmas              - Submit TMA for processing
GET    /api/tmas/:id          - Get TMA status
GET    /api/tmas              - List TMAs (with filters)
GET    /api/feedback/:tma_id  - Get generated feedback
```

#### Health Controller (`AwapBackendWeb.API.HealthController`)

**Location**: `/home/user/academic-workflow-suite/components/backend/lib/awap_backend_web/controllers/api/health_controller.ex`

**Endpoints**:
```
GET    /api/health            - System health check
```

### 3. Core Engine Worker Pool

**Location**: `/home/user/academic-workflow-suite/components/backend/lib/awap_backend/core/`

**Components**:
- **WorkerPool**: Supervises worker processes and job distribution
- **Worker**: Individual process that communicates with Rust core
- **WorkerSupervisor**: Dynamic supervisor for worker processes
- **JobRegistry**: ETS-based job tracking

**Flow**:
```
1. TMA submission → WorkerPool.process_tma()
2. WorkerPool assigns to available Worker
3. Worker calls CoreBridge functions
4. Results stored in database
5. Job status updated in Registry
```

### 4. Core Bridge (Rust Integration)

**Location**: `/home/user/academic-workflow-suite/components/backend/lib/awap_backend/core_bridge.ex`

**Communication Modes**:
- **Port**: Safer, runs Rust as separate process (default)
- **NIF**: Faster, direct function calls (optional with Rustler)

**Functions**:
- `anonymize_student/1` - Remove PII from submissions
- `parse_tma/1` - Extract structured data
- `generate_feedback/1` - Generate marking feedback
- `query_events/2` - Query event store

**Protocol** (Port mode):
```json
{
  "request_id": "abc123",
  "command": "parse_tma",
  "data": {...}
}
```

### 5. AI Jail Manager

**Location**: `/home/user/academic-workflow-suite/components/backend/lib/awap_backend/ai/`

**Components**:
- **Manager**: Orchestrates container lifecycle and request routing
- **Container**: Wraps Podman CLI for container operations

**Security Constraints**:
```bash
podman run -d \
  --network none \           # No network access
  --memory 2g \              # Memory limit
  --cpus 1.0 \               # CPU limit
  --read-only \              # Read-only filesystem
  --tmpfs /tmp \             # Writable tmp
  --security-opt no-new-privileges
```

**Features**:
- Container pooling (configurable max)
- Request queuing when pool exhausted
- Health monitoring
- Automatic restart on failure

### 6. Moodle Integration

**Location**: `/home/user/academic-workflow-suite/components/backend/lib/awap_backend/moodle.ex`

**Authentication**:
- OAuth2 (implemented)
- SAML (stub for extension)

**API Functions**:
- `get_assignments/2` - Fetch assignments for a course
- `download_submission/2` - Download single submission
- `download_submissions/2` - Download all submissions for assignment
- `upload_grade/2` - Upload grade and feedback

**Sync Scheduler** (`AwapBackend.Moodle.SyncScheduler`):
- Periodic sync (default: 15 minutes)
- Fetches new submissions
- Updates assignment metadata
- Configurable interval

### 7. Event Store

**Location**: `/home/user/academic-workflow-suite/components/backend/lib/awap_backend/event_store.ex`

**Purpose**:
- Audit trail for TMA processing
- Event sourcing for core engine
- Integration with EventStoreDB or similar

**Operations**:
- `append_event/2` - Write event to stream
- `read_stream/2` - Read events from stream
- `subscribe/1` - Subscribe to stream updates

## Database Schema

### TMAs Table

```sql
CREATE TABLE tmas (
  id UUID PRIMARY KEY,
  assignment_id VARCHAR NOT NULL,
  student_id VARCHAR NOT NULL,
  course_id VARCHAR NOT NULL,
  content JSONB NOT NULL,
  status VARCHAR NOT NULL DEFAULT 'pending',
  job_id VARCHAR,
  error_message TEXT,
  submitted_at TIMESTAMP NOT NULL,
  processed_at TIMESTAMP,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX ON tmas(assignment_id);
CREATE INDEX ON tmas(student_id);
CREATE INDEX ON tmas(status);
```

### Feedback Table

```sql
CREATE TABLE feedback (
  id UUID PRIMARY KEY,
  tma_id UUID NOT NULL REFERENCES tmas(id) ON DELETE CASCADE,
  grade FLOAT,
  feedback_text TEXT NOT NULL,
  marking_criteria JSONB,
  strengths TEXT[],
  improvements TEXT[],
  generated_at TIMESTAMP NOT NULL,
  reviewed_by VARCHAR,
  reviewed_at TIMESTAMP,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX ON feedback(tma_id);
```

### Audit Log Table

```sql
CREATE TABLE audit_log (
  id UUID PRIMARY KEY,
  action VARCHAR NOT NULL,
  resource_type VARCHAR NOT NULL,
  resource_id UUID,
  actor_id VARCHAR,
  actor_type VARCHAR,
  metadata JSONB DEFAULT '{}',
  ip_address VARCHAR,
  user_agent VARCHAR,
  result VARCHAR,
  error_message TEXT,
  timestamp TIMESTAMP NOT NULL
);

CREATE INDEX ON audit_log(action);
CREATE INDEX ON audit_log(resource_type, resource_id);
CREATE INDEX ON audit_log(timestamp);
```

## OTP Supervision Strategy

```
AwapBackend.Application (one_for_one)
├── AwapBackendWeb.Telemetry (permanent)
├── AwapBackend.Repo (permanent)
├── Phoenix.PubSub (permanent)
├── AwapBackendWeb.Endpoint (permanent)
├── AwapBackend.EventStore (permanent, with reconnect)
├── AwapBackend.CoreEngine.WorkerPool (one_for_one)
│   ├── Task.Supervisor (permanent)
│   ├── JobRegistry (permanent)
│   └── WorkerSupervisor (one_for_one, dynamic)
│       ├── Worker 1 (permanent)
│       ├── Worker 2 (permanent)
│       └── Worker N (permanent)
├── AwapBackend.AI.Manager (permanent)
│   └── Container monitoring (restart on failure)
└── AwapBackend.Moodle.SyncScheduler (permanent)
```

**Restart Strategies**:
- `one_for_one`: If a child crashes, only that child is restarted
- `permanent`: Always restart on termination
- Dynamic: Children can be added/removed at runtime

## Configuration

### Environment Variables

**Required**:
- `DATABASE_URL` - PostgreSQL connection string
- `SECRET_KEY_BASE` - Phoenix secret key
- `MOODLE_BASE_URL` - Moodle instance URL
- `MOODLE_CLIENT_ID` - OAuth2 client ID
- `MOODLE_CLIENT_SECRET` - OAuth2 client secret

**Optional**:
- `CORE_EXECUTABLE` - Path to Rust core binary
- `EVENT_STORE_URL` - Event store connection
- `AI_CONTAINER_IMAGE` - Docker/Podman image for AI
- `MAX_AI_CONTAINERS` - Container pool size
- `POOL_SIZE` - Database connection pool size

### Configuration Files

- `config/config.exs` - Shared configuration
- `config/dev.exs` - Development overrides
- `config/test.exs` - Test environment
- `config/prod.exs` - Production settings
- `config/runtime.exs` - Runtime secrets (env vars)

## Data Flow

### TMA Submission Flow

```
1. Client → POST /api/tmas
2. TMAController.create/2
3. TMA.create_tma/1 → Database INSERT
4. WorkerPool.process_tma/2 → Assign to Worker
5. Worker.process/4:
   a. CoreBridge.anonymize_student/1
   b. CoreBridge.parse_tma/1
   c. CoreBridge.generate_feedback/1
6. Store results → TMA.update_with_feedback/3
7. Update JobRegistry → :completed
8. Client polls GET /api/tmas/:id for status
9. Client fetches GET /api/feedback/:tma_id
```

### Moodle Sync Flow

```
1. SyncScheduler timer expires
2. Authenticate with Moodle (OAuth2)
3. Fetch active courses from DB
4. For each course:
   a. Moodle.get_assignments/2
   b. For each assignment:
      - Moodle.download_submissions/2
      - Store in database as TMAs
5. Schedule next sync (15 min default)
```

## Error Handling

### Worker Failures

- Worker crashes → Supervisor restarts worker
- Job in progress → Marked as failed
- New job can be submitted

### Container Failures

- Container crashes → Manager removes and starts replacement
- Queued requests → Routed to new container
- Health checks → Periodic monitoring

### Database Failures

- Connection pool exhaustion → Queue requests
- Transaction failures → Rollback and return error
- Migration failures → Halt deployment

## Security Considerations

### Database
- Binary UUIDs prevent enumeration
- Parameterized queries prevent SQL injection
- Connection pooling prevents exhaustion

### AI Containers
- Network isolation (`--network none`)
- Resource limits (CPU, memory)
- Read-only filesystem (except `/tmp`)
- Non-root user
- No new privileges

### Core Bridge
- Port communication isolates Rust process
- Timeouts prevent hung processes
- Input validation on all boundaries

### API
- CORS configuration
- Rate limiting (to be implemented)
- Authentication (to be implemented)
- Input validation with Ecto changesets

## Testing Strategy

### Unit Tests
- Context modules (TMA, Moodle)
- Business logic
- Validation rules

### Integration Tests
- API endpoints
- Database operations
- Worker pool behavior

### Test Support
- `DataCase` - Database-backed tests
- `ConnCase` - Controller tests
- SQL Sandbox - Test isolation

## Monitoring & Observability

### Telemetry Metrics
- HTTP request duration
- Database query time
- VM memory usage
- Process count

### Logging
- Structured logs with metadata
- Request ID tracking
- Log levels: debug, info, warn, error

### Health Checks
- Database connectivity
- Core engine responsiveness
- AI container availability
- Event store connection

## Future Enhancements

1. **Authentication & Authorization**
   - JWT tokens
   - Role-based access control
   - API key management

2. **Rate Limiting**
   - Per-user limits
   - Global rate limits
   - Adaptive throttling

3. **Caching**
   - Redis integration
   - Query result caching
   - Feedback caching

4. **Background Jobs**
   - Oban integration
   - Scheduled tasks
   - Retry mechanisms

5. **Real-time Updates**
   - Phoenix Channels
   - WebSocket notifications
   - Live status updates

6. **Analytics**
   - Processing metrics
   - Performance tracking
   - Usage statistics

## File Structure

```
/home/user/academic-workflow-suite/components/backend/
├── config/
│   ├── config.exs
│   ├── dev.exs
│   ├── test.exs
│   ├── prod.exs
│   └── runtime.exs
├── lib/
│   ├── awap_backend/
│   │   ├── application.ex
│   │   ├── repo.ex
│   │   ├── event_store.ex
│   │   ├── tma.ex
│   │   ├── core/
│   │   │   ├── worker_pool.ex
│   │   │   ├── worker.ex
│   │   │   ├── worker_supervisor.ex
│   │   │   └── job_registry.ex
│   │   ├── core_bridge.ex
│   │   ├── ai/
│   │   │   ├── manager.ex
│   │   │   └── container.ex
│   │   ├── moodle/
│   │   │   ├── sync_scheduler.ex
│   │   │   └── http_client.ex
│   │   ├── moodle.ex
│   │   └── schemas/
│   │       ├── tma.ex
│   │       └── feedback.ex
│   ├── awap_backend_web/
│   │   ├── controllers/
│   │   │   └── api/
│   │   │       ├── tma_controller.ex
│   │   │       └── health_controller.ex
│   │   ├── views/
│   │   │   ├── error_view.ex
│   │   │   └── error_helpers.ex
│   │   ├── channels/
│   │   │   └── user_socket.ex
│   │   ├── endpoint.ex
│   │   ├── router.ex
│   │   ├── telemetry.ex
│   │   └── gettext.ex
│   └── awap_backend_web.ex
├── priv/
│   └── repo/
│       ├── migrations/
│       │   ├── 20251122000001_create_tmas.exs
│       │   ├── 20251122000002_create_feedback.exs
│       │   └── 20251122000003_create_audit_log.exs
│       └── seeds.exs
├── test/
│   ├── awap_backend/
│   │   └── tma_test.exs
│   ├── awap_backend_web/
│   │   └── controllers/
│   │       └── api/
│   │           └── tma_controller_test.exs
│   ├── support/
│   │   ├── data_case.ex
│   │   └── conn_case.ex
│   └── test_helper.exs
├── mix.exs
├── .formatter.exs
├── .gitignore
├── README.md
└── ARCHITECTURE.md (this file)
```

---

**Last Updated**: 2025-11-22
**Version**: 0.1.0
