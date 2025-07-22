# 02 - Setup: Local and Cloud Cluster Setup

This section guides you through setting up Kubernetes environments for both local development and cloud-based learning.

## 🎯 Setup Options

Choose the setup that best fits your needs:

### Option A: Local Development (Recommended for Learning)
- **minikube**: Single-node cluster for development
- **kind**: Kubernetes in Docker containers
- **Docker Desktop**: Built-in Kubernetes support

### Option B: Cloud Playground (No Installation)
- **Play with Kubernetes**: Browser-based environment
- **Katacoda/Killercoda**: Interactive scenarios
- **Cloud provider free tiers**: GKE, EKS, AKS

### Option C: Production-like Setup
- **k3s**: Lightweight Kubernetes for edge/IoT
- **MicroK8s**: Canonical's minimal Kubernetes
- **kubeadm**: Bootstrap production clusters

## 🛠️ Local Setup Guide

### Prerequisites Checklist

#### System Requirements
- [ ] **OS**: Windows 10+, macOS 10.14+, or Linux (Ubuntu 18.04+)
- [ ] **RAM**: 4GB minimum (8GB recommended)
- [ ] **CPU**: 2+ cores
- [ ] **Disk**: 20GB free space
- [ ] **Virtualization**: VT-x/AMD-v enabled in BIOS

#### Required Tools
- [ ] **Docker Desktop** v20.0+
- [ ] **kubectl** v1.25.0+  
- [ ] **minikube** v1.25.0+
- [ ] **Terminal/PowerShell** with admin privileges

### Installation Steps

#### 1. Install Docker Desktop
```bash
# macOS (using Homebrew)
brew install --cask docker

# Windows
# Download from: https://www.docker.com/products/docker-desktop/

# Linux (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install docker.io
sudo usermod -aG docker $USER
```

#### 2. Install kubectl
```bash
# macOS
brew install kubectl

# Windows (using Chocolatey)
choco install kubernetes-cli

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

#### 3. Install minikube
```bash
# macOS
brew install minikube

# Windows
choco install minikube

# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

### Verification Commands

Run these commands to verify your installation:

```bash
# Check Docker
docker --version
docker ps

# Check kubectl
kubectl version --client

# Check minikube
minikube version

# Test minikube startup (may take 5-10 minutes first time)
minikube start --driver=docker --memory=4096 --cpus=2

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

## 🌐 Cloud Setup Alternatives

### Play with Kubernetes (Instant Access)
1. Visit [labs.play-with-k8s.com](https://labs.play-with-k8s.com/)
2. Log in with Docker Hub account
3. Click "Add New Instance"
4. Start with pre-configured Kubernetes cluster

### Killercoda Interactive Labs
1. Visit [killercoda.com/kubernetes](https://killercoda.com/kubernetes)
2. Choose from various Kubernetes scenarios
3. No installation required - runs in browser

### Cloud Provider Free Tiers

#### Google Kubernetes Engine (GKE)
```bash
# Install gcloud CLI
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Create cluster
gcloud container clusters create learning-cluster \
    --num-nodes=2 \
    --machine-type=e2-small \
    --zone=us-central1-a

# Get credentials
gcloud container clusters get-credentials learning-cluster --zone=us-central1-a
```

#### Amazon EKS (with eksctl)
```bash
# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Create cluster
eksctl create cluster --name learning-cluster --version 1.24 --region us-west-2 --nodegroup-name workers --node-type t3.small --nodes 2
```

## 🔧 Configuration and Optimization

### minikube Configuration
```bash
# Set default resources
minikube config set memory 6144
minikube config set cpus 2
minikube config set driver docker

# Enable useful addons
minikube addons enable dashboard
minikube addons enable metrics-server
minikube addons enable ingress

# View configuration
minikube config view
```

### kubectl Configuration
```bash
# Set up autocompletion (bash)
echo 'source <(kubectl completion bash)' >>~/.bashrc

# Set up autocompletion (zsh)
echo 'source <(kubectl completion zsh)' >>~/.zshrc

# Create useful aliases
echo 'alias k=kubectl' >>~/.bashrc
echo 'alias kgp="kubectl get pods"' >>~/.bashrc
echo 'alias kgs="kubectl get services"' >>~/.bashrc
```

## 🚨 Troubleshooting Common Issues

### Docker Desktop Issues
```bash
# Restart Docker Desktop
# macOS/Windows: Restart from system tray

# Linux: Restart Docker daemon
sudo systemctl restart docker

# Check Docker daemon status
docker system info
```

### minikube Issues
```bash
# Reset minikube completely
minikube delete
minikube start --driver=docker

# Check logs for errors
minikube logs

# Use different driver if VirtualBox conflicts
minikube start --driver=hyperkit  # macOS
minikube start --driver=hyperv    # Windows
```

### Network Issues
```bash
# Corporate firewall/proxy
minikube start --docker-env HTTP_PROXY=http://proxy:port \
               --docker-env HTTPS_PROXY=https://proxy:port

# DNS resolution problems
kubectl get pods -n kube-system
kubectl logs -n kube-system -l k8s-app=kube-dns
```

### Resource Limitations
```bash
# Check system resources
minikube status
kubectl top nodes
kubectl describe node minikube

# Increase resources if needed
minikube stop
minikube start --memory=8192 --cpus=4
```

## ✅ Setup Validation

Complete these validation steps to ensure your environment is ready:

### Basic Cluster Validation
```bash
# 1. Cluster accessibility
kubectl cluster-info

# 2. Node readiness
kubectl get nodes -o wide

# 3. System pods running
kubectl get pods -n kube-system

# 4. DNS functionality
kubectl run test-dns --image=busybox:1.35 --rm -it --restart=Never -- nslookup kubernetes.default.svc.cluster.local

# 5. Internet connectivity from pods
kubectl run test-internet --image=busybox:1.35 --rm -it --restart=Never -- ping -c 3 8.8.8.8
```

### Advanced Validation
```bash
# Test pod creation and networking
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - name: test
    image: nginx:1.25-alpine
    ports:
    - containerPort: 8080
EOF

# Wait for pod to be ready
kubectl wait --for=condition=Ready pod/test-pod --timeout=60s

# Test pod networking
kubectl exec test-pod -- curl -s http://kubernetes.default.svc.cluster.local

# Cleanup
kubectl delete pod test-pod
```

## 🎛️ Dashboard Access

Access the Kubernetes Dashboard for GUI management:

```bash
# Enable dashboard addon (minikube)
minikube addons enable dashboard

# Open dashboard in browser
minikube dashboard

# For cloud clusters, use kubectl proxy
kubectl proxy
# Then visit: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

## ⏭️ Next Steps

Once your setup is complete and validated:

1. ✅ Bookmark your cluster access method
2. ✅ Save your configuration commands
3. ✅ Proceed to **03-hands-on** practical exercises
4. ✅ Keep this troubleshooting guide handy

## 📚 Additional Resources

### Official Documentation
- [minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [kubectl Installation Guide](https://kubernetes.io/docs/tasks/tools/)
- [Docker Desktop Kubernetes](https://docs.docker.com/desktop/kubernetes/)

### Alternative Tools
- [kind (Kubernetes in Docker)](https://kind.sigs.k8s.io/)
- [k3s (Lightweight Kubernetes)](https://k3s.io/)
- [MicroK8s](https://microk8s.io/)

---

*Environment ready? Let's start deploying applications!* 🚀