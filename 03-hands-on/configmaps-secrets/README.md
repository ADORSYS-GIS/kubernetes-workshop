# Configuration Management: ConfigMaps and Secrets

Learn how to manage application configuration and sensitive data securely in Kubernetes using ConfigMaps and Secrets.

## 🎯 Learning Objectives

By the end of this module, you will be able to:
- Create and manage ConfigMaps for application configuration
- Handle sensitive data securely with Secrets
- Mount configurations as volumes or environment variables
- Implement configuration hot-reloading patterns
- Apply security best practices for secrets management
- Troubleshoot configuration-related issues

## 📚 Prerequisites

- ✅ Completed **deploying-apps** and **services-ingress** modules
- ✅ Understanding of environment variables and file systems
- ✅ Basic knowledge of application configuration concepts
- ✅ Familiarity with base64 encoding (helpful)

## 🗂️ Module Structure

```
configmaps-secrets/
├── README.md           # Complete learning guide
├── manifests/          # Configuration examples
│   ├── app-configmap.yaml          # Basic ConfigMap
│   ├── database-secret.yaml        # Secret management
│   ├── config-volume-mount.yaml    # File-based config
│   ├── config-env-vars.yaml        # Environment variables
│   ├── multi-source-config.yaml    # Multiple config sources
│   └── hot-reload-demo.yaml        # Configuration updates
├── scripts/            # Helper and validation scripts
└── solutions/          # Reference implementations
```

## 🔧 Understanding Configuration Management

### ConfigMaps vs Secrets

| Aspect | ConfigMaps | Secrets |
|--------|------------|---------|
| **Purpose** | Non-sensitive configuration | Sensitive data |
| **Storage** | Plain text | Base64 encoded |
| **Security** | Basic | Enhanced (encryption at rest) |
| **Size Limit** | 1MB | 1MB |
| **Use Cases** | App settings, config files | Passwords, tokens, certificates |

### Configuration Patterns

1. **Environment Variables**: Simple key-value pairs
2. **Volume Mounts**: Configuration files in containers
3. **Init Containers**: Configuration preprocessing
4. **Sidecar Containers**: Dynamic configuration updates

## 🚀 Lab Exercises

### Lab 1: Basic ConfigMaps (15 minutes)

**Objective**: Create and use ConfigMaps for application configuration.

#### Step 1: Create ConfigMap from Literals
```bash
# Navigate to module directory
cd 03-hands-on/configmaps-secrets

# Create ConfigMap using kubectl
kubectl create configmap app-config \
  --from-literal=database_host=postgresql.default.svc.cluster.local \
  --from-literal=database_port=5432 \
  --from-literal=log_level=INFO \
  --from-literal=debug_mode=false

# View the ConfigMap
kubectl get configmap app-config -o yaml
kubectl describe configmap app-config
```

#### Step 2: Create ConfigMap from File
```bash
# Create a configuration file
cat > app.properties << 'EOF'
# Application Configuration
server.port=8080
server.host=0.0.0.0
database.url=jdbc:postgresql://postgresql:5432/myapp
database.pool.min=5
database.pool.max=20
cache.enabled=true
cache.ttl=3600
logging.level=INFO
features.new_ui=true
features.analytics=false
EOF

# Create ConfigMap from file
kubectl create configmap app-properties --from-file=app.properties

# Create nginx configuration
mkdir -p nginx-conf
cat > nginx-conf/nginx.conf << 'EOF'
server {
    listen 8080;
    server_name localhost;
    
    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
    
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    location /api/ {
        proxy_pass http://backend-service/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

kubectl create configmap nginx-config --from-file=nginx-conf/

# Clean up local files
rm app.properties
rm -rf nginx-conf/
```

#### Step 3: Create ConfigMap from YAML
```bash
cat > manifests/app-configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: webapp-config
  labels:
    app: webapp
    component: config
data:
  # Simple key-value pairs
  DATABASE_HOST: "postgresql.default.svc.cluster.local"
  DATABASE_PORT: "5432"
  REDIS_HOST: "redis.default.svc.cluster.local"
  REDIS_PORT: "6379"
  LOG_LEVEL: "INFO"
  
  # Multi-line configuration file
  app.yaml: |
    server:
      port: 8080
      host: 0.0.0.0
    database:
      host: postgresql.default.svc.cluster.local
      port: 5432
      name: webapp
      ssl: true
    redis:
      host: redis.default.svc.cluster.local
      port: 6379
      db: 0
    logging:
      level: INFO
      format: json
    features:
      new_dashboard: true
      beta_features: false
      
  # JSON configuration
  config.json: |
    {
      "api": {
        "version": "v1",
        "timeout": 30,
        "retries": 3
      },
      "auth": {
        "provider": "oauth2",
        "scopes": ["read", "write"]
      },
      "monitoring": {
        "metrics": true,
        "tracing": true
      }
    }
EOF

kubectl apply -f manifests/app-configmap.yaml
```

### Lab 2: Secrets Management (20 minutes)

**Objective**: Handle sensitive data securely using Secrets.

#### Step 1: Create Secrets from Command Line
```bash
# Create generic secret
kubectl create secret generic database-credentials \
  --from-literal=username=webapp_user \
  --from-literal=password=super_secret_password \
  --from-literal=connection_string="postgresql://webapp_user:super_secret_password@postgresql:5432/webapp?sslmode=require"

# Create TLS secret (using existing or generate new)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=webapp.local/O=webapp"

kubectl create secret tls webapp-tls --key=tls.key --cert=tls.crt

rm tls.key tls.crt

# Create docker registry secret
kubectl create secret docker-registry my-registry-secret \
  --docker-server=my-registry.com \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=myuser@example.com
```

#### Step 2: Create Secrets from YAML
```bash
# Note: In real scenarios, never put secrets in YAML files!
# This is for educational purposes only
cat > manifests/database-secret.yaml << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: webapp-secrets
  labels:
    app: webapp
    component: secrets
type: Opaque
data:
  # Base64 encoded values (echo -n 'value' | base64)
  db-username: d2ViYXBwX3VzZXI=        # webapp_user
  db-password: c3VwZXJfc2VjcmV0X3Bhc3N3b3Jk  # super_secret_password
  api-key: YWJjZGVmZ2hpams=              # abcdefghijk
  jwt-secret: bXlfc3VwZXJfc2VjcmV0X2p3dF9rZXk=  # my_super_secret_jwt_key
stringData:
  # Plain text values (automatically base64 encoded)
  redis-url: "redis://redis.default.svc.cluster.local:6379/0"
  smtp-config: |
    host: smtp.example.com
    port: 587
    username: noreply@example.com
    password: smtp_password
    tls: true
---
# Service account token secret
apiVersion: v1
kind: Secret
metadata:
  name: webapp-service-account-token
  annotations:
    kubernetes.io/service-account.name: webapp-service-account
type: kubernetes.io/service-account-token
EOF

kubectl apply -f manifests/database-secret.yaml

# Verify secrets
kubectl get secrets
kubectl describe secret webapp-secrets
```

### Lab 3: Using Configurations in Pods (25 minutes)

**Objective**: Mount configurations as environment variables and volume mounts.

#### Step 1: Environment Variables from ConfigMaps and Secrets
```bash
cat > manifests/config-env-vars.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-env-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp-env-demo
  template:
    metadata:
      labels:
        app: webapp-env-demo
    spec:
      containers:
      - name: webapp
        image: nginx:1.25-alpine
        ports:
        - containerPort: 8080
        env:
        # Individual values from ConfigMap
        - name: DATABASE_HOST
          valueFrom:
            configMapKeyRef:
              name: webapp-config
              key: DATABASE_HOST
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: webapp-config
              key: LOG_LEVEL
        # Individual values from Secret
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: webapp-secrets
              key: db-username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: webapp-secrets
              key: db-password
        # All keys from ConfigMap as env vars
        envFrom:
        - configMapRef:
            name: app-config
        # All keys from Secret as env vars (with prefix)
        - secretRef:
            name: webapp-secrets
        # Static environment variables
        - name: APP_VERSION
          value: "1.0.0"
        - name: ENVIRONMENT
          value: "development"
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        securityContext:
          runAsNonRoot: true
          runAsUser: 65534
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
        volumeMounts:
        - name: tmp-volume
          mountPath: /tmp
      volumes:
      - name: tmp-volume
        emptyDir: {}
EOF

kubectl apply -f manifests/config-env-vars.yaml
```

#### Step 2: Volume Mounts for Configuration Files
```bash
cat > manifests/config-volume-mount.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-volume-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp-volume-demo
  template:
    metadata:
      labels:
        app: webapp-volume-demo
    spec:
      containers:
      - name: webapp
        image: nginx:1.25-alpine
        ports:
        - containerPort: 8080
        volumeMounts:
        # Mount entire ConfigMap as directory
        - name: app-config-volume
          mountPath: /etc/config
          readOnly: true
        # Mount specific ConfigMap key as file
        - name: nginx-config-volume
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: nginx.conf
          readOnly: true
        # Mount Secret as files
        - name: secret-volume
          mountPath: /etc/secrets
          readOnly: true
        # Writable directories
        - name: tmp-volume
          mountPath: /tmp
        - name: cache-volume
          mountPath: /var/cache/nginx
        - name: run-volume
          mountPath: /var/run
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        securityContext:
          runAsNonRoot: true
          runAsUser: 65534
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
      volumes:
      # ConfigMap volumes
      - name: app-config-volume
        configMap:
          name: webapp-config
      - name: nginx-config-volume
        configMap:
          name: nginx-config
          items:
          - key: nginx.conf
            path: nginx.conf
            mode: 0644
      # Secret volume with specific permissions
      - name: secret-volume
        secret:
          secretName: webapp-secrets
          defaultMode: 0600
          items:
          - key: db-username
            path: database/username
          - key: db-password
            path: database/password
          - key: api-key
            path: api/key
      # Writable volumes
      - name: tmp-volume
        emptyDir: {}
      - name: cache-volume
        emptyDir: {}
      - name: run-volume
        emptyDir: {}
EOF

kubectl apply -f manifests/config-volume-mount.yaml
```

#### Step 3: Verify Configuration Loading
```bash
# Check environment variables
kubectl exec deployment/webapp-env-demo -- env | grep -E "(DATABASE|LOG_LEVEL|DB_)"

# Check mounted files
kubectl exec deployment/webapp-volume-demo -- ls -la /etc/config/
kubectl exec deployment/webapp-volume-demo -- cat /etc/config/app.yaml
kubectl exec deployment/webapp-volume-demo -- ls -la /etc/secrets/
kubectl exec deployment/webapp-volume-demo -- cat /etc/secrets/database/username

# Check nginx configuration
kubectl exec deployment/webapp-volume-demo -- cat /etc/nginx/conf.d/default.conf
```

### Lab 4: Configuration Hot-Reloading (20 minutes)

**Objective**: Update configurations without restarting pods.

#### Step 1: Deploy Application with Configuration Watching
```bash
cat > manifests/hot-reload-demo.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: hot-reload-config
data:
  app.properties: |
    message=Hello from Kubernetes!
    refresh.rate=30
    feature.enabled=true
    color.theme=blue
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hot-reload-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hot-reload-app
  template:
    metadata:
      labels:
        app: hot-reload-app
    spec:
      containers:
      - name: config-watcher
        image: busybox:1.35
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "Starting configuration watcher..."
          while true; do
            echo "=== Configuration Update $(date) ==="
            echo "Current configuration:"
            cat /etc/config/app.properties
            echo "Watching for changes..."
            sleep 30
          done
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
          readOnly: true
        resources:
          requests:
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "64Mi"
            cpu: "200m"
      volumes:
      - name: config-volume
        configMap:
          name: hot-reload-config
EOF

kubectl apply -f manifests/hot-reload-demo.yaml

# Watch the logs
kubectl logs -f deployment/hot-reload-app
```

#### Step 2: Update Configuration and Observe Changes
```bash
# In another terminal, update the ConfigMap
kubectl patch configmap hot-reload-config --patch='
data:
  app.properties: |
    message=Configuration updated dynamically!
    refresh.rate=15
    feature.enabled=false
    color.theme=red
    new.feature=active
'

# The logs should show the updated configuration after a few seconds
# Note: It may take up to 60 seconds for kubelet to sync the changes
```

#### Step 3: Automatic Pod Restart on Config Changes
```bash
# Add annotation to trigger restart when config changes
kubectl patch deployment hot-reload-app -p '
{
  "spec": {
    "template": {
      "metadata": {
        "annotations": {
          "config/checksum": "'$(kubectl get configmap hot-reload-config -o yaml | sha256sum | cut -d ' ' -f 1)'"
        }
      }
    }
  }
}'

# This will trigger a rolling restart of pods
kubectl rollout status deployment/hot-reload-app
```

### Lab 5: Security Best Practices (15 minutes)

**Objective**: Implement security best practices for configuration management.

#### Step 1: Secure Secret Access with RBAC
```bash
cat > manifests/secure-config-demo.yaml << 'EOF'
# Service Account for the application
apiVersion: v1
kind: ServiceAccount
metadata:
  name: webapp-service-account
---
# Role with minimal permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: webapp-config-reader
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["webapp-config", "app-config"]
  verbs: ["get", "list"]
# Note: Intentionally NOT granting access to secrets
---
# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: webapp-config-reader-binding
subjects:
- kind: ServiceAccount
  name: webapp-service-account
roleRef:
  kind: Role
  name: webapp-config-reader
  apiGroup: rbac.authorization.k8s.io
---
# Deployment using the service account
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-webapp
  template:
    metadata:
      labels:
        app: secure-webapp
    spec:
      serviceAccountName: webapp-service-account
      securityContext:
        runAsNonRoot: true
        runAsUser: 65534
        fsGroup: 65534
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: webapp
        image: nginx:1.25-alpine
        securityContext:
          runAsNonRoot: true
          runAsUser: 65534
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
        env:
        # Only access allowed ConfigMaps
        - name: DATABASE_HOST
          valueFrom:
            configMapKeyRef:
              name: webapp-config
              key: DATABASE_HOST
        # Secrets are mounted as files with restricted permissions
        volumeMounts:
        - name: secret-volume
          mountPath: /etc/secrets
          readOnly: true
        - name: tmp-volume
          mountPath: /tmp
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
      volumes:
      - name: secret-volume
        secret:
          secretName: webapp-secrets
          defaultMode: 0400  # Read-only for owner only
      - name: tmp-volume
        emptyDir: {}
EOF

kubectl apply -f manifests/secure-config-demo.yaml
```

#### Step 2: Test Security Restrictions
```bash
# Test ConfigMap access (should work)
kubectl exec deployment/secure-webapp -- sh -c 'echo $DATABASE_HOST'

# Test secret file access (should work with restricted permissions)
kubectl exec deployment/secure-webapp -- ls -la /etc/secrets/

# Check file permissions
kubectl exec deployment/secure-webapp -- ls -la /etc/secrets/db-username
kubectl exec deployment/secure-webapp -- cat /etc/secrets/db-username
```

## 📋 Validation and Testing

### Module Validation Commands
```bash
# Run comprehensive validation
./scripts/validate-configmaps-secrets.sh

# Manual testing:
# Verify ConfigMaps are created
kubectl get configmaps

# Verify Secrets are created
kubectl get secrets

# Test environment variable injection
kubectl exec deployment/webapp-env-demo -- env | grep DATABASE_HOST

# Test volume mounts
kubectl exec deployment/webapp-volume-demo -- ls /etc/config/
```

### Success Criteria
✅ **Configuration Management**:
- Can create ConfigMaps from various sources
- Can manage Secrets securely
- Understand different mounting strategies

✅ **Security Practices**:
- Implement proper file permissions for secrets
- Use RBAC for configuration access
- Apply principle of least privilege

✅ **Operational Knowledge**:
- Can troubleshoot configuration issues
- Understand hot-reloading concepts
- Can update configurations safely

## 🔧 Troubleshooting Guide

### Configuration Not Loading
```bash
# Check ConfigMap/Secret exists
kubectl get configmap <name>
kubectl describe configmap <name>

# Check pod environment
kubectl exec <pod> -- env

# Check mounted files
kubectl exec <pod> -- ls -la /path/to/mount/
```

### Permission Denied Errors
```bash
# Check security contexts
kubectl describe pod <pod-name>

# Check file permissions
kubectl exec <pod> -- ls -la /etc/secrets/

# Check RBAC permissions
kubectl auth can-i get configmaps --as=system:serviceaccount:default:webapp-service-account
```

## 🎯 Advanced Challenges

### Challenge 1: External Configuration
Integrate with external configuration systems (Consul, etcd).

### Challenge 2: Configuration Validation
Implement configuration validation before pod startup.

### Challenge 3: Multi-Environment Configuration
Design configuration strategy for dev/staging/production environments.

## ⏭️ Next Steps

After completing this module:
1. ✅ Clean up resources: `kubectl delete -f manifests/ --recursive`
2. ✅ Proceed to **security** for advanced security practices
3. ✅ Practice configuration troubleshooting scenarios

---

*Great job! You now know how to manage application configuration securely. Let's move on to advanced security practices!* 🔐