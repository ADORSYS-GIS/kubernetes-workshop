# 03 - Hands-On: Practical Exercises

This section contains comprehensive hands-on exercises to master Kubernetes operations. Each subdirectory focuses on specific aspects of Kubernetes workload management.

## 🎯 Learning Path

### Prerequisites
- ✅ Completed **01-introduction**
- ✅ Completed **02-setup** with working cluster
- ✅ Basic command line familiarity
- ✅ Understanding of YAML syntax

### Exercise Structure
Each exercise follows this pattern:
1. **Learning Objectives** - What you'll master
2. **Concepts** - Theory and best practices  
3. **Hands-On Lab** - Step-by-step practical work
4. **Validation** - Verify your understanding
5. **Challenges** - Extended exercises for deeper learning

## 📚 Module Overview

### [deploying-apps/](./deploying-apps/README.md)
**Duration**: 45-60 minutes  
**Difficulty**: Beginner

Learn the fundamentals of deploying applications in Kubernetes:
- Pods, Deployments, and ReplicaSets
- Resource management and limits
- Labels and selectors
- Health checks and probes
- Rolling updates and rollbacks

**Key Files**:
- `basic-pod.yaml` - Simple pod definition
- `nginx-deployment.yaml` - Production-ready deployment
- `deployment-with-probes.yaml` - Health check examples

---

### [services-ingress/](./services-ingress/README.md)
**Duration**: 45-60 minutes  
**Difficulty**: Intermediate

Master Kubernetes networking and traffic management:
- Services (ClusterIP, NodePort, LoadBalancer)
- Ingress controllers and rules
- Network policies and security
- Service mesh basics

**Key Files**:
- `service-types.yaml` - All service types demonstrated
- `ingress-example.yaml` - HTTP routing and SSL
- `network-policy.yaml` - Traffic isolation

---

### [configmaps-secrets/](./configmaps-secrets/README.md)  
**Duration**: 30-45 minutes
**Difficulty**: Beginner-Intermediate

Handle application configuration and sensitive data:
- ConfigMaps for configuration management
- Secrets for sensitive information
- Volume mounts and environment variables
- Configuration hot-reloading

**Key Files**:
- `app-config.yaml` - ConfigMap examples
- `database-secrets.yaml` - Secret management
- `config-volume-mount.yaml` - File-based configuration

---

### [security/](./security/README.md)
**Duration**: 60-75 minutes  
**Difficulty**: Intermediate-Advanced

Implement security best practices in Kubernetes:
- Pod Security Standards and contexts
- Role-Based Access Control (RBAC)
- Network segmentation
- Image security scanning
- Admission controllers

**Key Files**:
- `pod-security-standards.yaml` - Security context examples
- `rbac-examples.yaml` - User and service account permissions
- `security-policies.yaml` - Admission controller policies

---

### [monitoring/](./monitoring/README.md)
**Duration**: 45-60 minutes
**Difficulty**: Intermediate

Set up observability and monitoring:
- Metrics collection with Prometheus
- Log aggregation strategies  
- Health monitoring and alerting
- Performance optimization
- Troubleshooting techniques

**Key Files**:
- `prometheus-setup.yaml` - Metrics monitoring
- `logging-stack.yaml` - Centralized logging
- `dashboards/` - Grafana dashboard configs

## 🚀 Quick Start Guide

### 1. Choose Your Path

**Beginner Path** (Recommended sequence):
```
deploying-apps → configmaps-secrets → services-ingress → monitoring → security
```

**Experienced Path** (Focus on specific areas):
```
Pick modules based on your immediate needs
```

### 2. Validate Environment

Before starting any module:
```bash
# Ensure cluster is accessible
kubectl cluster-info

# Check cluster resources
kubectl get nodes
kubectl top nodes

# Verify system pods
kubectl get pods -n kube-system
```

### 3. Module Navigation

Each module contains:
```
module-name/
├── README.md           # Learning guide and instructions
├── manifests/          # YAML files for exercises  
├── scripts/            # Helper automation scripts
├── solutions/          # Reference solutions
└── challenges/         # Advanced exercises
```

## 🎓 Learning Methodology

### Hands-On First Approach
1. **Deploy** - Start with working examples
2. **Observe** - See how components interact
3. **Modify** - Change parameters and observe effects
4. **Break** - Intentionally cause failures to understand recovery
5. **Fix** - Apply troubleshooting skills

### Validation Strategy
Each exercise includes validation commands:
```bash
# Example validation pattern
kubectl get pods -l app=example
kubectl describe deployment example-app
kubectl logs -f deployment/example-app
```

### Best Practices Integration
- Security-first mindset with non-root containers
- Resource management with requests and limits
- Observability with proper labeling and metrics
- Documentation as code with YAML comments

## 🛠️ Tools and Utilities

### Required Command Line Tools
```bash
# Core tools (should be already installed)
kubectl --version
docker --version

# Useful additions for hands-on work
curl --version          # API testing
jq --version           # JSON processing  
yq --version           # YAML processing (optional)
```

### Helpful kubectl Shortcuts
```bash
# Add to ~/.bashrc or ~/.zshrc
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias ke='kubectl exec -it'

# Enable autocompletion
source <(kubectl completion bash)
```

### VS Code Extensions (Recommended)
- **Kubernetes** - Microsoft Kubernetes support
- **YAML** - Red Hat YAML language support
- **Docker** - Microsoft Docker support

## 📊 Progress Tracking

### Module Completion Checklist
Track your progress through the exercises:

- [ ] **deploying-apps**: Basic workload deployment
- [ ] **services-ingress**: Networking and traffic management  
- [ ] **configmaps-secrets**: Configuration management
- [ ] **security**: Security hardening and RBAC
- [ ] **monitoring**: Observability and troubleshooting

### Skill Assessment
After completing modules, you should be able to:

**Beginner Level**:
- [ ] Deploy applications using Deployments and Services
- [ ] Manage application configuration with ConfigMaps
- [ ] Troubleshoot basic pod and service issues
- [ ] Apply security contexts and resource limits

**Intermediate Level**:
- [ ] Implement complex networking with Ingress
- [ ] Design RBAC policies for multi-tenant environments
- [ ] Set up monitoring and alerting pipelines
- [ ] Perform rolling updates and canary deployments

**Advanced Level**:
- [ ] Design security policies and admission controllers
- [ ] Implement custom monitoring and observability
- [ ] Troubleshoot complex cluster and networking issues
- [ ] Optimize workload performance and resource utilization

## 🆘 Getting Help

### Troubleshooting Resources
- Each module includes a **Troubleshooting** section
- Common error scenarios and solutions provided
- Reference to `../lab-files/validation-commands.txt`

### Community Support
- [Kubernetes Slack Community](https://kubernetes.slack.com/)
- [Stack Overflow - Kubernetes Tag](https://stackoverflow.com/questions/tagged/kubernetes)
- [Reddit r/kubernetes](https://www.reddit.com/r/kubernetes/)

### Documentation References
- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
- [API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)

---

**Ready to get your hands dirty with Kubernetes?** 

Pick your first module and let's start building! 🚀

*Remember: The best way to learn Kubernetes is by doing. Don't be afraid to experiment, break things, and learn from failures!*