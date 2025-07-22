# ConfigMaps and Secrets Solutions

This directory contains reference implementations demonstrating best practices for Kubernetes configuration management.

## 📁 Contents

### `complete-configmap-solution.yaml`
A comprehensive production-ready example showing:
- **ConfigMap Best Practices**: Environment-specific configuration, immutable configs, structured data
- **Secret Security**: Proper secret types, file-based secret mounting, minimal permissions
- **Application Integration**: Environment variables, volume mounts, configuration validation
- **Production Patterns**: Multi-environment support, rolling updates, health checks

## 🎯 Key Learning Points

### ConfigMap Patterns
```yaml
# ✅ Good: Structured configuration
data:
  app_name: "my-app"
  config.yaml: |
    database:
      host: postgres.svc.cluster.local
      port: 5432
    features:
      new_ui: true

# ❌ Avoid: Single large config blob
data:
  config: "app=myapp,db=postgres,port=5432,..."
```

### Secret Security
```yaml
# ✅ Good: File-based secrets with proper permissions
volumeMounts:
- name: app-secrets
  mountPath: /etc/secrets
  readOnly: true
volumes:
- name: app-secrets
  secret:
    secretName: app-secret
    defaultMode: 0400  # Read-only for owner only

# ❌ Avoid: Secrets in environment variables (visible in process list)
env:
- name: PASSWORD
  value: "plain-text-password"  # Never do this!
```

### Environment-Specific Configuration
```yaml
# Development
apiVersion: v1
kind: ConfigMap
metadata:
  name: dev-config
data:
  debug: "true"
  log_level: "debug"
  
# Production  
apiVersion: v1
kind: ConfigMap
metadata:
  name: prod-config
data:
  debug: "false"
  log_level: "warn"
```

## 🔒 Security Best Practices

1. **Secret Types**: Use appropriate secret types (`Opaque`, `kubernetes.io/tls`, etc.)
2. **File Permissions**: Set restrictive permissions (0400, 0600) for secret files
3. **Environment Variables**: Use `secretKeyRef` instead of plain values
4. **Immutable Configs**: Use `immutable: true` for static configuration
5. **Least Privilege**: Only mount secrets where needed

## 🚀 Usage Examples

### Deploy Complete Solution
```bash
# Apply the production-ready configuration
kubectl apply -f complete-configmap-solution.yaml

# Verify deployment
kubectl get pods -l app=production-app
kubectl get configmaps
kubectl get secrets

# Test the application
kubectl port-forward service/production-app-service 8080:80
curl http://localhost:8080
```

### Configuration Management
```bash
# Update configuration (rolling update)
kubectl patch configmap production-app-config \
  --patch='{"data":{"log_level":"info"}}'

# Restart deployment to pick up changes
kubectl rollout restart deployment/production-app

# View configuration in pod
kubectl exec deployment/production-app -- ls -la /etc/app/config
kubectl exec deployment/production-app -- cat /etc/app/config/app_name
```

### Secret Management
```bash
# Create secret from command line
kubectl create secret generic app-secret \
  --from-literal=username=admin \
  --from-literal=password=secret123

# Create secret from file
echo -n "admin" > username.txt
echo -n "secret123" > password.txt
kubectl create secret generic app-secret \
  --from-file=username.txt \
  --from-file=password.txt

# View secret (base64 encoded)
kubectl get secret app-secret -o yaml

# Decode secret value
kubectl get secret app-secret -o jsonpath='{.data.username}' | base64 -d
```

## 🔧 Troubleshooting

### Common Issues

1. **ConfigMap Changes Not Reflected**
   - ConfigMaps are not automatically reloaded
   - Restart pods or use tools like Reloader

2. **Secret Mount Permissions**
   ```bash
   # Check file permissions in container
   kubectl exec pod-name -- ls -la /etc/secrets/
   
   # Fix: Set proper defaultMode in volume spec
   defaultMode: 0400  # Read-only for owner
   ```

3. **Environment Variable Issues**
   ```bash
   # Debug environment variables
   kubectl exec pod-name -- env | grep -i config
   
   # Check if ConfigMap exists
   kubectl get configmap config-name -o yaml
   ```

4. **Base64 Encoding Issues**
   ```bash
   # Correct way to encode
   echo -n "password123" | base64
   
   # Decode to verify
   echo "cGFzc3dvcmQxMjM=" | base64 -d
   ```

## 🎯 Production Checklist

- [ ] Use appropriate secret types
- [ ] Set restrictive file permissions (0400-0600)
- [ ] Use secretKeyRef for environment variables
- [ ] Implement configuration validation
- [ ] Use immutable ConfigMaps for static data
- [ ] Implement proper error handling
- [ ] Add health checks and monitoring
- [ ] Use namespace isolation
- [ ] Implement configuration rollback strategy
- [ ] Document configuration changes

## 📚 Further Reading

- [Kubernetes ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Configuration Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Security Best Practices](https://kubernetes.io/docs/concepts/security/)

---

*These solutions demonstrate production-ready patterns for configuration management. Always validate configurations in a test environment before applying to production!* 🚀