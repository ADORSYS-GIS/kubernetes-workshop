# Security Best Practices for Kubernetes Labs

This document outlines the security improvements and best practices implemented in this educational lab environment.

## 🔒 Security Enhancements Applied

### 1. Container Image Security
- **Before**: `nginx:latest` (mutable, unpredictable)
- **After**: `nginx:1.25-alpine` (immutable, specific version)
- **Benefit**: Ensures reproducible builds and reduces supply chain risks

### 2. Non-Root Container Execution
- **Implementation**: All containers run as user ID 65534 (nobody)
- **Security Context**:
  ```yaml
  securityContext:
    runAsNonRoot: true
    runAsUser: 65534
    readOnlyRootFilesystem: true
    allowPrivilegeEscalation: false
  ```
- **Benefit**: Reduces attack surface if container is compromised

### 3. Resource Limits and Requests
- **CPU Limits**: Prevents CPU exhaustion attacks
- **Memory Limits**: Prevents memory exhaustion attacks
- **Example**:
  ```yaml
  resources:
    requests:
      memory: "64Mi"
      cpu: "250m"
    limits:
      memory: "128Mi"
      cpu: "500m"
  ```

### 4. Read-Only Root Filesystem
- **Implementation**: `readOnlyRootFilesystem: true`
- **Writable Volumes**: Only `/tmp`, `/var/cache`, `/var/run` as emptyDir
- **Benefit**: Prevents malicious file modifications

### 5. Capability Dropping
- **Implementation**: Drop ALL capabilities
- **Configuration**: `capabilities: { drop: [ALL] }`
- **Benefit**: Minimizes container privileges

## 🚨 Security Considerations for Production

### Network Security
- **Network Policies**: Implemented in `namespace-example.yaml`
- **Namespace Isolation**: Separate production/development environments
- **Service Mesh**: Consider Istio/Linkerd for advanced traffic management

### Secrets Management
- Never embed secrets in container images
- Use Kubernetes Secrets with encryption at rest
- Consider external secret management (HashiCorp Vault, etc.)

### Image Security
```bash
# Scan images for vulnerabilities
docker scout cves nginx:1.25-alpine

# Use minimal base images
# Alpine Linux is used for smaller attack surface
```

### RBAC (Role-Based Access Control)
```yaml
# Example: Least privilege service account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: production
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
```

### Pod Security Standards
- **Restricted Profile**: Most secure, used in examples
- **Baseline Profile**: Minimal restrictions for compatibility
- **Privileged Profile**: Unrestricted (avoid in production)

## 🔍 Security Validation Commands

### Check Security Context
```bash
# Verify non-root execution
kubectl exec nginx-pod -- whoami
# Expected: nobody or numeric UID

# Check running processes
kubectl exec nginx-pod -- ps aux
# Expected: Processes running as non-root user
```

### Validate Resource Limits
```bash
# Check resource allocation
kubectl describe pod nginx-pod | grep -A 10 "Limits"
kubectl top pod nginx-pod
```

### Network Security Testing
```bash
# Test network policies (if applied)
kubectl exec test-pod -- nc -zv nginx-service 80
# Should succeed from same namespace, fail from restricted namespace
```

## 📋 Security Checklist for Labs

### Before Deployment
- [ ] Images use specific tags, not `latest`
- [ ] Resource limits are defined
- [ ] Security contexts are configured
- [ ] No secrets in YAML files
- [ ] Read-only root filesystem where possible

### During Labs
- [ ] Validate non-root execution
- [ ] Check resource consumption
- [ ] Test network isolation
- [ ] Verify access controls

### After Labs
- [ ] Clean up all resources
- [ ] Remove any temporary accounts
- [ ] Clear any cached credentials

## 🎯 Educational Security Points

### Key Concepts to Teach
1. **Defense in Depth**: Multiple security layers
2. **Least Privilege**: Minimal necessary permissions
3. **Immutable Infrastructure**: Read-only containers
4. **Resource Governance**: Prevent resource exhaustion
5. **Network Segmentation**: Isolate workloads

### Common Security Mistakes
- Running containers as root
- Using `latest` tags in production
- No resource limits
- Overly permissive RBAC
- Secrets in environment variables

## 📚 Additional Security Resources

### Documentation
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

### Tools
- **Static Analysis**: kubesec, kube-score, Polaris
- **Runtime Security**: Falco, Twistlock, Aqua
- **Image Scanning**: Docker Scout, Trivy, Grype

### Compliance Frameworks
- **CIS Kubernetes Benchmark**
- **NSA/CISA Kubernetes Hardening Guide**
- **OWASP Kubernetes Security Cheat Sheet**