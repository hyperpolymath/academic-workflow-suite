# Academic Workflow Suite - Monitoring Guide

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Components](#components)
- [Setup](#setup)
- [Dashboards](#dashboards)
- [Alerts](#alerts)
- [Metrics](#metrics)
- [Logs](#logs)
- [Health Checks](#health-checks)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Overview

The Academic Workflow Suite monitoring infrastructure provides comprehensive observability through metrics, logs, alerts, and dashboards. The stack is built on industry-standard open-source tools and follows SRE best practices.

### Monitoring Stack

- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Alertmanager**: Alert routing and notifications
- **Loki**: Log aggregation
- **Promtail**: Log collection
- **Custom Exporters**: Application-specific metrics

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Application Layer                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Backend  │  │ AI Jail  │  │ Database │  │  Cache   │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│       │             │              │             │          │
└───────┼─────────────┼──────────────┼─────────────┼──────────┘
        │             │              │             │
        ├─Metrics─────┴──────────────┴─────────────┤
        │             │              │             │
┌───────▼─────────────▼──────────────▼─────────────▼──────────┐
│                    Monitoring Layer                          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │Prometheus  │  │   Loki     │  │  Exporters │            │
│  │(Metrics)   │  │   (Logs)   │  │  (Custom)  │            │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘            │
│        │               │               │                     │
│  ┌─────▼───────────────▼───────────────▼──────┐            │
│  │         Alertmanager (Routing)             │            │
│  └──────────────────┬─────────────────────────┘            │
│                     │                                        │
│  ┌──────────────────▼──────────────────────────┐           │
│  │      Grafana (Visualization)                │           │
│  └─────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
    ┌───▼────┐   ┌───▼────┐   ┌───▼────┐
    │ Email  │   │ Slack  │   │PagerDuty│
    └────────┘   └────────┘   └────────┘
```

## Components

### Prometheus

Prometheus scrapes metrics from instrumented endpoints and stores them in a time-series database.

**Configuration**: `/etc/prometheus/prometheus.yml`

**Key Features**:
- 15-second scrape interval
- 30-day data retention
- Alert rule evaluation every 15 seconds
- Recording rules for common aggregations

### Grafana

Grafana provides visualization dashboards for metrics and logs.

**Access**: http://localhost:3000
**Default Credentials**: admin/admin (change immediately)

**Dashboards**:
1. **Overview**: System-wide health and performance
2. **TMA Processing**: Assignment marking metrics
3. **AI Performance**: AI jail and GPU metrics
4. **Database**: PostgreSQL performance
5. **Security**: Security events and threats

### Alertmanager

Alertmanager handles alert routing, grouping, silencing, and notifications.

**Configuration**: `/etc/alertmanager/alertmanager.yml`

**Notification Channels**:
- Email
- Slack
- PagerDuty
- Discord (optional)

### Loki

Loki aggregates logs from all services and makes them queryable.

**Configuration**: `/etc/loki/loki-config.yaml`

**Retention**: 31 days

### Promtail

Promtail collects logs from various sources and ships them to Loki.

**Configuration**: `/etc/promtail/promtail-config.yaml`

**Log Sources**:
- Application logs
- Container logs
- System logs
- Nginx logs
- PostgreSQL logs
- Audit logs

## Setup

### Prerequisites

- Docker and Docker Compose
- Linux system with systemd
- 4GB RAM minimum
- 20GB disk space for metrics/logs

### Quick Start

```bash
# Navigate to monitoring directory
cd /path/to/academic-workflow-suite/monitoring

# Run setup script
./scripts/setup_monitoring.sh

# Verify all services are running
docker-compose ps

# Access Grafana
open http://localhost:3000
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
sudo cp prometheus/recording_rules.yml /etc/prometheus/
sudo cp alertmanager/alertmanager.yml /etc/alertmanager/
sudo cp logs/loki-config.yaml /etc/loki/
sudo cp logs/promtail-config.yaml /etc/promtail/
```

3. **Copy dashboards**:
```bash
sudo cp grafana/dashboards/*.json /etc/grafana/dashboards/
```

4. **Start services**:
```bash
docker-compose up -d
```

### Environment Variables

Create a `.env` file:

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
PROMETHEUS_URL=http://localhost:9090
ALERTMANAGER_URL=http://localhost:9093

# Notifications
SMTP_PASSWORD=your_smtp_password
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
PAGERDUTY_SERVICE_KEY=your_pagerduty_key
```

## Dashboards

### Overview Dashboard

**URL**: http://localhost:3000/d/aws-overview

**Panels**:
- Service status indicators
- Request rate and latency
- Error rates and availability
- Resource usage (CPU, memory, disk)
- Active users

**Use Cases**:
- Quick health check
- Incident response
- Capacity planning

### TMA Processing Dashboard

**URL**: http://localhost:3000/d/aws-tma-processing

**Panels**:
- TMAs processed per hour/day
- Average marking time
- Feedback quality scores
- AI inference latency
- Batch processing throughput

**Use Cases**:
- Monitor TMA processing pipeline
- Identify performance bottlenecks
- Track quality metrics

### AI Performance Dashboard

**URL**: http://localhost:3000/d/aws-ai-performance

**Panels**:
- Model loading time
- Tokens per second
- VRAM usage
- GPU utilization and temperature
- Queue depth

**Use Cases**:
- GPU resource monitoring
- Model performance optimization
- Capacity planning for AI workloads

### Database Dashboard

**URL**: http://localhost:3000/d/aws-database

**Panels**:
- Query latency (p50, p95, p99)
- Connection pool usage
- Transaction rates
- Cache hit ratio
- Event store size

**Use Cases**:
- Database performance tuning
- Query optimization
- Capacity planning

### Security Dashboard

**URL**: http://localhost:3000/d/aws-security

**Panels**:
- Failed authentication attempts
- PII detection events
- Container escape attempts
- Audit log volume
- Security events by severity

**Use Cases**:
- Security monitoring
- Threat detection
- Compliance auditing

## Alerts

### Alert Severity Levels

- **Critical**: Immediate action required, pages oncall
- **Warning**: Requires attention, email/Slack notification
- **Info**: Informational only, logged

### Core Alerts

| Alert | Severity | Threshold | Action |
|-------|----------|-----------|--------|
| ServiceDown | Critical | Service unreachable for 1m | Restart service |
| HighMemoryUsage | Warning | >90% for 5m | Scale up or investigate |
| HighCPUUsage | Warning | >80% for 10m | Investigate processes |
| DiskSpaceCritical | Critical | >90% for 2m | Clean up or expand disk |

### Backend Alerts

| Alert | Severity | Threshold | Action |
|-------|----------|-----------|--------|
| HighErrorRate | Critical | >5% 5xx errors | Check logs, restart |
| HighLatency | Warning | p95 > 1s for 5m | Investigate bottlenecks |
| TMAProcessingStalled | Critical | No processing for 5m | Check AI jail |
| LowFeedbackQuality | Warning | Avg < 0.7 for 15m | Review AI model |

### AI Jail Alerts

| Alert | Severity | Threshold | Action |
|-------|----------|-----------|--------|
| AIJailDown | Critical | Unreachable for 1m | Restart AI jail |
| HighGPUMemoryUsage | Warning | >90% for 5m | Check for leaks |
| AIQueueDepthCritical | Critical | >50 for 2m | Scale AI instances |
| ModelNotLoaded | Critical | Model not loaded | Restart AI jail |

### Database Alerts

| Alert | Severity | Threshold | Action |
|-------|----------|-----------|--------|
| PostgresDown | Critical | Unreachable for 1m | Restart database |
| HighConnectionPoolUsage | Warning | >80% for 5m | Check connection leaks |
| SlowQueries | Warning | Avg > 1s for 10m | Optimize queries |
| DatabaseDeadlocks | Warning | Any detected | Review transactions |

### Security Alerts

| Alert | Severity | Threshold | Action |
|-------|----------|-----------|--------|
| HighFailedAuthRate | Warning | >10/min for 5m | Enable rate limiting |
| ContainerEscapeAttempt | Critical | Any detected | Investigate immediately |
| PIIDetected | Warning | Any detected | Review data handling |
| SQLInjectionAttempt | Critical | Any detected | Block source IP |

### Alert Management

**Silencing alerts**:
```bash
# Via Alertmanager UI
open http://localhost:9093/#/silences

# Via CLI
amtool silence add alertname="ServiceDown" instance="test-instance" --duration=1h --comment="Planned maintenance"
```

**Testing alerts**:
```bash
./scripts/test_alerts.sh
```

## Metrics

### Application Metrics

Backend and AI Jail expose Prometheus metrics on `/metrics` endpoint.

**Common patterns**:
```promql
# Request rate
rate(http_requests_total[5m])

# Error rate
rate(http_requests_total{status=~"5.."}[5m])

# Latency percentiles
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

### Custom Metrics

The AWS exporter (`aws_exporter.rs`) provides business-specific metrics:

```promql
# TMAs processed
aws_tma_processed_total

# Feedback quality
aws_feedback_quality_score

# AI queue depth
aws_ai_queue_depth

# Active users
aws_active_users
```

### Recording Rules

Pre-aggregated metrics for faster queries:

```promql
# Service availability (5m)
job:availability:5m

# Request rate per job
job:http_requests_total:rate5m

# TMA processing duration p95
tma:processing_duration:p95
```

## Logs

### Log Aggregation

All logs are collected by Promtail and stored in Loki.

**Querying logs in Grafana**:

1. Open Grafana
2. Go to Explore
3. Select "Loki" datasource
4. Enter LogQL query

**Example queries**:

```logql
# All errors
{job=~".+"} |~ "(?i)error"

# Backend errors in last hour
{job="aws-backend"} |~ "ERROR|FATAL" | json

# AI inference failures
{job="ai-jail"} |~ "inference failed"

# Security events
{job="security"} or {job="audit"}

# Slow queries
{job="postgres"} |~ "duration: [0-9]{4,} ms"
```

### Log Levels

- **FATAL**: System crash
- **ERROR**: Operation failed
- **WARN**: Unexpected but handled
- **INFO**: Normal operations
- **DEBUG**: Detailed debugging

### Log Retention

- **Standard logs**: 31 days
- **Audit logs**: 90 days (archive after)
- **Metrics**: 30 days

## Health Checks

### Automated Health Checks

The `healthcheck.sh` script monitors all components:

```bash
# Run health check
./healthchecks/healthcheck.sh

# Exit codes:
# 0 = healthy
# 1 = unhealthy (critical failures)
# 2 = degraded (warnings)
```

### Health Check Endpoints

| Service | Endpoint | Expected Status |
|---------|----------|----------------|
| Backend | /health | 200 OK |
| AI Jail | /health | 200 OK |
| Prometheus | /-/healthy | 200 OK |
| Grafana | /api/health | 200 OK |
| Alertmanager | /-/healthy | 200 OK |
| Loki | /ready | 200 OK |

### Uptime Monitoring

External monitoring via Uptime Kuma or UptimeRobot:

- 60-second check interval for critical services
- 5-minute check interval for non-critical services
- SSL certificate expiration monitoring
- DNS resolution monitoring

## Troubleshooting

### Common Issues

**Prometheus not scraping metrics**:
```bash
# Check targets
open http://localhost:9090/targets

# Check logs
docker logs prometheus

# Verify network connectivity
curl http://backend:8080/metrics
```

**Grafana dashboards not loading**:
```bash
# Check datasources
open http://localhost:3000/datasources

# Test Prometheus connection
curl http://prometheus:9090/api/v1/query?query=up

# Check Grafana logs
docker logs grafana
```

**Alerts not firing**:
```bash
# Check alert rules
./scripts/test_alerts.sh rules

# Verify Alertmanager connectivity
curl http://localhost:9093/api/v1/status

# Check inhibition rules
open http://localhost:9093/#/status
```

**Loki logs not showing**:
```bash
# Check Promtail
docker logs promtail

# Verify log files exist
ls -la /var/log/aws-backend/

# Test Loki query
curl -G "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={job="aws-backend"}' \
  --data-urlencode 'limit=10'
```

### Performance Tuning

**Prometheus**:
- Adjust scrape interval based on needs
- Use recording rules for expensive queries
- Increase retention if needed

**Loki**:
- Tune chunk size for log volume
- Adjust compression settings
- Configure retention based on requirements

**Grafana**:
- Cache dashboard queries
- Use variables for dynamic filtering
- Optimize panel queries

## Best Practices

### Metrics

1. **Use labels wisely**: Keep cardinality low
2. **Consistent naming**: Follow Prometheus conventions
3. **Document metrics**: Add HELP and TYPE annotations
4. **Use histograms**: For latency measurements
5. **Avoid high-cardinality labels**: User IDs, request IDs, etc.

### Alerts

1. **Alert on symptoms, not causes**
2. **Make alerts actionable**: Include runbook links
3. **Avoid alert fatigue**: Tune thresholds carefully
4. **Use inhibition rules**: Prevent duplicate alerts
5. **Test alerts regularly**: Use test script

### Dashboards

1. **Start with overview**: High-level health first
2. **Drill down capability**: Link dashboards
3. **Show SLIs and SLOs**: Track objectives
4. **Use meaningful colors**: Red=bad, green=good
5. **Add descriptions**: Help users understand metrics

### Logs

1. **Structured logging**: Use JSON format
2. **Include context**: Request IDs, user IDs, etc.
3. **Appropriate levels**: Don't log everything as ERROR
4. **Sanitize sensitive data**: No passwords, tokens in logs
5. **Aggregate related logs**: Use correlation IDs

### Operations

1. **Regular backups**: Dashboard configurations, alerts
2. **Version control**: Store configs in Git
3. **Document changes**: Track alert tuning
4. **Incident reviews**: Learn from outages
5. **Capacity planning**: Monitor trends, plan ahead

## Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)
- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [LogQL Query Language](https://grafana.com/docs/loki/latest/logql/)
- [PromQL Query Language](https://prometheus.io/docs/prometheus/latest/querying/basics/)

## Support

For monitoring-related issues:

1. Check this documentation
2. Review troubleshooting section
3. Check service logs
4. Contact DevOps team: ops@academic-workflow-suite.com
