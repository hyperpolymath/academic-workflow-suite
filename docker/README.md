# Docker Configuration Directory

This directory contains all Docker-related configuration files for the Academic Workflow Suite.

## Directory Structure

```
docker/
├── configs/              # Service configuration files
│   ├── postgres/        # PostgreSQL initialization scripts
│   │   ├── init.sql
│   │   └── setup-replication.sql
│   ├── redis/           # Redis configuration
│   │   └── redis.conf
│   ├── nginx/           # Nginx reverse proxy configuration
│   │   ├── nginx.conf
│   │   ├── conf.d/
│   │   ├── ssl/
│   │   └── html/
│   ├── prometheus/      # Prometheus monitoring configuration
│   │   ├── prometheus.yml
│   │   └── alerts/
│   ├── grafana/         # Grafana dashboards and provisioning
│   │   ├── provisioning/
│   │   └── dashboards/
│   └── seccomp/         # Seccomp profiles for container security
│       └── ai-jail.json
└── scripts/             # Helper scripts for Docker operations
    ├── docker-up.sh
    ├── docker-down.sh
    ├── docker-logs.sh
    └── docker-reset.sh
```

## Configuration Files

### PostgreSQL (`configs/postgres/`)

- `init.sql` - Database schema initialization
- `setup-replication.sql` - Replication configuration (future use)

### Redis (`configs/redis/`)

- `redis.conf` - Redis server configuration

### Nginx (`configs/nginx/`)

- `nginx.conf` - Main nginx configuration
- `conf.d/upstream.conf` - Upstream server definitions
- `conf.d/default.conf` - Default server block
- `html/` - Static HTML pages (index, error pages)
- `ssl/` - SSL certificates (not in repo, must be provided)

### Prometheus (`configs/prometheus/`)

- `prometheus.yml` - Metrics scraping configuration
- `alerts/core.yml` - Alert rules for Core Engine

### Grafana (`configs/grafana/`)

- `provisioning/datasources/` - Auto-provisioned datasources
- `provisioning/dashboards/` - Dashboard provisioning config
- `dashboards/` - Pre-built dashboard JSON files

### Seccomp (`configs/seccomp/`)

- `ai-jail.json` - System call filter for AI Jail isolation

## Helper Scripts

### docker-up.sh

Start Docker Compose services in different environments:

```bash
./docker/scripts/docker-up.sh dev   # Development
./docker/scripts/docker-up.sh test  # Testing
./docker/scripts/docker-up.sh prod  # Production
```

### docker-down.sh

Stop Docker Compose services:

```bash
./docker/scripts/docker-down.sh dev           # Stop development
./docker/scripts/docker-down.sh dev --volumes # Stop and remove volumes
```

### docker-logs.sh

View logs for services:

```bash
./docker/scripts/docker-logs.sh         # All services
./docker/scripts/docker-logs.sh core    # Specific service
```

### docker-reset.sh

Reset all Docker data (use with caution):

```bash
./docker/scripts/docker-reset.sh
```

## Usage

For detailed usage instructions, see:

- [Docker Guide](../docs/DOCKER_GUIDE.md)
- [Makefile](../Makefile) - Convenient shortcuts for all operations

## Security Notes

1. **Never commit secrets** - Use `.env` files for sensitive data
2. **SSL Certificates** - Provide your own in `configs/nginx/ssl/`
3. **AI Jail** - Maximum security isolation is enforced
4. **Passwords** - Use strong passwords for all services

## Customization

To customize configurations:

1. **Development**: Edit files directly in `configs/`
2. **Production**: Override with environment variables or volume mounts
3. **Testing**: Use separate configurations in `docker-compose.test.yml`

## Support

For issues or questions:

- Check [Docker Guide](../docs/DOCKER_GUIDE.md)
- Review [Troubleshooting](../docs/DOCKER_GUIDE.md#troubleshooting)
- See [Architecture](../docs/ARCHITECTURE.md) for system design
