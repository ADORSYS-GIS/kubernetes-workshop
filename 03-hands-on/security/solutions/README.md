# Security Solutions

This directory contains reference implementations for comprehensive Kubernetes security using defense-in-depth strategies.

## 📁 Contents

### `complete-security-solution.yaml`
A production-hardened implementation demonstrating:
- **Pod Security Standards**: Restricted PSS compliance with comprehensive security contexts
- **RBAC**: Least-privilege service accounts, roles, and bindings
- **Network Policies**: Zero-trust network segmentation with default-deny policies
- **Image Security**: Digest-pinned images, minimal attack surface
- **Secret Management**: Secure secret handling with proper file permissions
- **Container Hardening**: Non-root execution, read-only filesystems, dropped capabilities

## 🛡️ Security Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  DEFENSE IN DEPTH                       │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │
│  │  CLUSTER    │  │   NETWORK   │  │      POD        │  │
│  │  SECURITY   │  │  SECURITY   │  │   SECURITY      │  │
│  │             │  │             │  │                 │  │
│  │ • PSS       │  │ • NetPol    │  │ • SecCtx       │  │
│  │ • RBAC      │  │ • Zero-trust│  │ • Non-root     │  │
│  │ • AdmCtl    │  │ • Micro-seg │  │ • ReadOnlyFS   │  │
│  └─────────────┘  └─────────────┘  └─────────────────┘  │
│         │                 │                   │         │
│         └─────────────────┼───────────────────┘         │
│                           │                             │
│                    COMPREHENSIVE                        │
│                     MONITORING                          │
└─────────────────────────────────────────────────────────┘
```

## 🔒 Key Security Features

### 1. Pod Security Standards (PSS)
```yaml
# Namespace with restricted PSS
metadata:
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted

# Compliant security context
securityContext:
  runAsNonRoot: true
  runAsUser: 65534
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop: [ALL]
  seccompProfile:
    type: RuntimeDefault
```

### 2. RBAC Best Practices
```yaml
# Least-privilege service account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: secure-app-sa
automountServiceAccountToken: false  # Explicit control

# Minimal role permissions
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list"]
  resourceNames: ["app-config", "app-secret"]  # Specific resources only
```

### 3. Network Policies (Zero-Trust)
```yaml
# Default deny-all traffic
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  # No rules = deny all

# Explicit allow rules only
ingress:
- from:
  - podSelector:
      matchLabels:
        app: allowed-app
  ports:
  - protocol: TCP
    port: 8080
```

### 4. Image Security
```yaml
# Digest-pinned images (immutable)
image: nginx:1.25-alpine@sha256:2d194b87c1e5b0f3c30b2d3c5b4f8a3c7d8e9f0a1b2c3d4e5f6789abcdef012

# Security annotations
annotations:
  security.kubernetes.io/scan-date: "2024-01-15"
  security.kubernetes.io/vulnerabilities: "0 critical, 2 medium"
```

## 🚀 Deployment Guide

### 1. Apply Security Solution
```bash
# Deploy the complete security solution
kubectl apply -f complete-security-solution.yaml

# Verify namespace security labels
kubectl describe namespace secure-production

# Check RBAC
kubectl get serviceaccounts,roles,rolebindings -n secure-production
```

### 2. Validate Security Posture
```bash
# Test Pod Security Standards
kubectl run test-pod --image=nginx --restart=Never -n secure-production
# Should fail due to restricted PSS

# Test RBAC permissions
kubectl auth can-i get secrets --as=system:serviceaccount:secure-production:secure-app-sa -n secure-production

# Test network policies
kubectl exec -n secure-production deployment/secure-app -- curl http://external-service
# Should fail due to network policies
```

### 3. Security Validation
```bash
# Run security validation script
./scripts/validate-security.sh

# Check pod security context
kubectl get pod -n secure-production -o yaml | grep -A 20 securityContext

# Verify network policies
kubectl describe networkpolicy -n secure-production
```

## 🔧 Security Checklist

### Pod Security ✅
- [ ] Non-root user execution (`runAsNonRoot: true`)
- [ ] Read-only root filesystem (`readOnlyRootFilesystem: true`)
- [ ] Privilege escalation disabled (`allowPrivilegeEscalation: false`)
- [ ] All capabilities dropped (`capabilities: drop: [ALL]`)
- [ ] Seccomp profile applied (`seccompProfile: type: RuntimeDefault`)
- [ ] Resource limits defined
- [ ] Health checks implemented

### RBAC Security ✅
- [ ] Dedicated service accounts (no default SA)
- [ ] Service account token mounting disabled
- [ ] Least-privilege roles (minimal permissions)
- [ ] Resource-specific permissions (resourceNames)
- [ ] Namespace isolation
- [ ] Regular permission audits

### Network Security ✅
- [ ] Default-deny network policies
- [ ] Explicit ingress rules only
- [ ] Explicit egress rules only
- [ ] DNS resolution allowed
- [ ] External traffic controlled
- [ ] Namespace segmentation
- [ ] Pod-to-pod communication restrictions

### Image Security ✅
- [ ] Digest-pinned images (immutable)
- [ ] Vulnerability scanning
- [ ] Minimal/distroless base images
- [ ] No latest tags
- [ ] Image signature verification
- [ ] Registry security scanning
- [ ] Supply chain security

### Secret Management ✅
- [ ] Secrets mounted as files (not env vars)
- [ ] Restrictive file permissions (0400)
- [ ] Proper secret types
- [ ] Secret rotation strategy
- [ ] No hardcoded secrets
- [ ] Encryption at rest
- [ ] Access logging

## 🔍 Security Monitoring

### Runtime Security
```bash
# Monitor security events
kubectl get events --sort-by=.metadata.creationTimestamp -n secure-production

# Check for security violations
kubectl logs -n secure-production deployment/secure-app | grep -i security

# Monitor network traffic
kubectl exec -n secure-production deployment/secure-app -- netstat -tuln
```

### Compliance Scanning
```bash
# Pod Security Standards violations
kubectl get pods -A -o json | jq '.items[] | select(.metadata.annotations["pod-security.kubernetes.io/enforce-policy"] == "restricted")'

# RBAC audit
kubectl auth can-i --list --as=system:serviceaccount:secure-production:secure-app-sa

# Network policy testing
kubectl run network-test --image=busybox --restart=Never -n secure-production -- sleep 3600
kubectl exec network-test -- nc -zv database-service 5432
```

## 🎯 Common Security Vulnerabilities

### ❌ Avoid These Patterns

1. **Running as Root**
```yaml
# WRONG - runs as root
securityContext:
  runAsUser: 0  # root user
```

2. **Privileged Containers**
```yaml
# WRONG - privileged mode
securityContext:
  privileged: true  # gives all capabilities
```

3. **Secrets in Environment Variables**
```yaml
# WRONG - secrets visible in process list
env:
- name: PASSWORD
  value: "plain-text-password"
```

4. **Open Network Policies**
```yaml
# WRONG - allows all traffic
spec:
  podSelector: {}
  ingress:
  - {}  # allows all ingress
```

5. **Latest Image Tags**
```yaml
# WRONG - mutable, unpredictable
image: nginx:latest  # could change at any time
```

### ✅ Secure Alternatives

1. **Non-Root Execution**
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 65534
```

2. **Dropped Capabilities**
```yaml
securityContext:
  capabilities:
    drop: [ALL]
```

3. **File-Based Secrets**
```yaml
volumeMounts:
- name: secrets
  mountPath: /etc/secrets
  readOnly: true
```

4. **Explicit Network Rules**
```yaml
ingress:
- from:
  - podSelector:
      matchLabels:
        app: allowed-source
```

5. **Digest-Pinned Images**
```yaml
image: nginx:1.25-alpine@sha256:abc123...
```

## 📚 Security Resources

- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [RBAC Good Practices](https://kubernetes.io/docs/concepts/security/rbac-good-practices/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)

## 🛡️ Advanced Security

For production environments, consider:
- **OPA Gatekeeper** for policy enforcement
- **Falco** for runtime security monitoring  
- **Service Mesh** (Istio/Linkerd) for mTLS
- **Image signing** with Cosign/Notary
- **Vulnerability scanning** in CI/CD
- **Secret management** with Vault/External Secrets

---

*Security is not a destination, it's a journey. Continuously monitor, audit, and improve your security posture!* 🛡️