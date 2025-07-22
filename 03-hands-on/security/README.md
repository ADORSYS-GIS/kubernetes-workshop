# Security: Kubernetes Security Best Practices

Master Kubernetes security through Pod Security Standards, RBAC, network policies, and advanced security controls for production environments.

## 🎯 Learning Objectives

By the end of this module, you will be able to:
- Implement Pod Security Standards and security contexts
- Design and implement RBAC policies
- Create network policies for micro-segmentation
- Secure container images and supply chains
- Configure admission controllers and policy engines
- Audit and monitor security events
- Apply defense-in-depth security strategies

## 📚 Prerequisites

- ✅ Completed **deploying-apps**, **services-ingress**, and **configmaps-secrets** modules
- ✅ Understanding of Linux security concepts (users, groups, capabilities)
- ✅ Basic knowledge of networking and firewalls
- ✅ Familiarity with PKI and certificate concepts (helpful)

## 🗂️ Module Structure

```
security/
├── README.md           # Complete security guide
├── manifests/          # Security configurations
│   ├── pod-security-standards.yaml    # PSS examples
│   ├── rbac-examples.yaml             # RBAC policies
│   ├── network-policies.yaml          # Network segmentation
│   ├── security-policies.yaml         # Admission controllers
│   ├── image-security.yaml            # Image scanning and policies
│   └── service-mesh-security.yaml     # mTLS and service mesh
├── scripts/            # Security validation and testing
└── solutions/          # Reference security implementations
```

## 🛡️ Kubernetes Security Model

### Defense in Depth Layers

```
┌─────────────────────────────────────────────────────────┐
│                    1. Cluster Security                   │
│  ┌─────────────────────────────────────────────────────┐ │
│  │              2. Network Security                    │ │
│  │  ┌─────────────────────────────────────────────────┐│ │
│  │  │             3. Pod Security                     ││ │
│  │  │  ┌─────────────────────────────────────────────┐││ │
│  │  │  │           4. Container Security             │││ │
│  │  │  │  ┌─────────────────────────────────────────┐│││ │
│  │  │  │  │         5. Application Security         ││││ │
│  │  │  │  └─────────────────────────────────────────┘│││ │
│  │  │  └─────────────────────────────────────────────┘││ │
│  │  └─────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Security Domains

| Domain | Focus | Tools/Concepts |
|--------|--------|---------------|
| **Authentication** | Who can access | OIDC, certificates, tokens |
| **Authorization** | What can be accessed | RBAC, ABAC, webhooks |
| **Admission Control** | What can be created | PSA, OPA, ValidatingAdmissionWebhooks |
| **Network Security** | How communication flows | Network Policies, Service Mesh |
| **Runtime Security** | What happens during execution | Security Contexts, AppArmor, SELinux |

## 🚀 Lab Exercises

### Lab 1: Pod Security Standards (25 minutes)

**Objective**: Implement comprehensive pod-level security controls.

#### Step 1: Understanding Pod Security Standards
```bash
# Navigate to security module
cd 03-hands-on/security

# Create namespace with Pod Security Standards
cat > manifests/pod-security-namespaces.yaml << 'EOF'
# Privileged namespace (least restrictive)
apiVersion: v1
kind: Namespace
metadata:
  name: privileged-workloads
  labels:
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/audit: privileged
    pod-security.kubernetes.io/warn: privileged
---
# Baseline namespace (some restrictions)
apiVersion: v1
kind: Namespace
metadata:
  name: baseline-workloads
  labels:
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/audit: baseline
    pod-security.kubernetes.io/warn: baseline
---
# Restricted namespace (most secure)
apiVersion: v1
kind: Namespace
metadata:
  name: restricted-workloads
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
EOF

kubectl apply -f manifests/pod-security-namespaces.yaml
```

#### Step 2: Test Pod Security Standards
```bash
cat > manifests/pod-security-standards.yaml << 'EOF'
# This pod violates baseline security (will be rejected in baseline/restricted namespaces)
apiVersion: v1
kind: Pod
metadata:
  name: insecure-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    securityContext:
      privileged: true  # Violates baseline
      runAsUser: 0      # Violates restricted
---
# This pod meets baseline security
apiVersion: v1
kind: Pod
metadata:
  name: baseline-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    securityContext:
      runAsUser: 0      # Still violates restricted
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
---
# This pod meets restricted security (most secure)
apiVersion: v1
kind: Pod
metadata:
  name: restricted-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 65534
    runAsGroup: 65534
    fsGroup: 65534
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    securityContext:
      runAsNonRoot: true
      runAsUser: 65534
      runAsGroup: 65534
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
    volumeMounts:
    - name: tmp-volume
      mountPath: /tmp
    - name: var-cache
      mountPath: /var/cache/nginx
    - name: var-run
      mountPath: /var/run
  volumes:
  - name: tmp-volume
    emptyDir: {}
  - name: var-cache
    emptyDir: {}
  - name: var-run
    emptyDir: {}
EOF

# Test in privileged namespace (should all work)
kubectl apply -f manifests/pod-security-standards.yaml -n privileged-workloads

# Test in baseline namespace (insecure-pod should be rejected)
kubectl apply -f manifests/pod-security-standards.yaml -n baseline-workloads

# Test in restricted namespace (only restricted-pod should work)
kubectl apply -f manifests/pod-security-standards.yaml -n restricted-workloads

# Check what was created/rejected
kubectl get pods -n privileged-workloads
kubectl get pods -n baseline-workloads
kubectl get pods -n restricted-workloads
```

### Lab 2: Role-Based Access Control (RBAC) (30 minutes)

**Objective**: Design granular access control with RBAC.

#### Step 1: Create Service Accounts and Roles
```bash
cat > manifests/rbac-examples.yaml << 'EOF'
# Service Accounts for different roles
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pod-reader
  namespace: default
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: deployment-manager
  namespace: default
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cluster-admin-limited
  namespace: default
---
# Role for reading pods only
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader-role
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
---
# Role for managing deployments
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: deployment-manager-role
rules:
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get", "list", "watch"]
---
# ClusterRole for limited cluster admin tasks
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-admin-limited-role
rules:
- apiGroups: [""]
  resources: ["nodes", "namespaces"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["persistentvolumes"]
  verbs: ["get", "list", "watch", "create", "delete"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses"]
  verbs: ["get", "list", "watch"]
---
# RoleBindings
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: default
subjects:
- kind: ServiceAccount
  name: pod-reader
  namespace: default
roleRef:
  kind: Role
  name: pod-reader-role
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deployment-manager-binding
  namespace: default
subjects:
- kind: ServiceAccount
  name: deployment-manager
  namespace: default
roleRef:
  kind: Role
  name: deployment-manager-role
  apiGroup: rbac.authorization.k8s.io
---
# ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-admin-limited-binding
subjects:
- kind: ServiceAccount
  name: cluster-admin-limited
  namespace: default
roleRef:
  kind: ClusterRole
  name: cluster-admin-limited-role
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f manifests/rbac-examples.yaml
```

#### Step 2: Test RBAC Permissions
```bash
# Test pod-reader permissions
kubectl auth can-i get pods --as=system:serviceaccount:default:pod-reader
kubectl auth can-i create deployments --as=system:serviceaccount:default:pod-reader
kubectl auth can-i delete pods --as=system:serviceaccount:default:pod-reader

# Test deployment-manager permissions  
kubectl auth can-i create deployments --as=system:serviceaccount:default:deployment-manager
kubectl auth can-i get nodes --as=system:serviceaccount:default:deployment-manager
kubectl auth can-i delete namespaces --as=system:serviceaccount:default:deployment-manager

# Test cluster-admin-limited permissions
kubectl auth can-i get nodes --as=system:serviceaccount:default:cluster-admin-limited
kubectl auth can-i create persistentvolumes --as=system:serviceaccount:default:cluster-admin-limited
kubectl auth can-i delete deployments --as=system:serviceaccount:default:cluster-admin-limited
```

#### Step 3: Deploy Pods with Service Accounts
```bash
cat > manifests/rbac-pod-test.yaml << 'EOF'
# Pod using pod-reader service account
apiVersion: v1
kind: Pod
metadata:
  name: pod-reader-test
spec:
  serviceAccountName: pod-reader
  containers:
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["/bin/sh", "-c"]
    args:
    - |
      echo "Testing pod-reader permissions..."
      kubectl get pods || echo "❌ Cannot get pods"
      kubectl get deployments || echo "❌ Cannot get deployments (expected)"
      kubectl create deployment test --image=nginx || echo "❌ Cannot create deployments (expected)"
      sleep 3600
  securityContext:
    runAsNonRoot: true
    runAsUser: 65534
---
# Pod using deployment-manager service account
apiVersion: v1
kind: Pod
metadata:
  name: deployment-manager-test
spec:
  serviceAccountName: deployment-manager
  containers:
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["/bin/sh", "-c"]
    args:
    - |
      echo "Testing deployment-manager permissions..."
      kubectl get pods || echo "❌ Cannot get pods"
      kubectl get deployments || echo "❌ Cannot get deployments"
      kubectl create deployment rbac-test --image=nginx:1.25-alpine --replicas=2 || echo "❌ Cannot create deployments"
      sleep 3600
  securityContext:
    runAsNonRoot: true
    runAsUser: 65534
EOF

kubectl apply -f manifests/rbac-pod-test.yaml

# Watch the logs to see permission tests
kubectl logs pod-reader-test
kubectl logs deployment-manager-test
```

### Lab 3: Network Policies (25 minutes)

**Objective**: Implement network segmentation and micro-segmentation.

#### Step 1: Create Multi-Tier Application
```bash
cat > manifests/network-policy-demo.yaml << 'EOF'
# Create namespaces for different environments
apiVersion: v1
kind: Namespace
metadata:
  name: frontend
  labels:
    tier: frontend
---
apiVersion: v1
kind: Namespace
metadata:
  name: backend
  labels:
    tier: backend
---
apiVersion: v1
kind: Namespace
metadata:
  name: database
  labels:
    tier: database
---
# Frontend deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-app
  namespace: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 8080
---
# Backend deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app
  namespace: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
        tier: backend
    spec:
      containers:
      - name: app
        image: nginx:1.25-alpine
        ports:
        - containerPort: 8080
---
# Database deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
        tier: database
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_PASSWORD
          value: "password"
        ports:
        - containerPort: 5432
---
# Services
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: frontend
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: backend
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: database-service
  namespace: database
spec:
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
EOF

kubectl apply -f manifests/network-policy-demo.yaml
```

#### Step 2: Implement Network Policies
```bash
cat > manifests/network-policies.yaml << 'EOF'
# Default deny all ingress traffic in database namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-default-deny
  namespace: database
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
# Allow backend to access database
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-allow-backend
  namespace: database
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5432
---
# Backend network policy - allow from frontend, allow to database
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
  # Allow DNS
  - to: []
    ports:
    - protocol: UDP
      port: 53
---
# Frontend network policy - allow from ingress, allow to backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
  namespace: frontend
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 80
  # Allow DNS
  - to: []
    ports:
    - protocol: UDP
      port: 53
EOF

kubectl apply -f manifests/network-policies.yaml
```

#### Step 3: Test Network Connectivity
```bash
# Test allowed connection: frontend to backend
kubectl exec -n frontend deployment/frontend-app -- wget -qO- http://backend-service.backend.svc.cluster.local --timeout=5

# Test allowed connection: backend to database
kubectl exec -n backend deployment/backend-app -- nc -zv database-service.database.svc.cluster.local 5432

# Test blocked connection: frontend to database (should fail)
kubectl exec -n frontend deployment/frontend-app -- nc -zv database-service.database.svc.cluster.local 5432 --timeout=5 || echo "❌ Connection blocked (expected)"

# Test from outside namespaces
kubectl run test-pod --image=busybox:1.35 --rm -it --restart=Never -- nc -zv database-service.database.svc.cluster.local 5432 || echo "❌ Connection blocked (expected)"
```

### Lab 4: Image Security and Supply Chain (20 minutes)

**Objective**: Secure container images and supply chain.

#### Step 1: Image Policy with Admission Controllers
```bash
cat > manifests/image-security.yaml << 'EOF'
# Example ValidatingAdmissionWebhook configuration
# Note: This is a simplified example - real implementation requires webhook server
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionWebhook
metadata:
  name: image-policy-webhook
rules:
- operations: ["CREATE", "UPDATE"]
  apiGroups: [""]
  apiVersions: ["v1"]
  resources: ["pods"]
- operations: ["CREATE", "UPDATE"]
  apiGroups: ["apps"]
  apiVersions: ["v1"]
  resources: ["deployments", "replicasets", "daemonsets", "statefulsets"]
webhookConfig:
  service:
    name: image-policy-service
    namespace: security-system
    path: "/validate-image"
  admissionReviewVersions: ["v1", "v1beta1"]
---
# Pod Security Policy alternative using OPA Gatekeeper constraint template
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredsecureimages
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredSecureImages
      validation:
        type: object
        properties:
          allowedRepos:
            type: array
            items:
              type: string
          deniedTags:
            type: array
            items:
              type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredsecureimages
        
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not starts_with(container.image, input.parameters.allowedRepos[_])
          msg := sprintf("Image '%v' is not from an allowed repository", [container.image])
        }
        
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          ends_with(container.image, input.parameters.deniedTags[_])
          msg := sprintf("Image '%v' uses a denied tag", [container.image])
        }
---
# Constraint using the template
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredSecureImages
metadata:
  name: must-use-secure-images
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
      - apiGroups: ["apps"]
        kinds: ["Deployment"]
  parameters:
    allowedRepos:
      - "nginx"
      - "alpine"
      - "postgres"
      - "redis"
    deniedTags:
      - ":latest"
      - ":dev"
      - ":test"
EOF

# Note: This requires OPA Gatekeeper to be installed
# kubectl apply -f manifests/image-security.yaml
```

#### Step 2: Image Scanning Integration
```bash
# Example of secure image deployment with scanning results
cat > manifests/secure-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  annotations:
    # Image scan results (example annotations)
    security.scan/last-scan: "2024-01-15T10:30:00Z"
    security.scan/vulnerabilities: "0 critical, 2 medium, 5 low"
    security.scan/scanner: "trivy"
    security.scan/image-digest: "sha256:abcd1234..."
spec:
  replicas: 2
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 65534
        fsGroup: 65534
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: app
        # Use specific digest instead of tag for immutability
        image: nginx:1.25-alpine@sha256:2d194b87c1e5b0f3c30b2d3c5b4f8a3c7d8e9f0a1b2c3d4e5f6789abcdef012
        securityContext:
          runAsNonRoot: true
          runAsUser: 65534
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: var-cache
          mountPath: /var/cache/nginx
        - name: var-run
          mountPath: /var/run
      volumes:
      - name: tmp
        emptyDir: {}
      - name: var-cache
        emptyDir: {}
      - name: var-run
        emptyDir: {}
EOF

kubectl apply -f manifests/secure-deployment.yaml
```

## 📋 Validation and Testing

### Module Validation Commands
```bash
# Run comprehensive security validation
./scripts/validate-security.sh

# Manual security checks:
# Check Pod Security Standards
kubectl get pods -n restricted-workloads
kubectl describe pod restricted-pod -n restricted-workloads

# Test RBAC
kubectl auth can-i get pods --as=system:serviceaccount:default:pod-reader

# Test Network Policies
kubectl exec -n frontend deployment/frontend-app -- nc -zv database-service.database.svc.cluster.local 5432
```

### Success Criteria
✅ **Pod Security**:
- Can implement Pod Security Standards
- Understand security contexts and their impact
- Can troubleshoot security-related pod failures

✅ **Access Control**:
- Can design granular RBAC policies
- Understand principle of least privilege
- Can test and validate permissions

✅ **Network Security**:
- Can implement network segmentation
- Understand ingress and egress controls
- Can troubleshoot network connectivity issues

## 🔧 Troubleshooting Guide

### Pod Security Issues
```bash
# Pod rejected due to security policy
kubectl describe pod <pod-name>
kubectl get events --sort-by=.metadata.creationTimestamp

# Check security context
kubectl get pod <pod-name> -o yaml | grep -A 20 securityContext
```

### RBAC Issues
```bash
# Permission denied errors
kubectl auth can-i <verb> <resource> --as=<user>
kubectl describe clusterrole <role-name>
kubectl describe rolebinding <binding-name>
```

### Network Policy Issues
```bash
# Connection blocked unexpectedly
kubectl describe networkpolicy -n <namespace>
kubectl exec <pod> -- nc -zv <service> <port>

# Check DNS resolution
kubectl exec <pod> -- nslookup <service>
```

## 🎯 Advanced Challenges

### Challenge 1: Multi-Tenant Security
Design security model for multi-tenant SaaS application.

### Challenge 2: Compliance Automation
Implement automated compliance checking with OPA Gatekeeper.

### Challenge 3: Zero-Trust Network
Design zero-trust network architecture with service mesh.

## ⏭️ Next Steps

After completing this module:
1. ✅ Clean up resources: `kubectl delete -f manifests/ --recursive`
2. ✅ Proceed to **monitoring** for observability
3. ✅ Practice security incident response

---

*Congratulations! You now have the skills to secure Kubernetes environments using industry best practices. Security is a journey, not a destination!* 🛡️