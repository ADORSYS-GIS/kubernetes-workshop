# Monitoring Solutions

This directory contains reference implementations for comprehensive Kubernetes observability using Prometheus, Grafana, and monitoring best practices.

## 📁 Contents

### `complete-monitoring-solution.yaml`
A production-ready monitoring stack featuring:
- **Prometheus**: Metrics collection with comprehensive scraping configuration
- **Grafana**: Visualization dashboards with pre-configured datasources
- **Alert Rules**: Production-ready alerting for infrastructure and applications
- **Recording Rules**: Pre-computed metrics for performance optimization
- **Service Discovery**: Automatic discovery of Kubernetes services and pods
- **Security**: RBAC, non-root execution, resource limits

## 📊 Monitoring Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   OBSERVABILITY STACK                   │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │
│  │ PROMETHEUS  │  │   GRAFANA   │  │  ALERTMANAGER   │  │
│  │             │  │             │  │                 │  │
│  │ • Metrics   │  │ • Dashboards│  │ • Notifications │  │
│  │ • Rules     │  │ • Queries   │  │ • Routing       │  │
│  │ • Storage   │  │ • Alerts    │  │ • Silencing     │  │
│  └─────────────┘  └─────────────┘  └─────────────────┘  │
│         │                 │                   │         │
│         └─────────────────┼───────────────────┘         │
│                           │                             │
│                    KUBERNETES CLUSTER                   │
│              (Pods, Services, Nodes, etc.)              │
└─────────────────────────────────────────────────────────┘
```

## 🎯 Key Features

### 1. Comprehensive Metrics Collection
```yaml
# Kubernetes API Server monitoring
- job_name: 'kubernetes-apiservers'
  scheme: https
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token

# Node-level metrics (cAdvisor)
- job_name: 'kubernetes-nodes-cadvisor'
  metrics_path: /metrics/cadvisor
```

### 2. Production Alert Rules
```yaml
# Critical infrastructure alerts
- alert: NodeNotReady
  expr: kube_node_status_condition{condition="Ready",status="true"} == 0
  for: 2m
  labels:
    severity: critical

# Application performance alerts  
- alert: HighErrorRate
  expr: sum(rate(http_requests_total{status=~"5.."}[5m])) > 0.05
  for: 5m
  labels:
    severity: warning
```

### 3. Recording Rules for Performance
```yaml
# Pre-computed cluster metrics
- record: cluster:node_cpu_utilization:ratio
  expr: 1 - avg(irate(node_cpu_seconds_total{mode="idle"}[5m]))

- record: pod:cpu_usage:rate5m
  expr: sum(rate(container_cpu_usage_seconds_total[5m])) by (pod, namespace)
```

### 4. Grafana Dashboards
- **Kubernetes Cluster Overview**: CPU, memory, pod status
- **Node Monitoring**: Per-node resource utilization
- **Pod Monitoring**: Container metrics and health
- **Application Metrics**: Custom application dashboards

## 🚀 Deployment Guide

### 1. Deploy Monitoring Stack
```bash
# Deploy complete monitoring solution
kubectl apply -f complete-monitoring-solution.yaml

# Verify deployment
kubectl get pods -n observability
kubectl get services -n observability

# Check RBAC permissions
kubectl get clusterrole prometheus
kubectl get clusterrolebinding prometheus
```

### 2. Access Monitoring Tools
```bash
# Access Prometheus
kubectl port-forward -n observability svc/prometheus 9090:9090
# Open: http://localhost:9090

# Access Grafana
kubectl port-forward -n observability svc/grafana 3000:3000
# Open: http://localhost:3000 (admin/admin123)
```

### 3. Validate Monitoring
```bash
# Run monitoring validation
./scripts/validate-monitoring.sh

# Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'

# Test alert rules
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[].rules[] | select(.type == "alerting")'
```

## 📈 Monitoring Best Practices

### 1. Metrics Collection
```yaml
# Use consistent labels
labels:
  app.kubernetes.io/name: myapp
  app.kubernetes.io/version: "1.0.0"
  environment: production

# Proper annotations for scraping
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "9090"
  prometheus.io/path: "/metrics"
```

### 2. Alert Rule Design
```yaml
# Good alert rule structure
- alert: HighCPUUsage
  expr: cpu_usage_percent > 80
  for: 10m  # Wait before firing
  labels:
    severity: warning
    team: platform
  annotations:
    summary: "High CPU usage on {{ $labels.instance }}"
    description: "CPU usage is {{ $value }}% for 10+ minutes"
    runbook_url: "https://wiki.company.com/runbooks/high-cpu"
```

### 3. Dashboard Organization
- **Overview Dashboards**: High-level cluster health
- **Detailed Dashboards**: Per-service deep dives
- **Troubleshooting Dashboards**: Debug-focused views
- **SLO Dashboards**: Service level objectives

## 🔧 Configuration Examples

### Application Instrumentation
```yaml
# Application with metrics endpoint
apiVersion: apps/v1
kind: Deployment
metadata:
  name: instrumented-app
spec:
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: app
        image: myapp:1.0.0
        ports:
        - name: metrics
          containerPort: 8080
```

### Custom Service Monitor
```yaml
# ServiceMonitor for custom application
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp-monitor
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

### Alert Manager Integration
```yaml
# Route alerts to different channels
route:
  group_by: ['alertname', 'severity']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'default'
  routes:
  - match:
      severity: critical
    receiver: 'critical-alerts'
  - match:
      team: platform
    receiver: 'platform-team'
```

## 📊 Key Metrics to Monitor

### Infrastructure Metrics
- **CPU Usage**: `100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
- **Memory Usage**: `(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100`
- **Disk Usage**: `(node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100`
- **Network I/O**: `rate(node_network_receive_bytes_total[5m])` / `rate(node_network_transmit_bytes_total[5m])`

### Kubernetes Metrics
- **Pod Restarts**: `rate(kube_pod_container_status_restarts_total[5m])`
- **Pod Status**: `kube_pod_status_phase{phase=~"Pending|Unknown|Failed"}`
- **Node Condition**: `kube_node_status_condition{condition="Ready",status="false"}`
- **Resource Quotas**: `kube_resourcequota{resource="requests.cpu"}`

### Application Metrics (Golden Signals)
- **Latency**: Response time percentiles (p50, p95, p99)
- **Traffic**: Request rate (requests per second)
- **Errors**: Error rate (errors per second)
- **Saturation**: Resource utilization (CPU, memory, connections)

## 🚨 Common Alert Rules

### Infrastructure Alerts
```yaml
# Node down
- alert: NodeDown
  expr: up{job="kubernetes-nodes"} == 0
  for: 5m

# High memory usage
- alert: NodeHighMemory
  expr: node_memory_usage_percent > 85
  for: 10m

# Disk space low
- alert: NodeLowDisk
  expr: node_filesystem_usage_percent > 85
  for: 5m
```

### Application Alerts
```yaml
# Application down
- alert: ApplicationDown
  expr: up{job="my-application"} == 0
  for: 1m

# High error rate
- alert: HighErrorRate
  expr: http_requests_error_rate > 5
  for: 5m

# High latency
- alert: HighLatency
  expr: http_request_duration_p95 > 0.5
  for: 5m
```

## 🔍 Troubleshooting Guide

### Prometheus Issues
```bash
# Check configuration
kubectl logs -n observability deployment/prometheus | grep -i error

# Validate config syntax
kubectl exec -n observability deployment/prometheus -- promtool check config /etc/prometheus/prometheus.yml

# Check targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'
```

### Grafana Issues
```bash
# Check datasource connectivity
kubectl logs -n observability deployment/grafana | grep -i error

# Test datasource manually
curl -X POST http://admin:admin123@localhost:3000/api/datasources/proxy/1/api/v1/query?query=up
```

### Missing Metrics
```bash
# Check service discovery
kubectl get endpoints -n observability

# Verify pod annotations
kubectl get pods -o yaml | grep -A 3 "prometheus.io"

# Check RBAC permissions
kubectl auth can-i get pods --as=system:serviceaccount:observability:prometheus
```

## 📚 Additional Resources

- [Prometheus Configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Kubernetes Monitoring](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/)
- [SRE Monitoring](https://sre.google/sre-book/monitoring-distributed-systems/)

## 🎯 Production Checklist

- [ ] Prometheus retention configured (storage)
- [ ] Grafana datasources automated provisioning
- [ ] Alert rules tested and validated
- [ ] Notification channels configured
- [ ] Dashboard access controls set up
- [ ] Metrics backup/disaster recovery plan
- [ ] Performance impact assessment
- [ ] Documentation and runbooks created
- [ ] Team training completed
- [ ] Monitoring monitoring (meta-monitoring)

---

*Observability is not just about collecting data—it's about gaining insights that enable better decisions and faster problem resolution!* 📊