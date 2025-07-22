# 🚀 Quick Start Guide

Get up and running with the Kubernetes Workshop in under 10 minutes!

## ⚡ 1-Minute Setup

### Prerequisites Check
```bash
# Check if you have the required tools
docker --version    # Should show v20.0+
kubectl version     # Should show client version
minikube version    # Should show v1.25.0+
```

**Don't have these tools?** Jump to [Full Setup](#full-setup) below.

### Instant Workshop Start
```bash
# Clone or navigate to workshop directory
cd kubernetes-workshop

# Run automated setup (handles everything!)
./scripts/setup-env.sh

# Open interactive guide
open kube.html  # macOS
# or visit file:///path/to/kube.html in browser

# Start first hands-on module
cd 03-hands-on/deploying-apps
```

## 🎯 Learning Paths

### Path 1: Complete Beginner (3-4 hours)
```
01-introduction → 02-setup → 03-hands-on/deploying-apps → 
03-hands-on/services-ingress → 03-hands-on/configmaps-secrets
```

### Path 2: Experienced Developer (2-3 hours)
```
02-setup → 03-hands-on/deploying-apps → 03-hands-on/security → 
03-hands-on/monitoring
```

### Path 3: Quick Demo (1 hour)
```
02-setup → 03-hands-on/deploying-apps → kube.html (visual guide)
```

## 📚 Module Quick Access

| Module | Time | Difficulty | Key Skills |
|--------|------|------------|------------|
| [**01-introduction**](01-introduction/README.md) | 15 min | Beginner | Concepts, Architecture |
| [**02-setup**](02-setup/README.md) | 15 min | Beginner | Environment, Tools |
| [**deploying-apps**](03-hands-on/deploying-apps/README.md) | 60 min | Beginner | Pods, Deployments |
| [**services-ingress**](03-hands-on/services-ingress/README.md) | 60 min | Intermediate | Networking, TLS |
| [**configmaps-secrets**](03-hands-on/configmaps-secrets/README.md) | 45 min | Intermediate | Configuration |
| [**security**](03-hands-on/security/README.md) | 75 min | Advanced | RBAC, Policies |
| [**monitoring**](03-hands-on/monitoring/README.md) | 60 min | Intermediate | Observability |

## ⚡ Quick Commands

### Environment Validation
```bash
# Check cluster status
kubectl cluster-info

# Verify system pods
kubectl get pods -n kube-system

# Test basic functionality
kubectl run test --image=nginx:1.25-alpine --rm -it --restart=Never -- echo "Kubernetes is working!"
```

### Essential kubectl Commands
```bash
# Core operations
kubectl get pods                    # List pods
kubectl describe pod <name>         # Pod details
kubectl logs <pod-name>            # Pod logs
kubectl exec -it <pod> -- sh       # Shell into pod
kubectl apply -f <file.yaml>       # Apply configuration
kubectl delete -f <file.yaml>      # Remove resources

# Quick aliases (run once)
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
```

## 🏁 Full Setup

### System Requirements
- **OS**: macOS 10.14+, Windows 10+, Linux (Ubuntu 18.04+)
- **RAM**: 4GB minimum (8GB recommended)
- **CPU**: 2+ cores
- **Disk**: 20GB free space
- **Internet**: Required for downloads

### Tool Installation

#### macOS (Homebrew)
```bash
# Install required tools
brew install docker kubectl minikube

# Start Docker Desktop
open -a Docker

# Verify installation
docker --version && kubectl version --client && minikube version
```

#### Windows (Chocolatey)
```powershell
# Install Chocolatey first: https://chocolatey.org/install

# Install tools
choco install docker-desktop kubernetes-cli minikube

# Start Docker Desktop and verify
docker --version; kubectl version --client; minikube version
```

#### Ubuntu/Debian
```bash
# Install Docker
sudo apt-get update
sudo apt-get install docker.io
sudo usermod -aG docker $USER

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Restart shell to apply group changes
exec su -l $USER
```

### Cluster Startup
```bash
# Configure minikube (optional)
minikube config set memory 4096
minikube config set cpus 2

# Start cluster
minikube start

# Enable useful addons
minikube addons enable dashboard
minikube addons enable ingress
minikube addons enable metrics-server

# Verify cluster
kubectl get nodes
kubectl get pods -n kube-system
```

## 🆘 Troubleshooting

### Common Issues

**🔧 Docker not starting**
```bash
# macOS/Windows: Restart Docker Desktop
# Linux: sudo systemctl restart docker
docker system info  # Check status
```

**🔧 minikube won't start**
```bash
# Reset and try again
minikube delete
minikube start --driver=docker --memory=4096

# Check system resources
minikube status
```

**🔧 kubectl not connecting**
```bash
# Check context
kubectl config current-context

# Reset kubeconfig if needed
kubectl config use-context minikube
```

**🔧 Pods stuck in Pending**
```bash
# Check node resources
kubectl describe nodes
kubectl top nodes

# Check pod events
kubectl describe pod <pod-name>
```

### Getting Help

- **GitHub Issues**: [Repository Issues](https://github.com/kubernetes/kubernetes/issues)
- **Community Slack**: [Kubernetes Slack](https://kubernetes.slack.com/)
- **Documentation**: [Official Kubernetes Docs](https://kubernetes.io/docs/)
- **Stack Overflow**: [kubernetes tag](https://stackoverflow.com/questions/tagged/kubernetes)

## 🎉 You're Ready!

### Next Steps
1. **Start learning**: Pick your [learning path](#learning-paths)
2. **Join community**: Connect with other learners
3. **Practice regularly**: Consistency builds expertise
4. **Contribute back**: Share your learning journey

### Workshop Resources
- 📊 **Interactive Guide**: Open `kube.html` for visual learning
- 📝 **Presentation**: Use `kubernetes_powerpoint_outline.md` for teaching
- 🛠️ **Scripts**: Automation tools in `scripts/` directory
- 📚 **Documentation**: Comprehensive guides in each module

---

**Happy Learning!** 🚀 *Remember: The best way to learn Kubernetes is by doing. Start with simple concepts and build complexity gradually.*

*Questions? Issues? Check the troubleshooting guide or create an issue in the repository.*