#!/bin/bash

# Kubernetes Workshop Environment Setup Script
# This script helps set up a consistent Kubernetes learning environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSHOP_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="${WORKSHOP_ROOT}/setup.log"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "\n${BLUE}===========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===========================================${NC}\n"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check version requirement
check_version() {
    local tool=$1
    local required_version=$2
    local current_version=$3
    
    print_status "Checking $tool version: $current_version (required: $required_version+)"
    # Note: This is a simplified version check. For production, use proper version comparison.
}

# Function to install kubectl
install_kubectl() {
    print_status "Installing kubectl..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command_exists brew; then
            brew install kubectl
        else
            print_warning "Homebrew not found. Installing kubectl manually..."
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
            chmod +x ./kubectl
            sudo mv ./kubectl /usr/local/bin/kubectl
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x ./kubectl
        sudo mv ./kubectl /usr/local/bin/kubectl
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        # Windows (Git Bash/MinGW)
        print_error "Windows detected. Please install kubectl manually from https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/"
        return 1
    fi
}

# Function to install minikube
install_minikube() {
    print_status "Installing minikube..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command_exists brew; then
            brew install minikube
        else
            curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
            sudo install minikube-darwin-amd64 /usr/local/bin/minikube
            rm minikube-darwin-amd64
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        sudo install minikube-linux-amd64 /usr/local/bin/minikube
        rm minikube-linux-amd64
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        # Windows
        print_error "Windows detected. Please install minikube manually from https://minikube.sigs.k8s.io/docs/start/"
        return 1
    fi
}

# Function to check system requirements
check_system_requirements() {
    print_header "Checking System Requirements"
    
    # Check available memory
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local total_mem=$(system_profiler SPHardwareDataType | grep "Memory:" | awk '{print $2}' | sed 's/GB//')
        print_status "Total system memory: ${total_mem}GB"
        if (( $(echo "$total_mem < 4" | bc -l) )); then
            print_warning "Less than 4GB RAM detected. Kubernetes may run slowly."
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        local total_mem=$(free -g | awk '/^Mem:/{print $2}')
        print_status "Total system memory: ${total_mem}GB"
        if (( total_mem < 4 )); then
            print_warning "Less than 4GB RAM detected. Kubernetes may run slowly."
        fi
    fi
    
    # Check CPU cores
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local cpu_cores=$(sysctl -n hw.ncpu)
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        local cpu_cores=$(nproc)
    else
        local cpu_cores="unknown"
    fi
    
    print_status "CPU cores available: $cpu_cores"
    if [[ "$cpu_cores" != "unknown" ]] && (( cpu_cores < 2 )); then
        print_warning "Less than 2 CPU cores detected. Performance may be limited."
    fi
    
    # Check disk space
    local available_space=$(df -h "$WORKSHOP_ROOT" | awk 'NR==2 {print $4}')
    print_status "Available disk space: $available_space"
}

# Function to verify installations
verify_tools() {
    print_header "Verifying Tool Installations"
    
    local all_good=true
    
    # Check Docker
    if command_exists docker; then
        local docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
        print_status "Docker found: $docker_version"
        
        # Check if Docker daemon is running
        if docker info >/dev/null 2>&1; then
            print_status "Docker daemon is running"
        else
            print_error "Docker daemon is not running. Please start Docker Desktop."
            all_good=false
        fi
    else
        print_error "Docker not found. Please install Docker Desktop from https://www.docker.com/products/docker-desktop/"
        all_good=false
    fi
    
    # Check kubectl
    if command_exists kubectl; then
        local kubectl_version=$(kubectl version --client --short 2>/dev/null | awk '{print $3}' || echo "unknown")
        print_status "kubectl found: $kubectl_version"
    else
        print_warning "kubectl not found. Attempting to install..."
        install_kubectl
    fi
    
    # Check minikube
    if command_exists minikube; then
        local minikube_version=$(minikube version --short 2>/dev/null || echo "unknown")
        print_status "minikube found: $minikube_version"
    else
        print_warning "minikube not found. Attempting to install..."
        install_minikube
    fi
    
    return $all_good
}

# Function to setup minikube
setup_minikube() {
    print_header "Setting Up Minikube"
    
    # Configure minikube defaults
    print_status "Configuring minikube defaults..."
    minikube config set memory 4096
    minikube config set cpus 2
    minikube config set driver docker
    
    # Start minikube if not running
    if minikube status >/dev/null 2>&1; then
        print_status "Minikube is already running"
    else
        print_status "Starting minikube cluster... (this may take several minutes)"
        if minikube start --memory=4096 --cpus=2 --driver=docker; then
            print_status "Minikube started successfully"
        else
            print_error "Failed to start minikube. Check the logs and try again."
            return 1
        fi
    fi
    
    # Enable useful addons
    print_status "Enabling useful minikube addons..."
    minikube addons enable dashboard
    minikube addons enable metrics-server
    minikube addons enable ingress
    
    # Verify cluster
    print_status "Verifying cluster connectivity..."
    if kubectl cluster-info >/dev/null 2>&1; then
        print_status "Cluster is accessible"
        kubectl get nodes
    else
        print_error "Cannot connect to cluster"
        return 1
    fi
}

# Function to setup kubectl configurations
setup_kubectl() {
    print_header "Setting Up kubectl Configuration"
    
    # Create useful aliases
    local shell_rc=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        shell_rc="$HOME/.bashrc"
    fi
    
    if [[ -n "$shell_rc" ]] && [[ -f "$shell_rc" ]]; then
        print_status "Adding kubectl aliases to $shell_rc"
        
        # Check if aliases already exist
        if ! grep -q "alias k=" "$shell_rc"; then
            cat >> "$shell_rc" << 'EOF'

# Kubernetes aliases (added by workshop setup)
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
alias ka='kubectl apply -f'
alias kd='kubectl delete'

# kubectl autocompletion
source <(kubectl completion $(basename $SHELL))
EOF
            print_status "Kubectl aliases and autocompletion added. Please restart your shell or run 'source $shell_rc'"
        else
            print_status "Kubectl aliases already exist in $shell_rc"
        fi
    fi
}

# Function to validate workshop environment
validate_environment() {
    print_header "Validating Workshop Environment"
    
    # Test basic cluster operations
    print_status "Testing basic cluster operations..."
    
    # Create a test pod
    kubectl run test-pod --image=nginx:1.25-alpine --port=8080 --rm --timeout=60s --dry-run=client -o yaml > /tmp/test-pod.yaml
    
    if kubectl apply -f /tmp/test-pod.yaml; then
        print_status "Test pod created successfully"
        
        # Wait for pod to be ready
        if kubectl wait --for=condition=Ready pod/test-pod --timeout=60s; then
            print_status "Test pod is ready"
            
            # Test pod networking
            if kubectl exec test-pod -- curl -s http://localhost:8080 >/dev/null; then
                print_status "Pod networking is working"
            else
                print_warning "Pod networking test failed"
            fi
            
            # Cleanup test pod
            kubectl delete pod test-pod
            print_status "Test pod cleaned up"
        else
            print_error "Test pod failed to become ready"
            kubectl describe pod test-pod
            kubectl delete pod test-pod --force --grace-period=0
        fi
    else
        print_error "Failed to create test pod"
    fi
    
    rm -f /tmp/test-pod.yaml
}

# Function to create workshop directories
setup_workshop_structure() {
    print_header "Setting Up Workshop Directory Structure"
    
    # Create lab output directory
    mkdir -p "${WORKSHOP_ROOT}/lab-output"
    mkdir -p "${WORKSHOP_ROOT}/lab-output/logs"
    mkdir -p "${WORKSHOP_ROOT}/lab-output/manifests"
    
    # Create scripts directory if it doesn't exist
    mkdir -p "${WORKSHOP_ROOT}/scripts"
    
    # Copy validation commands to easy access location
    if [[ -f "${WORKSHOP_ROOT}/lab-files/validation-commands.txt" ]]; then
        cp "${WORKSHOP_ROOT}/lab-files/validation-commands.txt" "${WORKSHOP_ROOT}/scripts/"
        print_status "Validation commands copied to scripts directory"
    fi
    
    print_status "Workshop directory structure created"
}

# Function to show completion message
show_completion_message() {
    print_header "Setup Complete!"
    
    echo -e "${GREEN}✅ Your Kubernetes workshop environment is ready!${NC}\n"
    echo -e "Next steps:"
    echo -e "1. Start with: ${BLUE}cd ${WORKSHOP_ROOT}/01-introduction${NC}"
    echo -e "2. Review the visual guide: ${BLUE}open ${WORKSHOP_ROOT}/kube.html${NC}"
    echo -e "3. Begin hands-on exercises: ${BLUE}cd ${WORKSHOP_ROOT}/03-hands-on${NC}"
    echo -e ""
    echo -e "Useful commands:"
    echo -e "• ${YELLOW}kubectl get nodes${NC} - Check cluster status"
    echo -e "• ${YELLOW}minikube dashboard${NC} - Open Kubernetes dashboard"
    echo -e "• ${YELLOW}minikube status${NC} - Check minikube status"
    echo -e ""
    echo -e "Need help? Check:"
    echo -e "• ${BLUE}${WORKSHOP_ROOT}/02-setup/README.md${NC} - Detailed setup guide"
    echo -e "• ${BLUE}${WORKSHOP_ROOT}/scripts/validation-commands.txt${NC} - Validation commands"
    echo -e "• Setup log: ${BLUE}${LOG_FILE}${NC}"
    echo -e ""
    echo -e "${GREEN}Happy learning! 🚀${NC}"
}

# Main execution
main() {
    print_header "Kubernetes Workshop Environment Setup"
    echo "Log file: $LOG_FILE"
    echo ""
    
    # Initialize log file
    echo "Setup started at $(date)" > "$LOG_FILE"
    
    # Run setup steps
    check_system_requirements
    
    if verify_tools; then
        setup_minikube
        setup_kubectl
        setup_workshop_structure
        validate_environment
        show_completion_message
    else
        print_error "Tool verification failed. Please install missing tools and run the script again."
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Kubernetes Workshop Environment Setup Script"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --check-only   Only check requirements, don't install"
        echo "  --skip-minikube Don't start/configure minikube"
        echo ""
        echo "This script will:"
        echo "1. Check system requirements"
        echo "2. Verify and install kubectl and minikube"
        echo "3. Start and configure minikube cluster"
        echo "4. Set up kubectl aliases and autocompletion"
        echo "5. Validate the environment"
        echo ""
        exit 0
        ;;
    --check-only)
        check_system_requirements
        verify_tools
        exit 0
        ;;
    --skip-minikube)
        check_system_requirements
        verify_tools
        setup_kubectl
        setup_workshop_structure
        show_completion_message
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac