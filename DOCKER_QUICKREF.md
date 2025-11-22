# Docker Quick Reference

**Fast reference for common Docker commands in Academic Workflow Suite**

## 🚀 Quick Start

```bash
make docker-build    # Build all images
make docker-up       # Start development
make help           # Show all commands
```

## 📦 Build

```bash
make docker-build              # Build all images
make docker-build-core         # Build Core Engine only
make docker-build-backend      # Build Backend Service only
docker-compose build --no-cache  # Force rebuild without cache
```

## ▶️ Start/Stop

```bash
make docker-up        # Start dev environment
make docker-prod      # Start production
make docker-down      # Stop services
make docker-restart   # Restart dev environment
```

## 🧪 Testing

```bash
make docker-test           # Run all tests
make docker-test-core      # Test Core Engine
make docker-test-backend   # Test Backend Service
```

## 📊 Logs & Status

```bash
make docker-logs           # All logs
make docker-logs-core      # Core Engine logs
make docker-ps            # Service status
make docker-stats         # Resource usage
```

## 💻 Shell Access

```bash
make docker-shell-core       # Bash in Core Engine
make docker-shell-backend    # Bash in Backend Service
make docker-shell-postgres   # PostgreSQL psql
make docker-shell-redis      # Redis CLI
```

## 🗄️ Database

```bash
make docker-db-migrate    # Run migrations
make docker-db-rollback   # Rollback migration
make docker-db-reset      # Reset database
make docker-db-seed       # Seed database
make docker-db-backup     # Backup database
```

## 🧹 Cleanup

```bash
make docker-clean            # Clean dangling resources
make docker-clean-volumes    # Remove volumes (⚠️ deletes data)
make docker-reset           # Complete reset (⚠️⚠️⚠️)
```

## 📈 Monitoring

```bash
make docker-prometheus    # Open Prometheus
make docker-grafana      # Open Grafana
make docker-adminer      # Open Adminer
```

## 🔍 Inspection

```bash
docker-compose ps                    # List services
docker-compose logs -f <service>     # Follow logs
docker-compose exec <service> bash   # Execute command
docker inspect <container>           # Inspect container
docker stats --no-stream            # Resource usage
```

## 🌐 Service URLs

| Service    | URL                       |
|------------|---------------------------|
| Nginx      | http://localhost          |
| Core API   | http://localhost:8080     |
| Backend    | http://localhost:4000     |
| Adminer    | http://localhost:8081     |
| Prometheus | http://localhost:9090     |
| Grafana    | http://localhost:3000     |

## 🔑 Default Credentials

| Service    | Username | Password    | Notes          |
|------------|----------|-------------|----------------|
| PostgreSQL | aws_user | (see .env)  | From .env file |
| Redis      | -        | (see .env)  | From .env file |
| Grafana    | admin    | (see .env)  | From .env file |
| Adminer    | -        | Use Postgres| -              |

## 🛠️ Common Tasks

### Add a new service
1. Edit `docker-compose.yml`
2. Add service configuration
3. Run `docker-compose up -d`

### Update a service
1. Edit code
2. Run `docker-compose restart <service>` (or let hot-reload work)

### View service configuration
```bash
docker-compose config
docker-compose config | grep -A 20 "service-name:"
```

### Execute one-off command
```bash
docker-compose run --rm core cargo test
docker-compose run --rm backend mix ecto.migrate
```

### Copy files to/from container
```bash
docker cp myfile.txt aws-core:/app/
docker cp aws-core:/app/logs/app.log ./
```

## 🚨 Troubleshooting

### Service won't start
```bash
docker-compose logs <service>
docker-compose ps
docker inspect <container>
```

### Port already in use
```bash
sudo lsof -i :8080
sudo kill -9 <PID>
```

### Out of disk space
```bash
docker system df
docker system prune -a --volumes
```

### Reset specific service
```bash
docker-compose stop <service>
docker-compose rm -f <service>
docker-compose up -d <service>
```

## 📚 Documentation

- Full Guide: `docs/DOCKER_GUIDE.md`
- Summary: `DOCKER_SETUP_SUMMARY.md`
- Architecture: `docs/ARCHITECTURE.md`
- Makefile Help: `make help`

## ⚡ Pro Tips

1. Use `make` commands for convenience
2. Check `make help` for all available commands
3. Use `-d` flag for detached mode
4. Use `--build` flag to force rebuild
5. Use `--no-deps` to not start dependent services
6. Use `--scale` to run multiple instances

## 🔥 Emergency

```bash
# Nuclear option - reset everything
make docker-reset

# Graceful stop with volume preservation
make docker-down

# Force remove everything
docker-compose down -v --remove-orphans
docker system prune -af --volumes
```

---

**Last Updated**: 2025-11-22
