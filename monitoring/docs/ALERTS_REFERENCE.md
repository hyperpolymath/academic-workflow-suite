# Alert Reference Guide

## Overview

This document provides a comprehensive reference for all alerts in the Academic Workflow Suite monitoring system.

## Alert Severity Levels

| Severity | Response Time | Notification | Description |
|----------|--------------|--------------|-------------|
| **Critical** | Immediate | PagerDuty, Email, Slack | Service outage or severe degradation |
| **Warning** | 15-30 min | Email, Slack | Performance degradation or potential issues |
| **Info** | Best effort | Logs only | Informational events |

## Alert Response SLAs

- **Critical**: Acknowledge within 5 minutes, resolve within 30 minutes
- **Warning**: Acknowledge within 15 minutes, resolve within 2 hours

## Core Service Alerts

### ServiceDown

**Severity**: Critical
**Expression**: `up == 0`
**For**: 1 minute
**Labels**: `severity=critical, component=infrastructure`

**Description**: Service is not responding to health checks.

**Runbook**:
1. Check if service container is running: `docker ps | grep <service>`
2. Check service logs: `docker logs <service>`
3. Restart service if needed: `docker restart <service>`
4. If restart fails, check resource constraints
5. Escalate if issue persists > 10 minutes

**Common Causes**:
- OOM kill
- Application crash
- Network issues
- Resource exhaustion

---

### HighMemoryUsage

**Severity**: Warning
**Expression**: `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90`
**For**: 5 minutes
**Labels**: `severity=warning, component=infrastructure`

**Description**: Memory usage is above 90%.

**Runbook**:
1. Identify memory-intensive processes: `docker stats`
2. Check for memory leaks in application logs
3. Consider scaling horizontally
4. Restart containers if memory leak confirmed
5. Increase memory if pattern is consistent

**Common Causes**:
- Memory leaks
- Unexpected traffic spike
- Large dataset processing
- Insufficient resources

---

### CriticalMemoryUsage

**Severity**: Critical
**Expression**: `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 95`
**For**: 2 minutes
**Labels**: `severity=critical, component=infrastructure`

**Description**: Memory usage critically high, OOM kill imminent.

**Runbook**:
1. **Immediate**: Identify and kill non-critical processes
2. Scale up resources immediately
3. Check for runaway processes: `top -o %MEM`
4. Restart affected services
5. Investigate root cause after mitigation

---

### DiskSpaceCritical

**Severity**: Critical
**Expression**: `(1 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})) * 100 > 90`
**For**: 2 minutes
**Labels**: `severity=critical, component=infrastructure`

**Description**: Disk space critically low.

**Runbook**:
1. Check disk usage: `df -h`
2. Find large files: `du -sh /* | sort -rh | head -20`
3. Clean up logs: `find /var/log -name "*.log" -mtime +30 -delete`
4. Archive old data
5. Expand disk if cleanup insufficient

---

## Backend Alerts

### HighErrorRate

**Severity**: Critical
**Expression**: `sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100 > 5`
**For**: 5 minutes
**Labels**: `severity=critical, component=backend`

**Description**: 5xx error rate exceeds 5%.

**Runbook**:
1. Check backend logs for errors: `docker logs aws-backend --tail 100`
2. Verify database connectivity: `./healthchecks/healthcheck.sh`
3. Check AI jail status
4. Review recent deployments
5. Rollback if necessary

**Common Causes**:
- Database connection issues
- AI jail unavailability
- Code bugs in recent deployment
- Resource exhaustion

---

### HighLatency

**Severity**: Warning
**Expression**: `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job="aws-backend"}[5m])) > 1`
**For**: 5 minutes
**Labels**: `severity=warning, component=backend`

**Description**: p95 request latency exceeds 1 second.

**Runbook**:
1. Check slow queries in database
2. Review AI inference times
3. Check for resource contention
4. Enable query performance logging
5. Optimize identified bottlenecks

---

### TMAProcessingStalled

**Severity**: Critical
**Expression**: `rate(aws_tma_processed_total[10m]) == 0 and aws_tma_queue_depth > 0`
**For**: 5 minutes
**Labels**: `severity=critical, component=backend`

**Description**: TMAs are queued but not being processed.

**Runbook**:
1. Check AI jail status: `curl http://ai-jail:8081/health`
2. Verify model is loaded: `curl http://ai-jail:8081/health/model`
3. Check worker processes
4. Review error logs
5. Restart TMA workers if needed

---

### LowFeedbackQuality

**Severity**: Warning
**Expression**: `avg(aws_feedback_quality_score) < 0.7`
**For**: 15 minutes
**Labels**: `severity=warning, component=backend`

**Description**: Feedback quality score below acceptable threshold.

**Runbook**:
1. Review recent feedback samples
2. Check AI model performance
3. Verify prompt templates
4. Check for data quality issues
5. Retrain model if needed

---

## AI Jail Alerts

### AIJailDown

**Severity**: Critical
**Expression**: `up{job="ai-jail"} == 0`
**For**: 1 minute
**Labels**: `severity=critical, component=ai-jail`

**Description**: AI Jail service is down.

**Runbook**:
1. Check container status: `docker ps -a | grep ai-jail`
2. View logs: `docker logs ai-jail --tail 200`
3. Check GPU availability: `nvidia-smi`
4. Restart service: `docker restart ai-jail`
5. Check model loading process

**Common Causes**:
- OOM kill (GPU memory)
- Model loading failure
- CUDA errors
- Configuration issues

---

### HighGPUMemoryUsage

**Severity**: Warning
**Expression**: `(aws_gpu_memory_used_bytes / aws_gpu_memory_total_bytes) * 100 > 90`
**For**: 5 minutes
**Labels**: `severity=warning, component=ai-jail`

**Description**: GPU memory usage above 90%.

**Runbook**:
1. Check inference queue: `curl http://ai-jail:8081/metrics | grep queue_depth`
2. Reduce batch size if applicable
3. Check for memory leaks
4. Consider model quantization
5. Scale AI jail instances

---

### AIQueueDepthCritical

**Severity**: Critical
**Expression**: `aws_ai_queue_depth > 50`
**For**: 2 minutes
**Labels**: `severity=critical, component=ai-jail`

**Description**: AI inference queue critically backed up.

**Runbook**:
1. **Immediate**: Scale AI jail instances
2. Check inference latency
3. Verify GPU performance: `nvidia-smi`
4. Check for slow inferences
5. Consider temporary rate limiting

---

### ModelNotLoaded

**Severity**: Critical
**Expression**: `aws_model_loaded == 0`
**For**: 2 minutes
**Labels**: `severity=critical, component=ai-jail`

**Description**: AI model failed to load.

**Runbook**:
1. Check AI jail logs for loading errors
2. Verify model files exist
3. Check GPU memory availability
4. Verify CUDA installation
5. Restart AI jail with increased logging

---

## Database Alerts

### PostgresDown

**Severity**: Critical
**Expression**: `up{job="postgres"} == 0`
**For**: 1 minute
**Labels**: `severity=critical, component=database`

**Description**: PostgreSQL database is unreachable.

**Runbook**:
1. Check PostgreSQL container: `docker ps -a | grep postgres`
2. View logs: `docker logs postgres --tail 200`
3. Check disk space on data volume
4. Restart database: `docker restart postgres`
5. Verify data integrity after restart

---

### HighConnectionPoolUsage

**Severity**: Warning
**Expression**: `(pg_stat_database_numbackends / pg_settings_max_connections) * 100 > 80`
**For**: 5 minutes
**Labels**: `severity=warning, component=database`

**Description**: Database connection pool over 80% utilized.

**Runbook**:
1. Check for connection leaks: `SELECT * FROM pg_stat_activity;`
2. Identify idle connections
3. Terminate long-idle connections if safe
4. Review application connection pooling
5. Increase max_connections if needed

---

### SlowQueries

**Severity**: Warning
**Expression**: `rate(pg_stat_statements_mean_exec_time[5m]) > 1000`
**For**: 10 minutes
**Labels**: `severity=warning, component=database`

**Description**: Database queries are running slow.

**Runbook**:
1. Identify slow queries: `SELECT * FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;`
2. Analyze query plans: `EXPLAIN ANALYZE <query>`
3. Check for missing indexes
4. Review table statistics: `ANALYZE;`
5. Optimize identified queries

---

## Security Alerts

### HighFailedAuthRate

**Severity**: Warning
**Expression**: `rate(aws_auth_failed_total[5m]) * 60 > 10`
**For**: 5 minutes
**Labels**: `severity=warning, component=security`

**Description**: High rate of authentication failures.

**Runbook**:
1. Check source IPs: Query logs for patterns
2. Enable rate limiting on auth endpoints
3. Check for brute force patterns
4. Block suspicious IPs
5. Enable CAPTCHA if needed

---

### ContainerEscapeAttempt

**Severity**: Critical
**Expression**: `increase(aws_container_escape_attempts_total[5m]) > 0`
**For**: 1 minute
**Labels**: `severity=critical, component=security`

**Description**: Container escape attempt detected.

**Runbook**:
1. **Immediate**: Isolate affected container
2. Review container logs and audit logs
3. Identify attack vector
4. Strengthen container security policies
5. File security incident report

---

### SQLInjectionAttempt

**Severity**: Critical
**Expression**: `increase(aws_security_events_total{type="sql_injection"}[5m]) > 0`
**For**: 1 minute
**Labels**: `severity=critical, component=security`

**Description**: SQL injection attempt detected.

**Runbook**:
1. **Immediate**: Block source IP
2. Review application logs
3. Verify parameterized queries in use
4. Check WAF rules
5. Assess if attack was successful

---

## Alert Workflow

### 1. Alert Received

- Check notification for severity and summary
- Acknowledge alert in PagerDuty/Alertmanager
- Note alert start time

### 2. Initial Assessment

- Verify alert is valid (not false positive)
- Check related alerts
- Assess impact (users affected, services down)

### 3. Investigation

- Follow runbook steps
- Check logs and metrics
- Identify root cause
- Document findings

### 4. Mitigation

- Apply fix following runbook
- Monitor for improvement
- Verify alert resolves

### 5. Post-Incident

- Document incident in log
- Update runbook if needed
- Schedule post-mortem if critical
- Tune alert if false positive

## Silencing Alerts

### When to Silence

- Planned maintenance
- Known issues during deployment
- False positives being investigated

### How to Silence

**Via Alertmanager UI**:
```
http://localhost:9093/#/silences
```

**Via CLI**:
```bash
amtool silence add \
  alertname="ServiceDown" \
  instance="backend-1" \
  --duration=1h \
  --comment="Planned maintenance" \
  --author="ops@example.com"
```

### Silence Guidelines

- Always add a comment explaining why
- Set appropriate duration (don't exceed 24h)
- Document silences in change log
- Review active silences regularly

## Testing Alerts

Use the test script to verify alerts:

```bash
./scripts/test_alerts.sh
```

Options:
- `health`: Check Prometheus/Alertmanager health
- `rules`: Verify alert rules loaded
- `firing`: Check currently firing alerts
- `test`: Send test alert
- `validate`: Validate alert syntax

## Alert Tuning

### When to Tune

- Frequent false positives
- Alert not firing when it should
- Threshold not appropriate
- Better metric available

### How to Tune

1. Analyze alert history
2. Adjust threshold or duration
3. Test changes in staging
4. Update documentation
5. Monitor for 1 week

### Tuning Checklist

- [ ] Verify new threshold is appropriate
- [ ] Test in non-production environment
- [ ] Update runbook
- [ ] Notify team of changes
- [ ] Monitor effectiveness

## Emergency Contacts

- **DevOps On-Call**: PagerDuty rotation
- **Security Team**: security@academic-workflow-suite.com
- **Database Team**: dba@academic-workflow-suite.com
- **AI/ML Team**: ml-ops@academic-workflow-suite.com

## Additional Resources

- [Monitoring Guide](./MONITORING_GUIDE.md)
- [Dashboard Guide](./DASHBOARD_GUIDE.md)
- [Prometheus Alert Rules](../prometheus/alerts/)
- [Alertmanager Config](../alertmanager/alertmanager.yml)
