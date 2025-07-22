# Kubernetes Architecture Presentation with Interactive Labs

This repository contains a comprehensive PowerPoint presentation about Kubernetes architecture with integrated hands-on labs for an interactive learning experience.

## 📋 Workshop Structure

### 🎓 Learning Modules
- **`01-introduction/`** - Kubernetes concepts and architecture fundamentals
- **`02-setup/`** - Local and cloud cluster setup with comprehensive guides
- **`03-hands-on/`** - Practical exercises organized by topic:
  - **`deploying-apps/`** - Pod and Deployment management
  - **`services-ingress/`** - Networking and traffic management
  - **`configmaps-secrets/`** - Configuration and secrets management
  - **`security/`** - Security best practices and RBAC
  - **`monitoring/`** - Observability and troubleshooting

### 📚 Support Materials
- **`kube.html`** - Interactive visual guide with modern design
- **`kubernetes_powerpoint_outline.md`** - 25-slide presentation outline
- **`scripts/`** - Automated setup and validation scripts
- **`assets/`** - Diagrams, presentations, and learning resources
- **`QUICKSTART.md`** - 10-minute setup guide for immediate start

## 🎯 Presentation Structure

### Core Content (14 slides)
1. **Introduction** (2 slides) - Title and overview
2. **Container Engine Types and Features** (2 slides) - Runtime landscape and feature comparison
3. **Container Fundamentals** (1 slide) - Namespaces and cgroups
4. **Orchestration Challenge** (1 slide) - Why we need Kubernetes
5. **Kubernetes Architecture** (7 slides) - Deep dive into components
6. **Conclusion** (2 slides) - Next steps and Q&A

### Interactive Labs (5 labs + 6 supporting slides)
- **Lab Setup Instructions** (1 slide)
- **Lab Overview & Timing** (1 slide)
- **Lab 1**: Start Your First Cluster (5 min)
- **Lab 2**: Create Your First Pod (8 min)
- **Lab 3**: Explore Worker Node Components (6 min)
- **Lab 4**: Services and Scaling (10 min)
- **Lab 5**: Cleanup and Resource Management (3 min)

## ⏱️ Timing
- **Total presentation time**: 75-90 minutes
- **Lab time**: ~32 minutes
- **Lecture time**: ~43-58 minutes
- **Format**: Interactive with hands-on practice

## 🔧 Prerequisites

### System Requirements
- **Operating System**: Windows 10+, macOS 10.14+, or Linux (Ubuntu 18.04+)
- **RAM**: Minimum 4GB available (8GB recommended)
- **CPU**: 2+ cores recommended
- **Disk Space**: 20GB free space minimum
- **Internet**: Required for downloading images and tools
- **Virtualization**: VT-x/AMD-v enabled in BIOS (for minikube)

### Required Tools
- [minikube](https://minikube.sigs.k8s.io/docs/start/) v1.25.0+ - Local Kubernetes cluster
- [kubectl](https://kubernetes.io/docs/tasks/tools/) v1.25.0+ - Kubernetes command-line tool
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) v20.0+ - Container runtime
- Terminal/Command prompt with admin privileges

### Quick Setup Verification
```bash
# Check versions
minikube version
kubectl version --client
docker --version

# Test minikube can start (this may take 5-10 minutes first time)
minikube start --dry-run

# Verify Docker is running
docker ps
```

### Common Installation Issues
- **Windows**: Enable Hyper-V or use WSL2 backend for Docker
- **macOS**: Install Xcode command line tools if needed
- **Linux**: Add user to docker group: `sudo usermod -aG docker $USER`
- **VirtualBox conflicts**: Use `--driver=docker` flag with minikube

### Alternative Options (No Installation Required)
- [Play with Kubernetes](https://labs.play-with-k8s.com/) - Browser-based K8s playground
- [Katacoda](https://katacoda.com/courses/kubernetes) - Interactive scenarios
- [Killercoda](https://killercoda.com/kubernetes) - Hands-on labs

## 🧪 Hands-On Learning Path

### 🏁 Getting Started (30-45 min)
- **Introduction**: Core concepts and container fundamentals
- **Setup**: Environment configuration with automated scripts
- **Validation**: Comprehensive cluster readiness checks

### 🚀 Core Applications (45-60 min)
- **Deploying Apps**: Pods, Deployments, health checks, rolling updates
- **Services & Ingress**: Networking, load balancing, TLS configuration
- **Configuration**: ConfigMaps, Secrets, environment management

### 🔐 Production Readiness (60-75 min)
- **Security**: RBAC, Pod Security Standards, network policies
- **Monitoring**: Observability, logging, performance troubleshooting
- **Advanced**: Multi-tenancy, operators, custom resources

## 🎓 Learning Outcomes

By completing this workshop, students will master:

### 📖 **Theoretical Knowledge**
- Container engine comparison and selection criteria
- Kubernetes architecture and component interactions
- Pod lifecycle and scheduling decisions
- Service discovery and networking patterns
- Security contexts and best practices

### 🛠️ **Practical Skills**
- Deploy and manage applications with Deployments
- Configure networking with Services and Ingress
- Manage configuration with ConfigMaps and Secrets
- Implement security policies and RBAC
- Set up monitoring and troubleshoot issues
- Perform rolling updates and rollbacks

### 🎯 **Production Readiness**
- Apply security-first development practices
- Implement proper resource management
- Design for high availability and scalability
- Troubleshoot common operational issues
- Follow Kubernetes best practices and patterns

## 👨‍🏫 For Presenters

### Preparation Checklist
- [ ] Install and test minikube, kubectl, Docker
- [ ] Download lab files to working directory
- [ ] Set up two terminals (commands + watching)
- [ ] Prepare backup online environments
- [ ] Test all commands beforehand

### Key Teaching Points
1. **Kubernetes is orchestration** - Managing application lifecycle
2. **Everything is declarative** - Describe desired state
3. **Components work together** - API Server, etcd, scheduler collaboration
4. **Labels are powerful** - How everything connects
5. **Observability is key** - describe, logs, events

### Troubleshooting Tips
- Have backup online environments ready
- Use `kubectl describe` for debugging
- Reset with `minikube delete && minikube start`
- Skip optional steps if running long

### Extended Troubleshooting Guide
- **Pods stuck in Pending**: Check resources with `kubectl describe node`
- **Image pull failures**: Verify internet connectivity and Docker Hub access
- **Permission denied**: Ensure Docker daemon is running and user has permissions
- **Resource exhaustion**: Increase minikube memory: `minikube start --memory=6144`
- **Network issues**: Try `minikube start --driver=docker --network-plugin=cni`
- **DNS resolution fails**: Restart CoreDNS: `kubectl rollout restart deployment coredns -n kube-system`

## 📚 Additional Resources

### Official Documentation
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kubernetes Tutorials](https://kubernetes.io/docs/tutorials/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)

### Practice Environments
- [minikube](https://minikube.sigs.k8s.io/docs/) - Local development
- [kind](https://kind.sigs.k8s.io/) - Kubernetes in Docker
- [k3s](https://k3s.io/) - Lightweight Kubernetes

### Certification Paths
- **CKA** (Certified Kubernetes Administrator)
- **CKAD** (Certified Kubernetes Application Developer)
- **CKS** (Certified Kubernetes Security Specialist)

## 🤝 Contributing

Feel free to:
- Suggest improvements to labs
- Add more troubleshooting scenarios
- Enhance explanations
- Create additional exercises

## 📄 License

This content is provided for educational purposes. Feel free to use and modify for your presentations and training sessions. 