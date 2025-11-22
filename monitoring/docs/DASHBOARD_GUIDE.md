# Dashboard Usage Guide

## Overview

This guide explains how to use Grafana dashboards for monitoring the Academic Workflow Suite.

## Accessing Dashboards

**URL**: http://localhost:3000

**Default Credentials**:
- Username: `admin`
- Password: `admin` (change on first login)

## Dashboard Overview

| Dashboard | URL | Purpose | Update Frequency |
|-----------|-----|---------|------------------|
| Overview | `/d/aws-overview` | System health | 10s |
| TMA Processing | `/d/aws-tma-processing` | Assignment marking | 10s |
| AI Performance | `/d/aws-ai-performance` | AI/GPU metrics | 10s |
| Database | `/d/aws-database` | PostgreSQL metrics | 10s |
| Security | `/d/aws-security` | Security events | 10s |

## Overview Dashboard

### Purpose
High-level view of system health and performance.

### Key Panels

#### Service Status Indicators
- **Green**: Service is up and healthy
- **Red**: Service is down
- **Gray**: No data (check configuration)

**What to look for**:
- All services should be green during normal operations
- Red status requires immediate attention

#### Request Rate
Shows requests per second to the backend API.

**Interpretation**:
- Baseline: 10-50 req/s during normal hours
- Peak: 100-200 req/s during high usage
- Sudden drops: Potential outage or routing issue
- Sudden spikes: Traffic surge or potential attack

#### Request Latency (p95, p99)
95th and 99th percentile request latency.

**Thresholds**:
- **Good**: p95 < 500ms, p99 < 1s
- **Warning**: p95 < 1s, p99 < 2s
- **Critical**: p95 > 1s, p99 > 3s

**Action Items**:
- Check slow database queries
- Review AI inference times
- Look for resource contention

#### CPU/Memory/Disk Usage
System resource utilization percentages.

**Healthy ranges**:
- CPU: 30-70%
- Memory: 40-80%
- Disk: < 70%

**Alert levels**:
- Warning: > 80%
- Critical: > 90%

#### Active Users
Number of users active in last 15 minutes.

**Typical patterns**:
- Business hours: 50-200 users
- Off-hours: 5-20 users
- Weekends: 10-50 users

### Using the Overview Dashboard

**Daily Health Check**:
1. Verify all services are green
2. Check request rate is within expected range
3. Confirm latency is acceptable
4. Review resource usage trends

**Incident Response**:
1. Identify affected services (red status)
2. Check error rate panel
3. Review latency spikes
4. Correlate with resource usage

## TMA Processing Dashboard

### Purpose
Monitor the TMA marking pipeline and feedback quality.

### Key Panels

#### TMAs Processed (Last Hour/24h)
Total TMAs marked in recent periods.

**Expected values**:
- Per hour: 5-50 (varies by usage)
- Per day: 100-1000

**Anomalies**:
- Zero for extended period: Processing stalled
- Unusually high: Batch processing or backlog

#### Average Marking Time
Mean time to mark a single TMA.

**Benchmarks**:
- Fast: < 30s
- Normal: 30-60s
- Slow: > 60s

**Factors affecting marking time**:
- TMA complexity
- AI model inference speed
- Queue depth

#### Feedback Quality Score
Average quality score (0-1) for generated feedback.

**Target**: > 0.8
**Acceptable**: > 0.7
**Concerning**: < 0.7

**Improving quality**:
- Review prompt templates
- Check model performance
- Validate input data quality

#### AI Inference Latency
Time taken for AI to generate feedback.

**Targets**:
- p95 < 5s
- p99 < 10s

**High latency causes**:
- GPU memory pressure
- Large batch sizes
- Model not optimized

#### Batch Processing Throughput
TMAs processed per second in batch mode.

**Expected**: 2-10 TMAs/sec depending on batch size

### Using the TMA Dashboard

**Performance Monitoring**:
1. Track processing rate trend
2. Monitor marking time for regressions
3. Watch quality score
4. Alert on processing stalls

**Capacity Planning**:
1. Review hourly/daily volumes
2. Project future needs
3. Plan AI jail scaling

## AI Performance Dashboard

### Purpose
Monitor AI jail health, GPU utilization, and model performance.

### Key Panels

#### Model Loading Time
Time to load AI model into GPU memory.

**Acceptable**: < 30s
**Concerning**: > 30s

**High loading time causes**:
- Disk I/O bottleneck
- Large model size
- Insufficient GPU memory

#### Tokens per Second
Token generation rate by AI model.

**Targets**:
- Modern GPUs: 50-200 tokens/sec
- Older GPUs: 10-50 tokens/sec

**Low throughput causes**:
- GPU thermal throttling
- VRAM limitations
- Suboptimal batch size

#### VRAM Usage
GPU memory utilization percentage.

**Healthy**: 60-80%
**Warning**: > 90%
**Critical**: > 95%

**High usage solutions**:
- Reduce batch size
- Use model quantization
- Clear cache between inferences

#### GPU Utilization
GPU compute utilization percentage.

**Healthy**: 70-90% during inference
**Concerning**: < 50% with queued requests

**Low utilization causes**:
- CPU bottleneck
- I/O bottleneck
- Inefficient batching

#### GPU Temperature
Temperature in Celsius.

**Safe**: < 80°C
**Warning**: 80-85°C
**Critical**: > 85°C

**High temperature actions**:
- Check cooling system
- Reduce workload temporarily
- Verify ambient temperature

#### Queue Depth
Number of pending AI inference requests.

**Normal**: 0-5
**Warning**: 5-20
**Critical**: > 20

**High queue depth solutions**:
- Scale AI jail instances
- Optimize inference speed
- Implement request throttling

### Using the AI Performance Dashboard

**Daily Operations**:
1. Verify GPU health (temp, memory)
2. Check token generation rate
3. Monitor queue depth
4. Review inference latency

**Performance Tuning**:
1. Correlate GPU utilization with throughput
2. Adjust batch size based on VRAM usage
3. Monitor temperature during peak load

## Database Dashboard

### Purpose
Monitor PostgreSQL performance and health.

### Key Panels

#### Query Latency (p50, p95, p99)
Database query execution time percentiles.

**Targets**:
- p50 < 10ms
- p95 < 100ms
- p99 < 500ms

**High latency investigation**:
1. Check Top Queries panel
2. Review missing indexes
3. Analyze query plans
4. Check for lock contention

#### Transaction Rate
Commits and rollbacks per second.

**Healthy**: High commit rate, low rollback rate

**High rollback rate causes**:
- Application errors
- Constraint violations
- Deadlocks

#### Active Connections
Current database connections.

**Typical**: 10-50
**Warning**: > 80% of max_connections
**Critical**: > 90% of max_connections

**High connections causes**:
- Connection leaks
- Missing connection pooling
- Traffic spike

#### Connection Pool Usage
Percentage of connection pool utilized.

**Healthy**: 40-70%
**Warning**: > 80%
**Critical**: > 90%

#### Event Store Size
Total events in event sourcing store.

**Monitor growth rate**: Should be steady and predictable

**Large size considerations**:
- Plan archival strategy
- Consider partitioning
- Monitor query performance

#### Cache Hit Ratio
Percentage of queries served from cache.

**Target**: > 95%
**Warning**: < 90%
**Concerning**: < 85%

**Low hit ratio causes**:
- Insufficient shared_buffers
- Working set larger than cache
- Query patterns not cache-friendly

### Using the Database Dashboard

**Daily Monitoring**:
1. Check query latency trends
2. Verify cache hit ratio
3. Monitor connection pool usage
4. Review transaction rates

**Performance Optimization**:
1. Identify slow queries
2. Check for missing indexes
3. Analyze table statistics
4. Review configuration parameters

## Security Dashboard

### Purpose
Monitor security events and potential threats.

### Key Panels

#### Failed Authentication Attempts
Failed login attempts per minute.

**Normal**: 0-2/min
**Warning**: > 10/min
**Critical**: > 50/min

**High failure rate actions**:
1. Identify source IPs
2. Check for brute force patterns
3. Enable rate limiting
4. Block suspicious IPs

#### PII Detection Events
Occurrences of personally identifiable information.

**Target**: 0
**Any detection**: Investigate immediately

**Response**:
1. Review log context
2. Identify source
3. Sanitize data
4. Update validation rules

#### Container Escape Attempts
Attempts to break out of container sandbox.

**Target**: 0
**Any attempt**: Critical security incident

**Response**:
1. Isolate container immediately
2. Review security logs
3. Investigate attack vector
4. Strengthen security policies

#### Audit Log Volume
Number of audit log entries per hour.

**Monitor for**:
- Unusual spikes (possible attack)
- Drops (logging failure)

#### Top Failed Auth IPs
Source IPs with most authentication failures.

**Use for**:
- Identifying attackers
- Building IP blocklists
- Geographic analysis

### Using the Security Dashboard

**Daily Security Review**:
1. Check failed auth rate
2. Review PII detections
3. Monitor for escape attempts
4. Scan audit log volume

**Incident Response**:
1. Identify security event type
2. Check event details in logs
3. Follow security runbook
4. Document incident

## Dashboard Features

### Time Range Selection

Use the time picker (top right) to change the view window:
- **Last 5 minutes**: Real-time monitoring
- **Last 1 hour**: Recent trends
- **Last 24 hours**: Daily patterns
- **Last 7 days**: Weekly trends
- **Custom**: Specific date ranges

### Auto-Refresh

Set auto-refresh rate (top right):
- **5s**: Critical incident monitoring
- **10s**: Default for most dashboards
- **1m**: Long-term trend analysis
- **Off**: Static snapshot

### Panel Actions

Hover over panel title for options:
- **View**: Expand to full screen
- **Edit**: Modify panel (requires permissions)
- **Share**: Get link to panel
- **Explore**: Open in Explore view
- **Inspect**: View raw data/queries

### Variables

Some dashboards have variables (top of page):
- **Instance**: Filter by specific server
- **Job**: Filter by service
- **Interval**: Adjust aggregation window

## Explore View

### Accessing
Click "Explore" in left sidebar or panel menu.

### Using Explore

**For Metrics (Prometheus)**:
1. Select "Prometheus" datasource
2. Enter PromQL query
3. Adjust time range
4. Run query
5. Visualize results

**For Logs (Loki)**:
1. Select "Loki" datasource
2. Enter LogQL query
3. Set time range
4. Run query
5. View log lines

### Common Queries

**Metrics**:
```promql
# Request rate
rate(http_requests_total[5m])

# Error rate
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))

# Memory usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

**Logs**:
```logql
# All errors
{job=~".+"} |~ "(?i)error"

# Backend logs
{job="aws-backend"} | json

# Slow queries
{job="postgres"} |~ "duration: [0-9]{4,} ms"
```

## Best Practices

### Dashboard Usage

1. **Start broad**: Use Overview dashboard first
2. **Drill down**: Navigate to specific dashboards
3. **Use time range**: Adjust to investigation needs
4. **Correlate metrics**: Look across panels for patterns
5. **Save snapshots**: Share dashboard state with team

### Effective Monitoring

1. **Regular reviews**: Check dashboards daily
2. **Trend analysis**: Look for patterns over time
3. **Baseline understanding**: Know what's normal
4. **Alert correlation**: Connect alerts to dashboard metrics
5. **Document findings**: Note unusual patterns

### Performance Tips

1. **Avoid long time ranges**: Use appropriate windows
2. **Limit panel queries**: Don't overcomplicate
3. **Use recording rules**: Pre-aggregate common queries
4. **Cache dashboards**: Browser caching helps
5. **Optimize queries**: Efficient PromQL/LogQL

## Troubleshooting

### Dashboard Not Loading

1. Check Grafana is running: `docker ps | grep grafana`
2. Check datasource connection: Grafana → Configuration → Data Sources
3. Verify Prometheus is reachable: `curl http://prometheus:9090/api/v1/query?query=up`
4. Check browser console for errors

### No Data Showing

1. Verify time range is appropriate
2. Check datasource in panel edit
3. Verify metrics are being scraped: `http://prometheus:9090/targets`
4. Test query in Explore view
5. Check Prometheus logs for scrape errors

### Slow Dashboard Loading

1. Reduce time range
2. Increase refresh interval
3. Simplify complex queries
4. Use recording rules
5. Check Prometheus resource usage

## Additional Resources

- [Grafana Documentation](https://grafana.com/docs/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [LogQL Documentation](https://grafana.com/docs/loki/latest/logql/)
- [Dashboard JSON](../grafana/dashboards/)
- [Monitoring Guide](./MONITORING_GUIDE.md)
