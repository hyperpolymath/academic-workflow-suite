# Academic Workflow Suite - Monitoring Infrastructure

Production-ready monitoring, alerting, and observability stack for the Academic Workflow Suite.

## Quick Start

```bash
# Setup monitoring stack
cd monitoring
./scripts/setup_monitoring.sh

# Access dashboards
open http://localhost:3000  # Grafana (admin/admin)
open http://localhost:9090  # Prometheus
open http://localhost:9093  # Alertmanager
```

## Overview

This monitoring infrastructure provides comprehensive observability for the Academic Workflow Suite through:

- **Metrics Collection**: Prometheus with custom exporters
- **Visualization**: Grafana dashboards
- **Alerting**: Alertmanager with multi-channel notifications
- **Log Aggregation**: Loki and Promtail
- **Health Checks**: Automated service monitoring
- **Uptime Monitoring**: External availability tracking

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                        │
│   Backend API  •  AI Jail  •  Database  •  Cache           │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                  Monitoring Stack                           │
│                                                             │
│  Prometheus  ←  Metrics  ←  Exporters                      │
│      ↓                                                      │
│  Alertmanager  →  Email/Slack/PagerDuty                    │
│      ↓                                                      │
│  Grafana  ←  Loki  ←  Promtail  ←  Logs                    │
└─────────────────────────────────────────────────────────────┘
```

## Components

### Grafana Dashboards

Pre-built dashboards for comprehensive monitoring:

- **Overview** (`overview.json`): System health and performance
- **TMA Processing** (`tma_processing.json`): Assignment marking metrics
- **AI Performance** (`ai_performance.json`): AI jail and GPU monitoring
- **Database** (`database.json`): PostgreSQL performance
- **Security** (`security.json`): Security events and threats

### Prometheus Alerts

Production-ready alert rules:

- **Core** (`alerts/core.yml`): Infrastructure and services
- **Backend** (`alerts/backend.yml`): API and application
- **AI** (`alerts/ai.yml`): AI jail and GPU
- **Database** (`alerts/database.yml`): PostgreSQL
- **Security** (`alerts/security.yml`): Security events

### Alertmanager

Multi-channel notification routing:

- Email notifications
- Slack integration
- PagerDuty escalation
- Severity-based routing
- Alert inhibition rules

### Logging

Centralized log aggregation:

- Loki for log storage
- Promtail for log collection
- Structured logging support
- Log pattern definitions
- 31-day retention

### Custom Exporters

Business-specific metrics:

- TMA processing metrics
- Feedback quality tracking
- AI performance monitoring
- Event store metrics
- Security event tracking

### Health Checks

Comprehensive health monitoring:

- Service health endpoints
- Automated health check script
- Uptime monitoring configs
- SSL certificate monitoring

## Directory Structure

```
monitoring/
├── grafana/
│   └── dashboards/          # 5 production dashboards
├── prometheus/
│   ├── alerts/              # Alert rules by component
│   └── recording_rules.yml  # Pre-aggregated metrics
├── alertmanager/
│   └── alertmanager.yml     # Alert routing config
├── logs/
│   ├── loki-config.yaml     # Loki configuration
│   ├── promtail-config.yaml # Log collection config
│   └── log_patterns.yaml    # Log parsing rules
├── exporters/
│   ├── aws_exporter.rs      # Custom metrics exporter
│   └── Cargo.toml           # Rust dependencies
├── healthchecks/
│   ├── healthcheck.sh       # Health check script
│   └── endpoints.yaml       # Health endpoints config
├── uptime/
│   ├── uptime-kuma-config.json    # Uptime Kuma
│   └── uptimerobot-monitors.json  # UptimeRobot
├── scripts/
│   ├── setup_monitoring.sh  # Setup automation
│   ├── backup_dashboards.sh # Dashboard backup
│   └── test_alerts.sh       # Alert testing
├── docs/
│   ├── MONITORING_GUIDE.md  # Complete guide
│   ├── ALERTS_REFERENCE.md  # Alert documentation
│   └── DASHBOARD_GUIDE.md   # Dashboard usage
└── README.md                # This file
```

## Installation

### Prerequisites

- Docker and Docker Compose
- Linux system (Ubuntu 20.04+ recommended)
- 4GB RAM minimum
- 20GB disk space

### Automated Setup

```bash
# Clone repository
cd /path/to/academic-workflow-suite/monitoring

# Run setup script
./scripts/setup_monitoring.sh

# Verify services
docker-compose ps
```

### Manual Setup

1. **Create directories**:
```bash
sudo mkdir -p /etc/{prometheus,grafana,alertmanager,loki,promtail}
sudo mkdir -p /var/lib/{prometheus,grafana,loki,alertmanager}
```

2. **Copy configurations**:
```bash
sudo cp prometheus/alerts/* /etc/prometheus/alerts/
sudo cp alertmanager/alertmanager.yml /etc/alertmanager/
sudo cp logs/loki-config.yaml /etc/loki/
sudo cp logs/promtail-config.yaml /etc/promtail/
```

3. **Start services**:
```bash
docker-compose up -d
```

## Configuration

### Environment Variables

Create `.env` file:

```bash
# Database
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=academic_workflow_suite
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_password

# Services
BACKEND_URL=http://localhost:8080
AI_JAIL_URL=http://localhost:8081

# Monitoring
GRAFANA_ADMIN_PASSWORD=secure_password

# Notifications
SMTP_PASSWORD=your_smtp_password
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
PAGERDUTY_SERVICE_KEY=your_pagerduty_key
```

### Customization

**Adjust alert thresholds**:
Edit `prometheus/alerts/*.yml` files.

**Modify dashboards**:
1. Edit in Grafana UI
2. Export JSON
3. Save to `grafana/dashboards/`
4. Backup with `./scripts/backup_dashboards.sh`

**Add custom metrics**:
1. Instrument code with Prometheus client
2. Add scrape target to `prometheus.yml`
3. Create dashboard panels
4. Define alerts if needed

## Usage

### Accessing Services

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://localhost:3000 | admin/admin |
| Prometheus | http://localhost:9090 | - |
| Alertmanager | http://localhost:9093 | - |

### Common Tasks

**View dashboards**:
```bash
open http://localhost:3000/dashboards
```

**Check alerts**:
```bash
./scripts/test_alerts.sh
```

**Run health check**:
```bash
./healthchecks/healthcheck.sh
```

**Backup dashboards**:
```bash
./scripts/backup_dashboards.sh
```

**View logs**:
```bash
docker-compose logs -f
```

**Restart services**:
```bash
docker-compose restart
```

### Querying Metrics

**Prometheus UI**: http://localhost:9090/graph

Example queries:
```promql
# Request rate
rate(http_requests_total[5m])

# Error rate
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))

# p95 latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

### Querying Logs

**Grafana Explore**: http://localhost:3000/explore

Example queries:
```logql
# All errors
{job=~".+"} |~ "(?i)error"

# Backend logs
{job="aws-backend"} | json

# Security events
{job="security"} or {job="audit"}
```

## Alerting

### Alert Severity

- **Critical**: Immediate action, pages on-call (PagerDuty)
- **Warning**: Requires attention (Email, Slack)
- **Info**: Informational only (Logs)

### Alert Workflow

1. Alert fires in Prometheus
2. Sent to Alertmanager
3. Routed by severity and component
4. Notifications sent via configured channels
5. Acknowledged and resolved

### Managing Alerts

**Silence an alert**:
```bash
amtool silence add alertname="ServiceDown" --duration=1h --comment="Maintenance"
```

**Test alerts**:
```bash
./scripts/test_alerts.sh test
```

**List firing alerts**:
```bash
./scripts/test_alerts.sh firing
```

## Monitoring Metrics

### Application Metrics

- Request rate, latency, errors
- TMA processing rate and duration
- Feedback quality scores
- AI inference performance
- Active users

### Infrastructure Metrics

- CPU, memory, disk usage
- Network traffic and errors
- Container health
- Service availability

### Database Metrics

- Query latency
- Connection pool usage
- Transaction rates
- Cache hit ratio
- Event store size

### Security Metrics

- Failed authentication attempts
- PII detection events
- Container escape attempts
- Rate limit violations
- Audit log volume

## Maintenance

### Regular Tasks

**Daily**:
- Review dashboards for anomalies
- Check alert notifications
- Verify service health

**Weekly**:
- Backup dashboard configurations
- Review alert effectiveness
- Check disk space usage

**Monthly**:
- Tune alert thresholds
- Archive old logs
- Review capacity trends
- Update documentation

### Backup and Restore

**Backup dashboards**:
```bash
./scripts/backup_dashboards.sh backup
```

**Restore dashboards**:
```bash
./scripts/backup_dashboards.sh restore /path/to/backup
```

**Backup Prometheus data**:
```bash
tar -czf prometheus-backup.tar.gz /var/lib/prometheus
```

### Troubleshooting

**Services not starting**:
```bash
# Check logs
docker-compose logs

# Verify ports not in use
netstat -tulpn | grep -E ':(3000|9090|9093|3100)'

# Check disk space
df -h
```

**Metrics not appearing**:
```bash
# Check Prometheus targets
open http://localhost:9090/targets

# Verify scrape configs
docker exec prometheus cat /etc/prometheus/prometheus.yml

# Test metric endpoint
curl http://backend:8080/metrics
```

**Alerts not firing**:
```bash
# Validate alert rules
./scripts/test_alerts.sh validate

# Check Alertmanager
open http://localhost:9093/#/status
```

## Performance Tuning

### Prometheus

- Adjust scrape interval (default: 15s)
- Tune retention period (default: 30d)
- Optimize recording rules
- Increase memory if needed

### Loki

- Adjust chunk size
- Configure retention (default: 31d)
- Tune compaction interval
- Optimize query performance

### Grafana

- Enable dashboard caching
- Optimize panel queries
- Use variables for filtering
- Limit concurrent queries

## Security

### Best Practices

- Change default passwords immediately
- Use HTTPS in production
- Restrict network access
- Enable authentication
- Rotate credentials regularly
- Monitor security dashboards

### Access Control

Grafana supports:
- User authentication
- Role-based access control
- Team-based permissions
- Anonymous access (disable in production)

## Documentation

- **[Monitoring Guide](docs/MONITORING_GUIDE.md)**: Complete monitoring documentation
- **[Alerts Reference](docs/ALERTS_REFERENCE.md)**: All alert definitions and runbooks
- **[Dashboard Guide](docs/DASHBOARD_GUIDE.md)**: Dashboard usage instructions

## Support

### Getting Help

1. Check documentation in `docs/`
2. Review troubleshooting section
3. Check service logs
4. Contact DevOps team

### Contact

- DevOps Team: ops@academic-workflow-suite.com
- Security: security@academic-workflow-suite.com
- On-Call: PagerDuty escalation

## Contributing

### Adding Dashboards

1. Create in Grafana UI
2. Export to JSON
3. Save to `grafana/dashboards/`
4. Document in `docs/DASHBOARD_GUIDE.md`
5. Commit to repository

### Adding Alerts

1. Define in `prometheus/alerts/`
2. Test with `./scripts/test_alerts.sh`
3. Document in `docs/ALERTS_REFERENCE.md`
4. Update runbooks
5. Notify team of changes

### Best Practices

- Follow naming conventions
- Document all changes
- Test before deploying
- Update documentation
- Review with team

## License

See main repository LICENSE file.

## Changelog

### v1.0.0 - 2025-11-22

Initial release:
- 5 production dashboards
- 50+ alert rules
- Multi-channel alerting
- Log aggregation
- Custom exporters
- Health checks
- Comprehensive documentation

---

**Status**: Production Ready
**Last Updated**: 2025-11-22
**Maintained By**: DevOps Team
