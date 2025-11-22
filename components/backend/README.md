# AWAP Backend

Phoenix-based backend for the Academic Workflow Automation Platform (AWAP).

## Overview

The AWAP backend provides a REST API for managing TMA (Tutor Marked Assignment) submissions, processing them through the Rust core engine, and integrating with Moodle LMS.

## Architecture

### Supervision Tree

```
AwapBackend.Application
├── AwapBackendWeb.Telemetry
├── AwapBackend.Repo (PostgreSQL)
├── Phoenix.PubSub
├── AwapBackendWeb.Endpoint
├── AwapBackend.EventStore
├── AwapBackend.CoreEngine.WorkerPool
│   ├── Task.Supervisor
│   ├── JobRegistry (ETS)
│   └── WorkerSupervisor
│       └── Worker (1..N)
├── AwapBackend.AI.Manager
│   └── Podman Containers (1..N)
└── AwapBackend.Moodle.SyncScheduler
```

### Key Components

#### Core Engine Bridge
- **Module**: `AwapBackend.CoreBridge`
- **Purpose**: Interface with Rust core via NIF or Port
- **Functions**: TMA parsing, anonymization, feedback generation

#### AI Jail Manager
- **Module**: `AwapBackend.AI.Manager`
- **Purpose**: Manage isolated AI containers using Podman
- **Security**: Network isolation, resource limits, ephemeral containers

#### Moodle Integration
- **Module**: `AwapBackend.Moodle`
- **Purpose**: OAuth2/SAML authentication, TMA download, grade upload
- **Scheduler**: `AwapBackend.Moodle.SyncScheduler`

#### Worker Pool
- **Module**: `AwapBackend.CoreEngine.WorkerPool`
- **Purpose**: Distribute TMA processing across worker processes
- **Registry**: ETS-based job tracking

## Getting Started

### Prerequisites

- Elixir 1.14+
- Erlang/OTP 25+
- PostgreSQL 14+
- Podman (for AI containers)
- Rust core binary (compiled separately)

### Installation

```bash
# Install dependencies
mix deps.get

# Create and migrate database
mix ecto.setup

# Start Phoenix server
mix phx.server
```

### Environment Variables

Create a `.env` file:

```bash
# Database
DATABASE_URL=ecto://postgres:postgres@localhost/awap_backend_dev

# Moodle
MOODLE_BASE_URL=https://moodle.example.edu
MOODLE_CLIENT_ID=your_client_id
MOODLE_CLIENT_SECRET=your_client_secret
MOODLE_USERNAME=service_account
MOODLE_PASSWORD=secure_password

# Core Engine
CORE_EXECUTABLE=/usr/local/bin/awap_core
EVENT_STORE_URL=tcp://localhost:1113

# AI Containers
AI_CONTAINER_IMAGE=localhost/awap-ai:latest
MAX_AI_CONTAINERS=5
AI_MAX_MEMORY=2g
AI_MAX_CPUS=1.0
AI_NETWORK_MODE=none
```

## API Endpoints

### TMAs

- `POST /api/tmas` - Submit a TMA for processing
- `GET /api/tmas/:id` - Get TMA status
- `GET /api/tmas` - List TMAs (with filters)

### Feedback

- `GET /api/feedback/:tma_id` - Get generated feedback

### Health

- `GET /api/health` - System health check

## Testing

```bash
# Run all tests
mix test

# Run with coverage
mix test --cover

# Run specific test file
mix test test/awap_backend/tma_test.exs
```

## Database

### Migrations

```bash
# Create migration
mix ecto.gen.migration create_table_name

# Run migrations
mix ecto.migrate

# Rollback
mix ecto.rollback
```

### Schema

- **tmas** - TMA submissions
- **feedback** - Generated feedback and grades
- **audit_log** - System audit trail

## Development

### Code Quality

```bash
# Format code
mix format

# Check code quality
mix credo

# Run dialyzer
mix dialyzer
```

### Live Dashboard

Development dashboard available at: http://localhost:4000/dev/dashboard

## Production Deployment

### Build Release

```bash
# Set production environment
export MIX_ENV=prod

# Install dependencies
mix deps.get --only prod

# Compile assets
mix assets.deploy

# Build release
mix release
```

### Run Release

```bash
_build/prod/rel/awap_backend/bin/awap_backend start
```

## Configuration

Configuration is managed via:
- `config/config.exs` - Shared configuration
- `config/dev.exs` - Development
- `config/test.exs` - Testing
- `config/prod.exs` - Production
- `config/runtime.exs` - Runtime configuration (secrets)

## Monitoring

### Telemetry

The application exposes metrics for:
- Phoenix endpoint performance
- Database query performance
- VM metrics (memory, processes)

### Logging

Structured logging with metadata:
- Request ID tracking
- Module/Function/Arity
- Contextual information

## Security

### Database
- Binary UUIDs for primary keys
- Prepared statements (SQL injection prevention)
- Connection pooling

### AI Containers
- No network access
- Resource limits (CPU, memory)
- Read-only filesystem
- Non-root user

### Core Bridge
- Port communication for isolation
- Request/response validation
- Timeout enforcement

## License

See LICENSE file in repository root.
