# Monitoring: Kubernetes Observability and Troubleshooting

Master Kubernetes observability through metrics collection, logging, distributed tracing, and performance monitoring for production environments.

## 🎯 Learning Objectives

By the end of this module, you will be able to:
- Set up comprehensive monitoring with Prometheus and Grafana
- Implement centralized logging with the ELK/EFK stack
- Configure alerting and notification systems
- Perform distributed tracing with Jaeger
- Troubleshoot performance and reliability issues
- Monitor application and infrastructure metrics
- Implement SLO/SLI-based monitoring strategies

## 📚 Prerequisites

- ✅ Completed **deploying-apps**, **services-ingress**, **configmaps-secrets** modules
- ✅ Basic understanding of monitoring concepts (metrics, logs, traces)
- ✅ Familiarity with PromQL (Prometheus Query Language) helpful
- ✅ Understanding of HTTP status codes and performance metrics

## 🗂️ Module Structure

```
monitoring/
├── README.md           # Complete monitoring guide
├── manifests/          # Monitoring configurations
│   ├── prometheus-stack.yaml         # Prometheus deployment
│   ├── grafana-dashboards.yaml       # Grafana setup
│   ├── logging-stack.yaml            # Centralized logging
│   ├── alerting-rules.yaml           # Alert configurations
│   ├── jaeger-tracing.yaml           # Distributed tracing
│   └── application-monitoring.yaml    # App instrumentation
├── scripts/            # Monitoring automation
└── solutions/          # Reference monitoring setups
```

## 📊 Observability Pillars

### The Three Pillars of Observability

```
┌─────────────────────────────────────────────────────────┐
│                      OBSERVABILITY                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │
│  │   METRICS   │  │    LOGS     │  │     TRACES      │  │
│  │             │  │             │  │                 │  │
│  │ • Prometheus│  │ • Fluentd   │  │ • Jaeger        │  │
│  │ • Grafana   │  │ • Elasticsearch│  │ • OpenTelemetry│  │
│  │ • AlertMgr  │  │ • Kibana    │  │ • Zipkin        │  │
│  └─────────────┘  └─────────────┘  └─────────────────┘  │
│         │                 │                   │         │
│         └─────────────────┼───────────────────┘         │
│                           │                             │
│                    CORRELATION                          │
└─────────────────────────────────────────────────────────┘
```

### Monitoring Stack Components

| Component | Purpose | Data Type | Retention |
|-----------|---------|-----------|-----------|
| **Prometheus** | Metrics collection & storage | Time series | 15-30 days |
| **Grafana** | Visualization & dashboards | Visual | N/A |
| **AlertManager** | Alert routing & notification | Alerts | N/A |
| **Fluentd/Fluent Bit** | Log collection & forwarding | Logs | Variable |
| **Elasticsearch** | Log storage & search | Documents | 7-90 days |
| **Jaeger** | Distributed tracing | Traces | 1-7 days |

## 🚀 Lab Exercises

### Lab 1: Prometheus and Grafana Setup (30 minutes)

**Objective**: Deploy a complete metrics monitoring stack.

#### Step 1: Deploy Prometheus Stack
```bash
# Navigate to monitoring module
cd 03-hands-on/monitoring

# Create monitoring namespace
kubectl create namespace monitoring

# Deploy Prometheus with RBAC
cat > manifests/prometheus-stack.yaml << 'EOF'
# Prometheus ServiceAccount and RBAC
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources:
  - nodes
  - nodes/proxy
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups:
  - extensions
  resources:
  - ingresses
  verbs: ["get", "list", "watch"]
- nonResourceURLs: ["/metrics"]
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: monitoring
---
# Prometheus Configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    
    rule_files:
    - "alert_rules.yml"
    
    alerting:
      alertmanagers:
      - static_configs:
        - targets:
          - alertmanager:9093
    
    scrape_configs:
    - job_name: 'prometheus'
      static_configs:
      - targets: ['localhost:9090']
    
    - job_name: 'kubernetes-apiservers'
      kubernetes_sd_configs:
      - role: endpoints
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      relabel_configs:
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
        action: keep
        regex: default;kubernetes;https
    
    - job_name: 'kubernetes-nodes'
      kubernetes_sd_configs:
      - role: node
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - target_label: __address__
        replacement: kubernetes.default.svc:443
      - source_labels: [__meta_kubernetes_node_name]
        regex: (.+)
        target_label: __metrics_path__
        replacement: /api/v1/nodes/${1}/proxy/metrics
    
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: kubernetes_pod_name

  alert_rules.yml: |
    groups:
    - name: kubernetes-alerts
      rules:
      - alert: PodCrashLooping
        expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
        for: 0m
        labels:
          severity: warning
        annotations:
          summary: "Pod {{ $labels.pod }} is crash looping"
          description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is restarting frequently"
      
      - alert: NodeNotReady
        expr: kube_node_status_condition{condition="Ready",status="true"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Node {{ $labels.node }} is not ready"
          description: "Node {{ $labels.node }} has been unready for more than 2 minutes"
      
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 80% for more than 5 minutes"
---
# Prometheus Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      serviceAccountName: prometheus
      securityContext:
        runAsNonRoot: true
        runAsUser: 65534
        fsGroup: 65534
      containers:
      - name: prometheus
        image: prom/prometheus:v2.45.0
        args:
        - '--config.file=/etc/prometheus/prometheus.yml'
        - '--storage.tsdb.path=/prometheus/'
        - '--web.console.libraries=/etc/prometheus/console_libraries'
        - '--web.console.templates=/etc/prometheus/consoles'
        - '--storage.tsdb.retention.time=15d'
        - '--web.enable-lifecycle'
        ports:
        - containerPort: 9090
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        volumeMounts:
        - name: prometheus-config
          mountPath: /etc/prometheus/
        - name: prometheus-storage
          mountPath: /prometheus/
        securityContext:
          runAsNonRoot: true
          runAsUser: 65534
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
      volumes:
      - name: prometheus-config
        configMap:
          name: prometheus-config
      - name: prometheus-storage
        emptyDir: {}
---
# Prometheus Service
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: monitoring
  labels:
    app: prometheus
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090
    name: web
  type: ClusterIP
EOF

kubectl apply -f manifests/prometheus-stack.yaml
```

#### Step 2: Deploy Grafana
```bash
cat > manifests/grafana-setup.yaml << 'EOF'
# Grafana ConfigMap for dashboards
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards-config
  namespace: monitoring
data:
  kubernetes-cluster.json: |
    {
      "dashboard": {
        "id": null,
        "title": "Kubernetes Cluster Overview",
        "tags": ["kubernetes"],
        "style": "dark",
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "Cluster CPU Usage",
            "type": "stat",
            "targets": [
              {
                "expr": "100 - (avg(irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
                "refId": "A"
              }
            ],
            "fieldConfig": {
              "defaults": {
                "unit": "percent",
                "min": 0,
                "max": 100
              }
            },
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
          },
          {
            "id": 2,
            "title": "Memory Usage",
            "type": "stat",
            "targets": [
              {
                "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
                "refId": "A"
              }
            ],
            "fieldConfig": {
              "defaults": {
                "unit": "percent",
                "min": 0,
                "max": 100
              }
            },
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
          }
        ],
        "time": {
          "from": "now-1h",
          "to": "now"
        },
        "refresh": "30s"
      }
    }
---
# Grafana Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 65534
        fsGroup: 65534
      containers:
      - name: grafana
        image: grafana/grafana:10.1.0
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin123"
        - name: GF_SECURITY_ADMIN_USER
          value: "admin"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
        - name: grafana-dashboards
          mountPath: /var/lib/grafana/dashboards
        securityContext:
          runAsNonRoot: true
          runAsUser: 65534
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
      volumes:
      - name: grafana-storage
        emptyDir: {}
      - name: grafana-dashboards
        configMap:
          name: grafana-dashboards-config
---
# Grafana Service
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: monitoring
  labels:
    app: grafana
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
    targetPort: 3000
    name: web
  type: ClusterIP
EOF

kubectl apply -f manifests/grafana-setup.yaml
```

#### Step 3: Access Monitoring Dashboards
```bash
# Port forward to access Prometheus
kubectl port-forward -n monitoring service/prometheus 9090:9090 &

# Port forward to access Grafana
kubectl port-forward -n monitoring service/grafana 3000:3000 &

echo "Access Prometheus at: http://localhost:9090"
echo "Access Grafana at: http://localhost:3000 (admin/admin123)"

# Wait for deployments to be ready
kubectl rollout status deployment/prometheus -n monitoring
kubectl rollout status deployment/grafana -n monitoring
```

### Lab 2: Application Instrumentation (25 minutes)

**Objective**: Add metrics to applications and monitor custom metrics.

#### Step 1: Deploy Instrumented Application
```bash
cat > manifests/application-monitoring.yaml << 'EOF'
# Sample application with Prometheus metrics
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: sample-app
        image: nginx:1.25-alpine
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 9113
          name: metrics
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
      # Sidecar for nginx metrics
      - name: nginx-exporter
        image: nginx/nginx-prometheus-exporter:0.11.0
        ports:
        - containerPort: 9113
          name: metrics
        args:
        - -nginx.scrape-uri=http://localhost:8080/nginx_status
        resources:
          requests:
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "64Mi"
            cpu: "200m"
        securityContext:
          runAsNonRoot: true
          runAsUser: 65534
          allowPrivilegeEscalation: false
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app
  labels:
    app: sample-app
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 8080
    name: http
  - port: 9113
    targetPort: 9113
    name: metrics
---
# Load generator to create metrics
apiVersion: apps/v1
kind: Deployment
metadata:
  name: load-generator
spec:
  replicas: 1
  selector:
    matchLabels:
      app: load-generator
  template:
    metadata:
      labels:
        app: load-generator
    spec:
      containers:
      - name: load-generator
        image: busybox:1.35
        command: ["/bin/sh", "-c"]
        args:
        - |
          while true; do
            wget -qO- http://sample-app/
            sleep 2
          done
        resources:
          requests:
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "64Mi"
            cpu: "200m"
EOF

kubectl apply -f manifests/application-monitoring.yaml
```

#### Step 2: Create Custom Dashboards
```bash
# Create a comprehensive Grafana dashboard
cat > manifests/custom-dashboard.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-dashboard
  namespace: monitoring
data:
  application-metrics.json: |
    {
      "dashboard": {
        "id": null,
        "title": "Application Metrics",
        "tags": ["application", "nginx"],
        "style": "dark",
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "Request Rate",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(nginx_http_requests_total[5m])",
                "legendFormat": "{{instance}} - {{status}}",
                "refId": "A"
              }
            ],
            "yAxes": [
              {
                "unit": "reqps",
                "min": 0
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
          },
          {
            "id": 2,
            "title": "Response Time",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(nginx_http_request_duration_seconds_sum[5m]) / rate(nginx_http_request_duration_seconds_count[5m])",
                "legendFormat": "{{instance}}",
                "refId": "A"
              }
            ],
            "yAxes": [
              {
                "unit": "s",
                "min": 0
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
          },
          {
            "id": 3,
            "title": "Pod CPU Usage",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(container_cpu_usage_seconds_total{pod=~\"sample-app-.*\"}[5m])",
                "legendFormat": "{{pod}}",
                "refId": "A"
              }
            ],
            "yAxes": [
              {
                "unit": "percent",
                "min": 0
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8}
          },
          {
            "id": 4,
            "title": "Pod Memory Usage",
            "type": "graph",
            "targets": [
              {
                "expr": "container_memory_usage_bytes{pod=~\"sample-app-.*\"}",
                "legendFormat": "{{pod}}",
                "refId": "A"
              }
            ],
            "yAxes": [
              {
                "unit": "bytes",
                "min": 0
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8}
          }
        ],
        "time": {
          "from": "now-1h",
          "to": "now"
        },
        "refresh": "30s"
      }
    }
EOF

kubectl apply -f manifests/custom-dashboard.yaml
```

### Lab 3: Centralized Logging (25 minutes)

**Objective**: Set up log aggregation and search capabilities.

#### Step 1: Deploy Logging Stack
```bash
cat > manifests/logging-stack.yaml << 'EOF'
# Elasticsearch for log storage
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
      - name: elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:8.9.0
        env:
        - name: discovery.type
          value: single-node
        - name: ES_JAVA_OPTS
          value: "-Xms512m -Xmx512m"
        - name: xpack.security.enabled
          value: "false"
        ports:
        - containerPort: 9200
        - containerPort: 9300
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        volumeMounts:
        - name: es-data
          mountPath: /usr/share/elasticsearch/data
      volumes:
      - name: es-data
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
  namespace: monitoring
spec:
  selector:
    app: elasticsearch
  ports:
  - port: 9200
    targetPort: 9200
---
# Kibana for log visualization
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
    spec:
      containers:
      - name: kibana
        image: docker.elastic.co/kibana/kibana:8.9.0
        env:
        - name: ELASTICSEARCH_HOSTS
          value: "http://elasticsearch:9200"
        ports:
        - containerPort: 5601
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: kibana
  namespace: monitoring
spec:
  selector:
    app: kibana
  ports:
  - port: 5601
    targetPort: 5601
---
# Fluent Bit DaemonSet for log collection
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluent-bit
  namespace: monitoring
spec:
  selector:
    matchLabels:
      name: fluent-bit
  template:
    metadata:
      labels:
        name: fluent-bit
    spec:
      serviceAccountName: fluent-bit
      containers:
      - name: fluent-bit
        image: fluent/fluent-bit:2.1.8
        ports:
        - containerPort: 24224
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        volumeMounts:
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: fluent-bit-config
          mountPath: /fluent-bit/etc/
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: fluent-bit-config
        configMap:
          name: fluent-bit-config
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluent-bit
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: fluent-bit-read
rules:
- apiGroups: [""]
  resources:
  - namespaces
  - pods
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: fluent-bit-read
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: fluent-bit-read
subjects:
- kind: ServiceAccount
  name: fluent-bit
  namespace: monitoring
---
# Fluent Bit Configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-config
  namespace: monitoring
data:
  fluent-bit.conf: |
    [SERVICE]
        Flush         1
        Log_Level     info
        Daemon        off
        Parsers_File  parsers.conf
    
    [INPUT]
        Name              tail
        Path              /var/log/containers/*.log
        Parser            docker
        Tag               kube.*
        Refresh_Interval  5
        Mem_Buf_Limit     50MB
        Skip_Long_Lines   On
    
    [FILTER]
        Name                kubernetes
        Match               kube.*
        Kube_URL            https://kubernetes.default.svc:443
        Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
        Merge_Log           On
        K8S-Logging.Parser  On
        K8S-Logging.Exclude Off
    
    [OUTPUT]
        Name  es
        Match *
        Host  elasticsearch
        Port  9200
        Index kubernetes_logs
        Type  _doc
        Retry_Limit False
  
  parsers.conf: |
    [PARSER]
        Name        docker
        Format      json
        Time_Key    time
        Time_Format %Y-%m-%dT%H:%M:%S.%L
        Time_Keep   On
EOF

kubectl apply -f manifests/logging-stack.yaml
```

#### Step 2: Access Logging Dashboard
```bash
# Port forward to access Kibana
kubectl port-forward -n monitoring service/kibana 5601:5601 &

echo "Access Kibana at: http://localhost:5601"

# Wait for services to be ready
kubectl rollout status deployment/elasticsearch -n monitoring
kubectl rollout status deployment/kibana -n monitoring
kubectl rollout status daemonset/fluent-bit -n monitoring
```

### Lab 4: Alerting and Notifications (20 minutes)

**Objective**: Configure alerts and notification channels.

#### Step 1: Deploy AlertManager
```bash
cat > manifests/alerting-rules.yaml << 'EOF'
# AlertManager Configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
  namespace: monitoring
data:
  config.yml: |
    global:
      smtp_smarthost: 'localhost:587'
      smtp_from: 'alerts@company.com'
    
    route:
      group_by: ['alertname']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'web.hook'
      routes:
      - match:
          severity: critical
        receiver: 'critical-alerts'
      - match:
          severity: warning
        receiver: 'warning-alerts'
    
    receivers:
    - name: 'web.hook'
      webhook_configs:
      - url: 'http://webhook-service:5001/alerts'
        send_resolved: true
    
    - name: 'critical-alerts'
      slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#critical-alerts'
        title: 'Critical Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
    
    - name: 'warning-alerts'
      slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#warnings'
        title: 'Warning Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
---
# AlertManager Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: alertmanager
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: alertmanager
  template:
    metadata:
      labels:
        app: alertmanager
    spec:
      containers:
      - name: alertmanager
        image: prom/alertmanager:v0.25.0
        args:
        - '--config.file=/etc/alertmanager/config.yml'
        - '--storage.path=/alertmanager'
        ports:
        - containerPort: 9093
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        volumeMounts:
        - name: alertmanager-config
          mountPath: /etc/alertmanager
        - name: alertmanager-storage
          mountPath: /alertmanager
      volumes:
      - name: alertmanager-config
        configMap:
          name: alertmanager-config
      - name: alertmanager-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: alertmanager
  namespace: monitoring
spec:
  selector:
    app: alertmanager
  ports:
  - port: 9093
    targetPort: 9093
EOF

kubectl apply -f manifests/alerting-rules.yaml
```

#### Step 2: Test Alerting
```bash
# Port forward to access AlertManager
kubectl port-forward -n monitoring service/alertmanager 9093:9093 &

echo "Access AlertManager at: http://localhost:9093"

# Create a pod that will trigger alerts
kubectl run stress-test --image=busybox:1.35 --restart=Never --rm -it -- sh -c "
while true; do
  echo 'High CPU usage simulation'
  yes > /dev/null &
  sleep 30
  kill %1
  sleep 30
done
"
```

## 📋 Validation and Testing

### Module Validation Commands
```bash
# Run comprehensive monitoring validation
./scripts/validate-monitoring.sh

# Manual monitoring checks:
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Check metrics collection
curl http://localhost:9090/api/v1/query?query=up

# Check Grafana datasource
curl -u admin:admin123 http://localhost:3000/api/datasources
```

### Success Criteria
✅ **Metrics Collection**:
- Prometheus collecting cluster and application metrics
- Custom metrics from application instrumentation
- Dashboards displaying real-time data

✅ **Logging**:
- Centralized log collection from all pods
- Log search and filtering capabilities
- Structured logging with metadata

✅ **Alerting**:
- Alert rules triggering based on conditions
- Notifications routing to appropriate channels
- Alert resolution and acknowledgment

## 🔧 Troubleshooting Guide

### Prometheus Issues
```bash
# Check Prometheus configuration
kubectl exec -n monitoring deployment/prometheus -- promtool check config /etc/prometheus/prometheus.yml

# Check targets
curl http://localhost:9090/api/v1/targets

# Check service discovery
kubectl logs -n monitoring deployment/prometheus
```

### Grafana Issues
```bash
# Check datasource connectivity
kubectl logs -n monitoring deployment/grafana

# Test dashboard queries
curl -u admin:admin123 "http://localhost:3000/api/datasources/proxy/1/api/v1/query?query=up"
```

### Logging Issues
```bash
# Check log collection
kubectl logs -n monitoring daemonset/fluent-bit

# Check Elasticsearch indices
curl http://localhost:9200/_cat/indices

# Check Kibana connectivity
kubectl logs -n monitoring deployment/kibana
```

## 🎯 Advanced Challenges

### Challenge 1: SLO/SLI Implementation
Implement Service Level Objectives with error budgets.

### Challenge 2: Distributed Tracing
Add Jaeger for end-to-end request tracing.

### Challenge 3: Custom Metrics
Create business-specific metrics and dashboards.

## ⏭️ Next Steps

After completing this module:
1. ✅ Clean up resources: `kubectl delete -f manifests/ --recursive`
2. ✅ Explore advanced monitoring patterns
3. ✅ Practice incident response workflows

---

*Excellent work! You now have comprehensive observability for your Kubernetes environments. Remember: monitoring is not just about collecting data, but about actionable insights!* 📊