# Services and Ingress: Kubernetes Networking

Master Kubernetes networking concepts including Services, Ingress controllers, and traffic management for production applications.

## 🎯 Learning Objectives

By the end of this module, you will be able to:
- Create and manage different types of Services
- Understand Service discovery and DNS resolution
- Configure Ingress controllers for HTTP routing
- Implement load balancing strategies
- Secure ingress traffic with TLS/SSL
- Apply network policies for micro-segmentation
- Troubleshoot networking issues

## 📚 Prerequisites

- ✅ Completed **deploying-apps** module
- ✅ Working Kubernetes cluster with Ingress support
- ✅ Understanding of basic networking concepts (TCP/IP, DNS, HTTP)
- ✅ Familiarity with TLS/SSL certificates (helpful but not required)

## 🗂️ Module Structure

```
services-ingress/
├── README.md           # Complete learning guide
├── manifests/          # YAML configurations
│   ├── nginx-service.yaml          # Basic service
│   ├── service-types-demo.yaml     # All service types
│   ├── ingress-basic.yaml          # Basic ingress
│   ├── ingress-tls.yaml            # TLS/SSL ingress
│   ├── network-policy.yaml         # Network isolation
│   └── load-balancer-demo.yaml     # Load balancing
├── scripts/            # Helper and validation scripts
└── solutions/          # Reference implementations
```

## 🌐 Understanding Kubernetes Services

### Service Types Overview

| Type | Use Case | Access Method | External Access |
|------|----------|---------------|-----------------|
| **ClusterIP** | Internal communication | DNS name | No |
| **NodePort** | Development/Testing | Node IP:Port | Yes |
| **LoadBalancer** | Production external access | Cloud LB IP | Yes |
| **ExternalName** | External service proxy | DNS CNAME | No |

## 🚀 Lab Exercises

### Lab 1: Basic Service Types (20 minutes)

**Objective**: Understand how different Service types expose applications.

#### Step 1: Prepare Applications
```bash
# Navigate to module directory
cd 03-hands-on/services-ingress

# Ensure we have a deployment to work with
kubectl apply -f ../deploying-apps/manifests/nginx-deployment.yaml

# Wait for deployment to be ready
kubectl rollout status deployment/nginx-deployment
```

#### Step 2: ClusterIP Service (Internal Only)
```bash
# Create a basic ClusterIP service
cat > manifests/service-clusterip.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: nginx-clusterip
  labels:
    app: nginx
    service-type: clusterip
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
EOF

kubectl apply -f manifests/service-clusterip.yaml

# Test internal connectivity
kubectl run test-pod --image=busybox:1.35 --rm -it --restart=Never -- sh

# Inside test pod:
wget -qO- http://nginx-clusterip
nslookup nginx-clusterip
exit
```

#### Step 3: NodePort Service (External Access)
```bash
# Create NodePort service
cat > manifests/service-nodeport.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
  labels:
    app: nginx
    service-type: nodeport
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
    protocol: TCP
    name: http
EOF

kubectl apply -f manifests/service-nodeport.yaml

# Get service details
kubectl get service nginx-nodeport

# Test external access (if using minikube)
minikube service nginx-nodeport --url
# Or access via: http://<node-ip>:30080
```

#### Step 4: LoadBalancer Service (Cloud Provider)
```bash
# Apply LoadBalancer service (works with cloud providers)
kubectl apply -f manifests/nginx-service.yaml

# Watch for external IP assignment (may take a few minutes)
kubectl get service nginx-service -w

# For minikube, use tunnel to simulate LoadBalancer
# In separate terminal: minikube tunnel
```

### Lab 2: Service Discovery and DNS (15 minutes)

**Objective**: Understand how Kubernetes DNS enables service discovery.

#### Step 1: Explore DNS Resolution
```bash
# Create a multi-service environment
cat > manifests/multi-app-demo.yaml << 'EOF'
# Frontend application
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 8080
---
# Backend application
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8080
EOF

kubectl apply -f manifests/multi-app-demo.yaml
```

#### Step 2: Test DNS Resolution
```bash
# Create a debug pod for testing
kubectl run dns-test --image=busybox:1.35 --rm -it --restart=Never -- sh

# Inside the pod, test different DNS formats:
nslookup frontend-service
nslookup frontend-service.default
nslookup frontend-service.default.svc.cluster.local
nslookup backend-service

# Test connectivity
wget -qO- http://frontend-service
wget -qO- http://backend-service

exit
```

#### Step 3: Examine Service Endpoints
```bash
# Check service endpoints
kubectl get endpoints

# Detailed endpoint information
kubectl describe endpoints frontend-service
kubectl describe endpoints backend-service

# See how endpoints map to pods
kubectl get pods -l app=frontend -o wide
kubectl get pods -l app=backend -o wide
```

### Lab 3: Ingress Controllers (30 minutes)

**Objective**: Configure HTTP routing and load balancing with Ingress.

#### Step 1: Enable Ingress (minikube)
```bash
# Enable ingress addon
minikube addons enable ingress

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s
```

#### Step 2: Create Basic Ingress
```bash
cat > manifests/ingress-basic.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /frontend
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /backend
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80
  - host: admin.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80
EOF

kubectl apply -f manifests/ingress-basic.yaml
```

#### Step 3: Test Ingress Routing
```bash
# Get ingress details
kubectl get ingress web-ingress

# Get ingress IP (may take a moment)
kubectl get ingress web-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# For minikube, get ingress IP
minikube ip

# Add entries to /etc/hosts (adjust IP as needed)
echo "$(minikube ip) myapp.local admin.local" | sudo tee -a /etc/hosts

# Test routing
curl http://myapp.local/frontend
curl http://myapp.local/backend
curl http://admin.local/
```

### Lab 4: TLS/SSL with Ingress (20 minutes)

**Objective**: Secure HTTP traffic with TLS certificates.

#### Step 1: Create Self-Signed Certificate
```bash
# Generate self-signed certificate for demo
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=myapp.local/O=myapp.local" \
  -addext "subjectAltName = DNS:myapp.local,DNS:admin.local"

# Create Kubernetes secret
kubectl create secret tls myapp-tls --key=tls.key --cert=tls.crt

# Clean up certificate files
rm tls.key tls.crt
```

#### Step 2: Configure TLS Ingress
```bash
cat > manifests/ingress-tls.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress-tls
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.local
    - admin.local
    secretName: myapp-tls
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /frontend
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /backend
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80
  - host: admin.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80
EOF

kubectl apply -f manifests/ingress-tls.yaml
```

#### Step 3: Test TLS
```bash
# Test HTTPS (ignore certificate warnings for self-signed cert)
curl -k https://myapp.local/frontend
curl -k https://admin.local/

# Test HTTP redirect to HTTPS
curl -I http://myapp.local/frontend
```

### Lab 5: Network Policies (25 minutes)

**Objective**: Implement network segmentation for security.

#### Step 1: Create Namespaces for Isolation
```bash
# Create different environments
kubectl create namespace production
kubectl create namespace development
kubectl create namespace monitoring

# Label namespaces
kubectl label namespace production env=prod
kubectl label namespace development env=dev
kubectl label namespace monitoring env=monitor
```

#### Step 2: Deploy Apps in Different Namespaces
```bash
# Deploy to production
kubectl apply -f manifests/multi-app-demo.yaml -n production

# Deploy to development
kubectl apply -f manifests/multi-app-demo.yaml -n development

# Create a monitoring service
cat > manifests/monitoring-app.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
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
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus-service
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090
EOF

kubectl apply -f manifests/monitoring-app.yaml -n monitoring
```

#### Step 3: Apply Network Policies
```bash
cat > manifests/network-policies.yaml << 'EOF'
# Deny all ingress traffic to production by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: production-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
# Allow specific ingress to production frontend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: production-frontend-ingress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          env: monitor
    ports:
    - protocol: TCP
      port: 8080
  - from: []  # Allow ingress controller
    ports:
    - protocol: TCP
      port: 8080
---
# Allow production frontend to call backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: production-backend-ingress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
---
# Allow monitoring to access production
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: monitoring-egress
  namespace: monitoring
spec:
  podSelector:
    matchLabels:
      app: prometheus
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          env: prod
    ports:
    - protocol: TCP
      port: 8080
  - to: []  # Allow DNS
    ports:
    - protocol: UDP
      port: 53
EOF

kubectl apply -f manifests/network-policies.yaml
```

#### Step 4: Test Network Isolation
```bash
# Test connectivity from monitoring to production (should work)
kubectl exec -n monitoring deployment/prometheus -- wget -qO- http://frontend-service.production.svc.cluster.local --timeout=5

# Test connectivity from development to production (should fail)
kubectl run test-dev --image=busybox:1.35 --rm -it --restart=Never -n development -- sh
# Inside pod: wget -qO- http://frontend-service.production.svc.cluster.local --timeout=5
# Should timeout due to network policy
```

## 📋 Validation and Testing

### Module Validation Commands
```bash
# Run comprehensive validation
./scripts/validate-services-ingress.sh

# Or test individual components:

# Test service discovery
kubectl run dns-test --image=busybox:1.35 --rm -it --restart=Never -- nslookup frontend-service

# Test ingress
curl -H "Host: myapp.local" http://$(minikube ip)/frontend

# Test network policies
kubectl exec -n monitoring deployment/prometheus -- wget -qO- http://frontend-service.production.svc.cluster.local --timeout=5
```

### Success Criteria
✅ **Service Management**:
- Can create different types of services
- Understand service discovery via DNS
- Can troubleshoot service connectivity issues

✅ **Ingress Configuration**:
- Can configure HTTP routing rules
- Understand host-based and path-based routing
- Can secure traffic with TLS certificates

✅ **Network Security**:
- Can implement network policies
- Understand namespace isolation
- Can troubleshoot network connectivity issues

## 🔧 Troubleshooting Guide

### Service Issues
```bash
# Service not accessible
kubectl describe service <service-name>
kubectl get endpoints <service-name>

# Check if pods are running and labeled correctly
kubectl get pods -l <selector>
```

### Ingress Issues
```bash
# Ingress not working
kubectl describe ingress <ingress-name>
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Check ingress controller status
kubectl get pods -n ingress-nginx
```

### Network Policy Issues
```bash
# Test connectivity
kubectl exec <pod> -- nc -zv <service> <port>

# Check network policies
kubectl get networkpolicies -A
kubectl describe networkpolicy <policy-name>
```

## 🎯 Advanced Challenges

### Challenge 1: Advanced Load Balancing
Configure session affinity and custom load balancing algorithms.

### Challenge 2: Multi-Domain Ingress
Set up ingress for multiple domains with different TLS certificates.

### Challenge 3: Network Policy Matrix
Create a complex network policy setup with multiple tiers.

## ⏭️ Next Steps

After completing this module:
1. ✅ Clean up resources: `kubectl delete -f manifests/ --recursive`
2. ✅ Proceed to **configmaps-secrets** for configuration management
3. ✅ Practice troubleshooting networking issues

---

*Excellent work! You now understand how to expose and secure applications in Kubernetes. Next, let's learn about configuration management!* 🌐