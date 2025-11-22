#!/bin/bash

# Academic Workflow Suite - Monitoring Setup Script
# This script sets up the complete monitoring infrastructure

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITORING_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$MONITORING_DIR")"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}===== $1 =====${NC}\n"
}

# Check prerequisites
check_prerequisites() {
    log_section "Checking Prerequisites"

    local missing_deps=0

    # Check Docker
    if command -v docker &> /dev/null; then
        log_info "Docker: $(docker --version)"
    else
        log_error "Docker is not installed"
        ((missing_deps++))
    fi

    # Check Docker Compose
    if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
        log_info "Docker Compose is installed"
    else
        log_error "Docker Compose is not installed"
        ((missing_deps++))
    fi

    # Check curl
    if command -v curl &> /dev/null; then
        log_info "curl is installed"
    else
        log_error "curl is not installed"
        ((missing_deps++))
    fi

    if [ $missing_deps -gt 0 ]; then
        log_error "Missing $missing_deps prerequisite(s). Please install them first."
        exit 1
    fi

    log_info "All prerequisites met"
}

# Create necessary directories
create_directories() {
    log_section "Creating Directories"

    local dirs=(
        "/var/lib/prometheus"
        "/var/lib/grafana"
        "/var/lib/loki"
        "/var/lib/alertmanager"
        "/var/log/prometheus"
        "/var/log/grafana"
        "/var/log/loki"
        "/var/log/promtail"
        "/etc/prometheus/alerts"
        "/etc/grafana/provisioning/dashboards"
        "/etc/grafana/provisioning/datasources"
    )

    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            log_info "Creating directory: $dir"
            sudo mkdir -p "$dir"
            sudo chown -R "${USER}:${USER}" "$dir" || true
        else
            log_info "Directory already exists: $dir"
        fi
    done
}

# Deploy Prometheus
deploy_prometheus() {
    log_section "Deploying Prometheus"

    # Copy alert rules
    log_info "Copying Prometheus alert rules..."
    sudo cp -r "$MONITORING_DIR/prometheus/alerts/"* /etc/prometheus/alerts/

    # Copy recording rules
    log_info "Copying Prometheus recording rules..."
    sudo cp "$MONITORING_DIR/prometheus/recording_rules.yml" /etc/prometheus/

    # Create Prometheus config
    log_info "Creating Prometheus configuration..."
    cat > /tmp/prometheus.yml <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'aws-production'
    environment: 'production'

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

rule_files:
  - '/etc/prometheus/alerts/*.yml'
  - '/etc/prometheus/recording_rules.yml'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'aws-backend'
    static_configs:
      - targets: ['backend:8080']

  - job_name: 'ai-jail'
    static_configs:
      - targets: ['ai-jail:8081']

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'aws-exporter'
    static_configs:
      - targets: ['aws-exporter:9090']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
EOF

    sudo mv /tmp/prometheus.yml /etc/prometheus/prometheus.yml
    log_info "Prometheus configuration created"
}

# Deploy Grafana
deploy_grafana() {
    log_section "Deploying Grafana"

    # Create datasource configuration
    log_info "Creating Grafana datasources..."
    cat > /tmp/datasources.yml <<EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false

  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    editable: false

  - name: PostgreSQL
    type: postgres
    url: postgres:5432
    database: academic_workflow_suite
    user: \${POSTGRES_USER}
    secureJsonData:
      password: \${POSTGRES_PASSWORD}
    jsonData:
      sslmode: disable
    editable: false
EOF

    sudo mv /tmp/datasources.yml /etc/grafana/provisioning/datasources/datasources.yml

    # Create dashboard provisioning
    log_info "Creating Grafana dashboard provisioning..."
    cat > /tmp/dashboards.yml <<EOF
apiVersion: 1

providers:
  - name: 'AWS Dashboards'
    orgId: 1
    folder: 'Academic Workflow Suite'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/dashboards
EOF

    sudo mv /tmp/dashboards.yml /etc/grafana/provisioning/dashboards/dashboards.yml

    # Copy dashboard files
    log_info "Copying Grafana dashboards..."
    sudo mkdir -p /etc/grafana/dashboards
    sudo cp "$MONITORING_DIR/grafana/dashboards/"*.json /etc/grafana/dashboards/

    log_info "Grafana configuration completed"
}

# Deploy Loki and Promtail
deploy_loki() {
    log_section "Deploying Loki and Promtail"

    # Copy Loki config
    log_info "Copying Loki configuration..."
    sudo cp "$MONITORING_DIR/logs/loki-config.yaml" /etc/loki/loki-config.yaml

    # Copy Promtail config
    log_info "Copying Promtail configuration..."
    sudo cp "$MONITORING_DIR/logs/promtail-config.yaml" /etc/promtail/promtail-config.yaml

    log_info "Loki and Promtail configured"
}

# Deploy Alertmanager
deploy_alertmanager() {
    log_section "Deploying Alertmanager"

    # Copy Alertmanager config
    log_info "Copying Alertmanager configuration..."
    sudo cp "$MONITORING_DIR/alertmanager/alertmanager.yml" /etc/alertmanager/alertmanager.yml

    log_info "Alertmanager configured"
}

# Create Docker Compose file
create_docker_compose() {
    log_section "Creating Docker Compose Configuration"

    cat > "$MONITORING_DIR/docker-compose.yml" <<'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    volumes:
      - /etc/prometheus:/etc/prometheus
      - /var/lib/prometheus:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
      - '--web.enable-lifecycle'
    ports:
      - "9090:9090"
    networks:
      - monitoring

  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    restart: unless-stopped
    volumes:
      - /etc/alertmanager:/etc/alertmanager
      - /var/lib/alertmanager:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
    ports:
      - "9093:9093"
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    volumes:
      - /var/lib/grafana:/var/lib/grafana
      - /etc/grafana/provisioning:/etc/grafana/provisioning
      - /etc/grafana/dashboards:/etc/grafana/dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-admin}
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_SERVER_ROOT_URL=http://localhost:3000
    ports:
      - "3000:3000"
    networks:
      - monitoring

  loki:
    image: grafana/loki:latest
    container_name: loki
    restart: unless-stopped
    volumes:
      - /etc/loki:/etc/loki
      - /var/lib/loki:/loki
    command: -config.file=/etc/loki/loki-config.yaml
    ports:
      - "3100:3100"
    networks:
      - monitoring

  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    restart: unless-stopped
    volumes:
      - /etc/promtail:/etc/promtail
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    command: -config.file=/etc/promtail/promtail-config.yaml
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    command:
      - '--path.rootfs=/host'
    volumes:
      - /:/host:ro,rslave
    ports:
      - "9100:9100"
    networks:
      - monitoring

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    restart: unless-stopped
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker:/var/lib/docker:ro
    ports:
      - "8080:8080"
    networks:
      - monitoring

  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:latest
    container_name: postgres-exporter
    restart: unless-stopped
    environment:
      - DATA_SOURCE_NAME=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}?sslmode=disable
    ports:
      - "9187:9187"
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
EOF

    log_info "Docker Compose file created"
}

# Start services
start_services() {
    log_section "Starting Monitoring Services"

    cd "$MONITORING_DIR"

    log_info "Starting Docker Compose services..."
    docker-compose up -d

    log_info "Waiting for services to be ready..."
    sleep 10

    # Check service health
    services=("prometheus:9090/-/healthy" "grafana:3000/api/health" "alertmanager:9093/-/healthy" "loki:3100/ready")

    for service in "${services[@]}"; do
        IFS=':' read -r container endpoint <<< "$service"
        if curl -sf "http://localhost:${endpoint}" &> /dev/null; then
            log_info "$container is healthy"
        else
            log_warn "$container health check failed"
        fi
    done
}

# Print access information
print_access_info() {
    log_section "Setup Complete!"

    echo -e "${GREEN}Monitoring stack is now running!${NC}\n"
    echo "Access URLs:"
    echo "  - Prometheus:    http://localhost:9090"
    echo "  - Grafana:       http://localhost:3000 (admin/admin)"
    echo "  - Alertmanager:  http://localhost:9093"
    echo
    echo "Dashboards:"
    echo "  - Overview:      http://localhost:3000/d/aws-overview"
    echo "  - TMA Processing: http://localhost:3000/d/aws-tma-processing"
    echo "  - AI Performance: http://localhost:3000/d/aws-ai-performance"
    echo "  - Database:      http://localhost:3000/d/aws-database"
    echo "  - Security:      http://localhost:3000/d/aws-security"
    echo
    echo "Useful commands:"
    echo "  - View logs:     docker-compose logs -f"
    echo "  - Stop services: docker-compose down"
    echo "  - Restart:       docker-compose restart"
}

# Main installation
main() {
    echo -e "${BLUE}"
    cat << "EOF"
    ___                __               _
   / _ | ______  _____/ /__ __ _  (_)____
  / __ |/ __/ / / / _  / -_)  ' \/ / __/
 /_/ |_\__/\_,_/\_,_/\__/_/_/_/_/\__/

  Workflow Suite - Monitoring Setup
EOF
    echo -e "${NC}"

    check_prerequisites
    create_directories
    deploy_prometheus
    deploy_grafana
    deploy_loki
    deploy_alertmanager
    create_docker_compose
    start_services
    print_access_info
}

# Run main
main "$@"
