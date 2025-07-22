# Deploying Applications in Kubernetes

Learn the fundamentals of deploying and managing applications in Kubernetes using Pods, Deployments, and ReplicaSets.

## 🎯 Learning Objectives

By the end of this module, you will be able to:
- Create and manage Pods directly
- Deploy applications using Deployments
- Understand ReplicaSets and their role
- Configure resource limits and requests
- Implement health checks with probes
- Perform rolling updates and rollbacks
- Apply security contexts and best practices

## 📚 Prerequisites

- ✅ Completed **01-introduction** and **02-setup**
- ✅ Working Kubernetes cluster (minikube recommended)
- ✅ kubectl configured and accessible
- ✅ Basic understanding of YAML syntax

## 🗂️ Module Structure

```
deploying-apps/
├── README.md           # This file - complete learning guide
├── manifests/          # YAML files for exercises
│   ├── my-first-pod.yaml           # Basic pod example
│   ├── nginx-deployment.yaml       # Production deployment
│   ├── nginx-deployment-with-pdb.yaml  # Advanced deployment
│   ├── resource-limits-demo.yaml   # Resource management
│   ├── health-checks-demo.yaml     # Probes and health monitoring
│   └── rolling-update-demo.yaml    # Update strategies
├── scripts/            # Helper scripts and validation
└── solutions/          # Reference solutions for exercises
```

## 🚀 Lab Exercises

### Lab 1: Your First Pod (15 minutes)

**Objective**: Create and manage a basic Pod to understand fundamental concepts.

#### Step 1: Create a Simple Pod
```bash
# Navigate to the module directory
cd 03-hands-on/deploying-apps

# Apply the pod configuration
kubectl apply -f manifests/my-first-pod.yaml

# Watch the pod creation process
kubectl get pods -w
```

#### Step 2: Examine the Pod
```bash
# Get detailed pod information
kubectl describe pod nginx-pod

# Check pod logs
kubectl logs nginx-pod

# Get pod in different formats
kubectl get pod nginx-pod -o wide
kubectl get pod nginx-pod -o yaml
```

#### Step 3: Interact with the Pod
```bash
# Execute commands in the pod
kubectl exec -it nginx-pod -- /bin/sh

# Inside the pod:
whoami              # Check user (should be nobody/65534)
ps aux              # List processes
wget -qO- http://localhost:8080  # Test nginx
exit
```

#### Step 4: Port Forward to Access the Application
```bash
# Forward local port to pod port
kubectl port-forward nginx-pod 8080:8080

# In another terminal, test the connection
curl http://localhost:8080

# Stop port-forward with Ctrl+C
```

### Lab 2: Deployments and ReplicaSets (20 minutes)

**Objective**: Learn declarative application management with Deployments.

#### Step 1: Create a Deployment
```bash
# Apply the deployment
kubectl apply -f manifests/nginx-deployment.yaml

# Watch deployment rollout
kubectl rollout status deployment/nginx-deployment

# Examine what was created
kubectl get deployments
kubectl get replicasets
kubectl get pods -l app=nginx
```

#### Step 2: Scale the Deployment
```bash
# Scale up to 5 replicas
kubectl scale deployment nginx-deployment --replicas=5

# Watch scaling in action
kubectl get pods -l app=nginx -w

# Scale back down
kubectl scale deployment nginx-deployment --replicas=3
```

#### Step 3: Update the Deployment
```bash
# Update the image (simulate new version)
kubectl set image deployment/nginx-deployment nginx=nginx:1.25-alpine

# Watch the rolling update
kubectl rollout status deployment/nginx-deployment

# Check rollout history
kubectl rollout history deployment/nginx-deployment
```

#### Step 4: Rollback if Needed
```bash
# Simulate a bad update
kubectl set image deployment/nginx-deployment nginx=nginx:bad-tag

# Check rollout status (it will fail)
kubectl rollout status deployment/nginx-deployment

# Rollback to previous version
kubectl rollout undo deployment/nginx-deployment

# Verify rollback
kubectl rollout status deployment/nginx-deployment
```

### Lab 3: Advanced Deployment Features (25 minutes)

**Objective**: Implement production-ready deployment patterns.

#### Step 1: Deploy with Pod Disruption Budget
```bash
# Apply the advanced deployment
kubectl apply -f manifests/nginx-deployment-with-pdb.yaml

# Check what was created
kubectl get deployment,configmap,pdb
```

#### Step 2: Test High Availability
```bash
# Get pod names
kubectl get pods -l app=nginx

# Delete a pod to test self-healing
kubectl delete pod <pod-name>

# Watch automatic replacement
kubectl get pods -l app=nginx -w

# Try to delete multiple pods (PDB should prevent disruption)
kubectl delete pods -l app=nginx --wait=false
```

#### Step 3: Examine Resource Management
```bash
# Check resource allocation
kubectl describe nodes
kubectl top pods

# View resource requests and limits
kubectl describe deployment nginx-deployment
```

### Lab 4: Health Checks and Monitoring (15 minutes)

**Objective**: Implement robust health checking for applications.

#### Step 1: Understanding Probes
```bash
# Create deployment with comprehensive health checks
cat > manifests/health-checks-demo.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: health-demo
  labels:
    app: health-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: health-demo
  template:
    metadata:
      labels:
        app: health-demo
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 8080
          name: http
        # Startup probe - gives container time to initialize
        startupProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 6
        # Readiness probe - determines if pod can receive traffic
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 3
          failureThreshold: 3
        # Liveness probe - restarts container if unhealthy
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 10
          failureThreshold: 3
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
          capabilities:
            drop:
            - ALL
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

# Apply the health check demo
kubectl apply -f manifests/health-checks-demo.yaml
```

#### Step 2: Observe Health Check Behavior
```bash
# Watch pod startup with detailed events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check pod readiness
kubectl get pods -l app=health-demo

# Describe pod to see probe results
kubectl describe pod -l app=health-demo
```

#### Step 3: Test Failure Scenarios
```bash
# Simulate application failure by making health check fail
kubectl exec -it $(kubectl get pod -l app=health-demo -o jsonpath='{.items[0].metadata.name}') -- sh -c "pkill nginx"

# Watch kubernetes restart the container
kubectl get pods -l app=health-demo -w

# Check events to see the restart
kubectl get events --field-selector involvedObject.name=$(kubectl get pod -l app=health-demo -o jsonpath='{.items[0].metadata.name}')
```

## 📋 Validation and Testing

### Module Validation Commands
```bash
# Verify all components are working
./scripts/validate-deploying-apps.sh

# Or run individual checks:

# Check pod is running and healthy
kubectl get pods nginx-pod -o jsonpath='{.status.phase}'

# Verify deployment has desired replicas
kubectl get deployment nginx-deployment -o jsonpath='{.status.readyReplicas}'

# Test application accessibility
kubectl port-forward deployment/nginx-deployment 8080:8080 &
curl -f http://localhost:8080
pkill kubectl  # Stop port-forward
```

### Success Criteria
✅ **Basic Pod Management**:
- Can create, describe, and delete pods
- Understand pod lifecycle and status
- Can execute commands in pods

✅ **Deployment Operations**:
- Can create and scale deployments
- Understand rolling updates and rollbacks
- Can manage deployment history

✅ **Resource Management**:
- Pods have appropriate resource limits
- Can monitor resource usage
- Understand resource requests vs limits

✅ **Health Monitoring**:
- Can configure liveness and readiness probes
- Understand probe types and their purposes
- Can troubleshoot unhealthy pods

## 🔧 Troubleshooting Guide

### Common Issues and Solutions

#### Pod Stuck in Pending
```bash
# Check node resources
kubectl describe nodes
kubectl top nodes

# Check pod events
kubectl describe pod <pod-name>

# Solution: Scale down other workloads or add more nodes
```

#### Pod CrashLoopBackOff
```bash
# Check pod logs
kubectl logs <pod-name> --previous

# Check events
kubectl describe pod <pod-name>

# Common causes: Wrong image, missing config, resource limits too low
```

#### Deployment Not Rolling Out
```bash
# Check deployment events
kubectl describe deployment <deployment-name>

# Check replica set status
kubectl get rs

# Force restart if needed
kubectl rollout restart deployment/<deployment-name>
```

#### Health Checks Failing
```bash
# Check probe configuration
kubectl describe pod <pod-name>

# Test probe endpoint manually
kubectl exec <pod-name> -- curl -f http://localhost:8080/health

# Adjust probe timing or endpoint
```

## 🎯 Advanced Challenges

### Challenge 1: Blue-Green Deployment
Implement a blue-green deployment strategy using labels and services.

### Challenge 2: Canary Deployment  
Create a canary deployment that routes 10% of traffic to a new version.

### Challenge 3: Multi-Container Pod
Deploy a pod with multiple containers (sidecar pattern).

### Challenge 4: Custom Health Checks
Implement custom health check endpoints in your application.

## 📚 Additional Resources

### Official Documentation
- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)

### Best Practices
- [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Security Contexts](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

## ⏭️ Next Steps

After completing this module:
1. ✅ Clean up resources: `kubectl delete -f manifests/`  
2. ✅ Proceed to **services-ingress** for networking
3. ✅ Review concepts that weren't clear
4. ✅ Try the advanced challenges

---

*Congratulations! You've mastered the fundamentals of deploying applications in Kubernetes. Next, let's learn how to expose and connect these applications!* 🚀