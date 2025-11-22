# Docker Guide

**Comprehensive guide to running Academic Workflow Suite with Docker**

This guide provides complete documentation for developing, testing, and deploying Academic Workflow Suite using Docker and Docker Compose.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Service Architecture](#service-architecture)
- [Development Environment](#development-environment)
- [Testing Environment](#testing-environment)
- [Production Deployment](#production-deployment)
- [Common Operations](#common-operations)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Security Considerations](#security-considerations)

---

## Overview

The Academic Workflow Suite uses Docker Compose to orchestrate multiple services:

- **Core Engine** (Rust/Actix-Web) - Main API and business logic
- **Backend Service** (Elixir/Phoenix) - Rubric repository and updates
- **AI Jail** - Isolated AI inference container
- **PostgreSQL** - Relational database
- **Redis** - Caching and pub/sub
- **Nginx** - Reverse proxy and load balancer
- **Prometheus** - Metrics collection
- **Grafana** - Monitoring dashboards
- **Adminer** - Database management UI (dev only)

---

## Prerequisites

### Required Software

1. **Docker** (version 20.10 or later)
   ```bash
   # Install on Ubuntu/Debian
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh

   # Install on macOS
   brew install --cask docker

   # Verify installation
   docker --version
   ```

2. **Docker Compose** (version 2.0 or later)
   ```bash
   # Usually included with Docker Desktop
   # Or install standalone:
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose

   # Verify installation
   docker-compose --version
   ```

3. **Make** (optional, for convenience)
   ```bash
   # Install on Ubuntu/Debian
   sudo apt-get install make

   # Install on macOS
   brew install make
   ```

### System Requirements

- **Minimum**: 8 GB RAM, 4 CPU cores, 20 GB disk space
- **Recommended**: 16 GB RAM, 8 CPU cores, 50 GB disk space
- **Operating System**: Linux, macOS, or Windows with WSL2

---

## Quick Start

### Using Makefile (Recommended)

```bash
# Build all images
make docker-build

# Start development environment
make docker-up

# View logs
make docker-logs

# Stop services
make docker-down

# View help for all commands
make help
```

### Using Scripts

```bash
# Start development environment
./docker/scripts/docker-up.sh dev

# Start production environment
./docker/scripts/docker-up.sh prod

# Run tests
./docker/scripts/docker-up.sh test

# View logs
./docker/scripts/docker-logs.sh

# Stop services
./docker/scripts/docker-down.sh dev

# Reset everything
./docker/scripts/docker-reset.sh
```

### Using Docker Compose Directly

```bash
# Development
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Production
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Testing
docker-compose -f docker-compose.yml -f docker-compose.test.yml up --abort-on-container-exit
```

---

## Service Architecture

### Network Topology

```
┌─────────────────────────────────────────────────────────┐
│                    aws-network                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │  Nginx   │←─┤   Core   │←─┤ Backend  │             │
│  │   :80    │  │  :8080   │  │  :4000   │             │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘             │
│       │             │              │                    │
│       │        ┌────┴────┐    ┌────┴────┐              │
│       │        │ Postgres│    │  Redis  │              │
│       │        │  :5432  │    │  :6379  │              │
│       │        └─────────┘    └─────────┘              │
│       │                                                 │
│       │        ┌──────────┐  ┌──────────┐              │
│       └───────►│Prometheus│  │ Grafana  │              │
│                │  :9090   │  │  :3000   │              │
│                └──────────┘  └──────────┘              │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│              ai-jail-network (internal)                 │
│  ┌──────────┐                                           │
│  │ AI Jail  │ ← Unix socket → Core                      │
│  │ (no net) │                                           │
│  └──────────┘                                           │
└─────────────────────────────────────────────────────────┘
```

### Port Mappings

| Service    | Port  | URL                     | Description              |
|------------|-------|-------------------------|--------------------------|
| Nginx      | 80    | http://localhost        | HTTP redirect to HTTPS   |
| Nginx      | 443   | https://localhost       | HTTPS reverse proxy      |
| Core       | 8080  | http://localhost:8080   | Core Engine API          |
| Backend    | 4000  | http://localhost:4000   | Backend Service API      |
| PostgreSQL | 5432  | localhost:5432          | Database                 |
| Redis      | 6379  | localhost:6379          | Cache                    |
| Adminer    | 8081  | http://localhost:8081   | DB UI (dev only)         |
| Prometheus | 9090  | http://localhost:9090   | Metrics                  |
| Grafana    | 3000  | http://localhost:3000   | Dashboards               |

---

## Development Environment

### Starting Development Environment

```bash
# Option 1: Using Makefile
make docker-dev

# Option 2: Using script
./docker/scripts/docker-up.sh dev

# Option 3: Using docker-compose
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### Development Features

- **Hot Reload**: Source code changes trigger automatic rebuilds
- **Debug Ports**: Exposed for remote debugging
- **Verbose Logging**: Debug-level logs for all services
- **Development Tools**: Additional containers with debugging utilities
- **Relaxed Security**: Easier to debug and develop

### Accessing Services

```bash
# View all running services
make docker-ps

# Open shell in Core Engine
make docker-shell-core

# Open shell in Backend Service
make docker-shell-backend

# Open PostgreSQL shell
make docker-shell-postgres

# Open Redis CLI
make docker-shell-redis
```

### Viewing Logs

```bash
# All services
make docker-logs

# Specific service
make docker-logs-core
make docker-logs-backend
make docker-logs-ai-jail

# Follow logs in real-time
docker-compose logs -f core

# Last 100 lines
docker-compose logs --tail=100 backend
```

### Hot Reload Configuration

Development environment automatically reloads on code changes:

- **Rust (Core/AI Jail)**: Uses `cargo-watch` to rebuild on changes
- **Elixir (Backend)**: Phoenix live-reload enabled
- **Configuration**: Mounted as read-only volumes

### Development Database

```bash
# Run migrations
make docker-db-migrate

# Rollback last migration
make docker-db-rollback

# Reset database
make docker-db-reset

# Seed database
make docker-db-seed
```

---

## Testing Environment

### Running Tests

```bash
# Run all tests
make docker-test

# Run Core Engine tests only
make docker-test-core

# Run Backend Service tests only
make docker-test-backend

# Run integration tests
make docker-test-integration
```

### Test Features

- **Isolated Database**: Fresh test database for each run
- **No Persistent Volumes**: Clean state for every test
- **Mock Services**: AI Jail runs with mock responses
- **Coverage Reports**: Automatically generated in `test-results/`
- **Parallel Execution**: Tests run in parallel where possible

### Test Results

Test results are saved to `/test-results` volume:

```bash
# View test results
ls -l test-results/

# View coverage reports
open coverage-reports/core/index.html
open coverage-reports/backend/index.html
```

---

## Production Deployment

### Prerequisites for Production

1. **Environment Variables**: Create `.env.prod` file:
   ```bash
   # Required
   POSTGRES_PASSWORD=strong_password_here
   REDIS_PASSWORD=strong_password_here
   SECRET_KEY_BASE=generate_with_mix_phx_gen_secret
   GRAFANA_ADMIN_PASSWORD=strong_password_here

   # Optional
   VERSION=1.0.0
   POSTGRES_USER=aws_user
   BACKUP_S3_BUCKET=my-backups
   ```

2. **SSL Certificates**: Place in `docker/configs/nginx/ssl/`:
   ```bash
   docker/configs/nginx/ssl/server.crt
   docker/configs/nginx/ssl/server.key
   ```

3. **Backup Storage**: Configure S3 or local backup directory

### Starting Production

```bash
# Build production images
docker-compose -f docker-compose.yml -f docker-compose.prod.yml build

# Start production services
make docker-prod
# OR
./docker/scripts/docker-up.sh prod
# OR
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Production Features

- **SSL/TLS**: Enforced HTTPS with proper certificates
- **Health Checks**: All services have health monitoring
- **Resource Limits**: CPU and memory constraints
- **Restart Policies**: Automatic recovery from failures
- **Optimized Images**: Multi-stage builds for minimal size
- **Security Hardening**: Maximum security for AI Jail
- **Logging**: Structured logs with rotation
- **Monitoring**: Prometheus and Grafana dashboards
- **Backups**: Automated database backups

### Scaling Services

```bash
# Scale Core Engine to 3 replicas
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --scale core=3

# Scale Backend Service to 2 replicas
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --scale backend=2
```

### Database Backups

```bash
# Create backup
make docker-db-backup

# Restore from backup
docker-compose exec -T postgres psql -U aws_user academic_workflow < backups/postgres/backup_20250101_120000.sql
```

### Monitoring

```bash
# Open Prometheus
make docker-prometheus

# Open Grafana
make docker-grafana

# View metrics
curl http://localhost:9090/api/v1/query?query=up

# View container stats
make docker-stats
```

---

## Common Operations

### Building Images

```bash
# Build all images
make docker-build

# Build specific service
make docker-build-core
make docker-build-backend
make docker-build-ai-jail
make docker-build-nginx

# Force rebuild without cache
docker-compose build --no-cache
```

### Managing Services

```bash
# Start services
make docker-up

# Stop services
make docker-down

# Restart services
make docker-restart

# View service status
make docker-ps

# View resource usage
make docker-stats
```

### Accessing Containers

```bash
# Execute command in container
docker-compose exec core /bin/bash

# Run one-off command
docker-compose run --rm core cargo --version

# Copy files to/from container
docker cp local-file.txt aws-core:/app/
docker cp aws-core:/app/logs/app.log ./
```

### Managing Data

```bash
# List volumes
make docker-volumes

# Inspect volume
docker volume inspect academic-workflow-suite_postgres-data

# Backup volume
docker run --rm -v academic-workflow-suite_postgres-data:/data -v $(pwd)/backups:/backup alpine tar czf /backup/postgres-data.tar.gz /data

# Restore volume
docker run --rm -v academic-workflow-suite_postgres-data:/data -v $(pwd)/backups:/backup alpine tar xzf /backup/postgres-data.tar.gz -C /
```

### Cleanup

```bash
# Stop and remove containers
make docker-down

# Remove volumes (WARNING: deletes data)
make docker-clean-volumes

# Clean up dangling images
make docker-clean

# Complete reset (WARNING: deletes everything)
make docker-reset
```

---

## Troubleshooting

### Common Issues

#### Issue: Containers won't start

```bash
# Check logs
docker-compose logs

# Check specific service
docker-compose logs postgres

# Check container status
docker-compose ps

# Inspect container
docker inspect aws-core
```

#### Issue: Port already in use

```bash
# Find process using port
sudo lsof -i :8080
sudo netstat -tulpn | grep 8080

# Kill process
sudo kill -9 <PID>

# Or change port in docker-compose.yml
ports:
  - "8081:8080"  # Changed from 8080:8080
```

#### Issue: Database connection refused

```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Check PostgreSQL logs
docker-compose logs postgres

# Test connection
docker-compose exec postgres pg_isready -U aws_user

# Manually connect
docker-compose exec postgres psql -U aws_user -d academic_workflow
```

#### Issue: Out of disk space

```bash
# Check disk usage
docker system df

# Clean up unused resources
docker system prune -a --volumes

# Remove specific volumes
docker volume rm academic-workflow-suite_postgres-data
```

#### Issue: AI Jail communication failure

```bash
# Check AI Jail is running
docker-compose ps ai-jail

# Check AI Jail logs
docker-compose logs ai-jail

# Check Unix socket permissions
docker-compose exec core ls -la /run/ai-jail.sock

# Restart AI Jail
docker-compose restart ai-jail
```

### Performance Tuning

#### Increase Resource Limits

Edit `docker-compose.yml`:

```yaml
services:
  core:
    deploy:
      resources:
        limits:
          cpus: '8.0'
          memory: 16G
        reservations:
          cpus: '4.0'
          memory: 8G
```

#### Enable BuildKit for Faster Builds

```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Build with BuildKit
docker-compose build
```

#### Optimize PostgreSQL

Edit PostgreSQL configuration:

```sql
-- Increase shared buffers
ALTER SYSTEM SET shared_buffers = '2GB';

-- Increase work memory
ALTER SYSTEM SET work_mem = '16MB';

-- Reload configuration
SELECT pg_reload_conf();
```

### Debugging

#### Enable Debug Logging

```bash
# Set environment variable
export RUST_LOG=debug

# Or in docker-compose.yml
environment:
  RUST_LOG: debug
  RUST_BACKTRACE: full
```

#### Attach Debugger

```bash
# Expose debug port in docker-compose.dev.yml
ports:
  - "9229:9229"

# Attach with your IDE or debugger
```

#### Profile Performance

```bash
# Enable profiling
docker-compose exec core perf record -F 99 -p $(pgrep aws-core) -g -- sleep 30

# Generate flame graph
docker-compose exec core perf script | flamegraph.pl > flamegraph.svg
```

---

## Best Practices

### Development

1. **Use development compose file** for local development
2. **Mount source code** for hot reload
3. **Use named volumes** for persistent data
4. **Enable debug logging** for troubleshooting
5. **Run tests frequently** with `make docker-test`

### Production

1. **Use production compose file** with optimizations
2. **Set resource limits** on all services
3. **Enable health checks** for monitoring
4. **Use secrets management** for sensitive data
5. **Implement backup strategy** for data persistence
6. **Monitor metrics** with Prometheus/Grafana
7. **Review logs regularly** for issues
8. **Keep images updated** for security patches

### Security

1. **Never commit secrets** to version control
2. **Use .env files** for environment variables
3. **Rotate passwords** regularly
4. **Enable SSL/TLS** in production
5. **Restrict network access** (AI Jail isolation)
6. **Use read-only filesystems** where possible
7. **Apply security updates** promptly
8. **Audit logs** for suspicious activity

---

## Security Considerations

### AI Jail Isolation

The AI Jail container has maximum security:

- **No Network Access**: Cannot communicate externally
- **Read-Only Filesystem**: Cannot persist data
- **Limited Capabilities**: Only essential Linux capabilities
- **Seccomp Profile**: Restricted system calls
- **Resource Limits**: Bounded CPU and memory
- **Unix Socket Only**: Communication via IPC

Verify isolation:

```bash
# Check network is disabled
docker-compose exec ai-jail ping -c 1 8.8.8.8  # Should fail

# Check filesystem is read-only
docker-compose exec ai-jail touch /test  # Should fail

# Check seccomp profile
docker inspect aws-ai-jail | grep -A 10 SecurityOpt
```

### Database Security

```bash
# Use strong passwords
POSTGRES_PASSWORD=$(openssl rand -base64 32)

# Enable SSL
ssl=on
ssl_cert_file=/etc/ssl/certs/server.crt
ssl_key_file=/etc/ssl/private/server.key

# Restrict access
host all all 0.0.0.0/0 md5
host all all ::0/0 md5
```

### Nginx Security Headers

Already configured in `nginx.conf`:

```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
```

---

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [AWS Architecture](./ARCHITECTURE.md)
- [AWS Development Guide](./DEVELOPMENT.md)
- [AWS Security Guide](./SECURITY.md)

---

## Appendix

### Environment Variables Reference

| Variable               | Description                    | Default          | Required |
|------------------------|--------------------------------|------------------|----------|
| POSTGRES_PASSWORD      | PostgreSQL password            | changeme123      | Prod     |
| POSTGRES_USER          | PostgreSQL username            | aws_user         | No       |
| REDIS_PASSWORD         | Redis password                 | (none)           | Prod     |
| SECRET_KEY_BASE        | Phoenix secret key             | (generated)      | Prod     |
| GRAFANA_ADMIN_PASSWORD | Grafana admin password         | admin            | Prod     |
| AWS_ENV                | Environment (dev/prod)         | production       | No       |
| RUST_LOG               | Rust logging level             | info             | No       |
| VERSION                | Application version            | latest           | No       |

### Docker Compose Commands Reference

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# Execute command
docker-compose exec <service> <command>

# Run one-off command
docker-compose run --rm <service> <command>

# View status
docker-compose ps

# Build images
docker-compose build

# Pull images
docker-compose pull

# View config
docker-compose config
```

---

**Last Updated**: 2025-11-22
**Docker Compose Version**: 3.8
**Minimum Docker Version**: 20.10
