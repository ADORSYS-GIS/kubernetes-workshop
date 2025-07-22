#!/bin/bash

# Validation script for deploying-apps module
# This script validates that students have successfully completed the exercises

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
PASSED=0
FAILED=0

print_header() {
    echo -e "\n${BLUE}===========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===========================================${NC}\n"
}

print_test() {
    echo -e "${YELLOW}Testing:${NC} $1"
}

print_pass() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    ((PASSED++))
}

print_fail() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    ((FAILED++))
}

print_info() {
    echo -e "${BLUE}ℹ️ INFO:${NC} $1"
}

# Test if kubectl is working
test_kubectl() {
    print_test "kubectl connectivity"
    if kubectl cluster-info >/dev/null 2>&1; then
        print_pass "kubectl can connect to cluster"
    else
        print_fail "kubectl cannot connect to cluster"
        return 1
    fi
}

# Test basic pod creation
test_basic_pod() {
    print_test "Basic pod deployment"
    
    # Apply pod if it doesn't exist
    if ! kubectl get pod nginx-pod >/dev/null 2>&1; then
        print_info "Creating nginx-pod for testing..."
        kubectl apply -f ../manifests/my-first-pod.yaml >/dev/null
        sleep 10
    fi
    
    # Check if pod is running
    local pod_phase=$(kubectl get pod nginx-pod -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
    if [[ "$pod_phase" == "Running" ]]; then
        print_pass "nginx-pod is running"
    else
        print_fail "nginx-pod is not running (phase: $pod_phase)"
    fi
    
    # Check if pod is ready
    local pod_ready=$(kubectl get pod nginx-pod -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
    if [[ "$pod_ready" == "True" ]]; then
        print_pass "nginx-pod is ready"
    else
        print_fail "nginx-pod is not ready"
    fi
    
    # Test pod networking
    if kubectl exec nginx-pod -- curl -sf http://localhost:8080 >/dev/null 2>&1; then
        print_pass "nginx-pod is responding to HTTP requests"
    else
        print_fail "nginx-pod is not responding to HTTP requests"
    fi
}

# Test deployment functionality
test_deployment() {
    print_test "Deployment management"
    
    # Apply deployment if it doesn't exist
    if ! kubectl get deployment nginx-deployment >/dev/null 2>&1; then
        print_info "Creating nginx-deployment for testing..."
        kubectl apply -f ../manifests/nginx-deployment.yaml >/dev/null
        kubectl rollout status deployment/nginx-deployment --timeout=60s >/dev/null
    fi
    
    # Check deployment status
    local deployment_ready=$(kubectl get deployment nginx-deployment -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    local deployment_desired=$(kubectl get deployment nginx-deployment -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
    
    if [[ "$deployment_ready" == "$deployment_desired" ]] && [[ "$deployment_ready" -gt "0" ]]; then
        print_pass "nginx-deployment has all replicas ready ($deployment_ready/$deployment_desired)"
    else
        print_fail "nginx-deployment replicas not ready ($deployment_ready/$deployment_desired)"
    fi
    
    # Check if ReplicaSet exists
    local rs_count=$(kubectl get rs -l app=nginx --no-headers 2>/dev/null | wc -l || echo "0")
    if [[ "$rs_count" -gt "0" ]]; then
        print_pass "ReplicaSet created for nginx-deployment"
    else
        print_fail "No ReplicaSet found for nginx-deployment"
    fi
}

# Test scaling functionality
test_scaling() {
    print_test "Deployment scaling"
    
    if kubectl get deployment nginx-deployment >/dev/null 2>&1; then
        # Scale to 4 replicas
        print_info "Scaling deployment to 4 replicas..."
        kubectl scale deployment nginx-deployment --replicas=4 >/dev/null
        kubectl rollout status deployment/nginx-deployment --timeout=60s >/dev/null
        
        local current_replicas=$(kubectl get deployment nginx-deployment -o jsonpath='{.status.readyReplicas}')
        if [[ "$current_replicas" == "4" ]]; then
            print_pass "Successfully scaled deployment to 4 replicas"
            
            # Scale back to 3
            kubectl scale deployment nginx-deployment --replicas=3 >/dev/null
        else
            print_fail "Failed to scale deployment (current: $current_replicas, expected: 4)"
        fi
    else
        print_fail "nginx-deployment not found for scaling test"
    fi
}

# Test resource limits and security
test_resource_security() {
    print_test "Resource limits and security contexts"
    
    # Check if pods have resource limits
    local pods_with_limits=$(kubectl get pods -l app=nginx -o jsonpath='{range .items[*]}{.spec.containers[0].resources.limits}{"\n"}{end}' 2>/dev/null | grep -v "^$" | wc -l || echo "0")
    
    if [[ "$pods_with_limits" -gt "0" ]]; then
        print_pass "Pods have resource limits configured"
    else
        print_fail "Pods do not have resource limits configured"
    fi
    
    # Check security context
    local pods_with_security=$(kubectl get pods -l app=nginx -o jsonpath='{range .items[*]}{.spec.containers[0].securityContext.runAsNonRoot}{"\n"}{end}' 2>/dev/null | grep "true" | wc -l || echo "0")
    
    if [[ "$pods_with_security" -gt "0" ]]; then
        print_pass "Pods have security contexts configured"
    else
        print_fail "Pods do not have proper security contexts"
    fi
}

# Test health checks
test_health_checks() {
    print_test "Health check configuration"
    
    # Check for liveness probes
    local pods_with_liveness=$(kubectl get pods -l app=nginx -o jsonpath='{range .items[*]}{.spec.containers[0].livenessProbe}{"\n"}{end}' 2>/dev/null | grep -v "^$" | wc -l || echo "0")
    
    if [[ "$pods_with_liveness" -gt "0" ]]; then
        print_pass "Pods have liveness probes configured"
    else
        print_fail "Pods do not have liveness probes configured"
    fi
    
    # Check for readiness probes
    local pods_with_readiness=$(kubectl get pods -l app=nginx -o jsonpath='{range .items[*]}{.spec.containers[0].readinessProbe}{"\n"}{end}' 2>/dev/null | grep -v "^$" | wc -l || echo "0")
    
    if [[ "$pods_with_readiness" -gt "0" ]]; then
        print_pass "Pods have readiness probes configured"
    else
        print_fail "Pods do not have readiness probes configured"
    fi
}

# Test rollout functionality
test_rollouts() {
    print_test "Rollout and rollback functionality"
    
    if kubectl get deployment nginx-deployment >/dev/null 2>&1; then
        # Get initial revision
        local initial_revision=$(kubectl rollout history deployment/nginx-deployment --output=jsonpath='{.items[-1:].metadata.name}' 2>/dev/null || echo "1")
        
        # Trigger a rollout
        print_info "Testing rollout with image update..."
        kubectl set image deployment/nginx-deployment nginx=nginx:1.25-alpine >/dev/null 2>&1 || true
        kubectl rollout status deployment/nginx-deployment --timeout=60s >/dev/null 2>&1 || true
        
        # Check if rollout history exists
        local history_count=$(kubectl rollout history deployment/nginx-deployment 2>/dev/null | grep -c "nginx-deployment" || echo "0")
        if [[ "$history_count" -gt "0" ]]; then
            print_pass "Deployment rollout history is available"
        else
            print_fail "No rollout history found"
        fi
        
        # Test rollback capability (just check if command works)
        if kubectl rollout undo deployment/nginx-deployment --dry-run=client >/dev/null 2>&1; then
            print_pass "Rollback command is functional"
        else
            print_fail "Rollback command failed"
        fi
    else
        print_fail "nginx-deployment not found for rollout test"
    fi
}

# Test advanced features if available
test_advanced_features() {
    print_test "Advanced deployment features"
    
    # Check for Pod Disruption Budget
    if kubectl get pdb nginx-pdb >/dev/null 2>&1; then
        print_pass "Pod Disruption Budget is configured"
    else
        print_info "Pod Disruption Budget not found (optional for basic module)"
    fi
    
    # Check for ConfigMaps
    local configmap_count=$(kubectl get configmaps --no-headers 2>/dev/null | wc -l || echo "0")
    if [[ "$configmap_count" -gt "0" ]]; then
        print_pass "ConfigMaps are present"
    else
        print_info "No ConfigMaps found (may be covered in later modules)"
    fi
}

# Cleanup function
cleanup_test_resources() {
    print_test "Cleanup validation"
    
    print_info "This script does not automatically clean up resources."
    print_info "To clean up, run: kubectl delete -f ../manifests/"
    print_info "Or clean up specific resources:"
    echo "  kubectl delete pod nginx-pod"
    echo "  kubectl delete deployment nginx-deployment"
    echo "  kubectl delete pdb nginx-pdb"
    echo "  kubectl delete configmap nginx-config"
}

# Main execution
main() {
    print_header "Deploying Apps Module Validation"
    
    # Run all tests
    test_kubectl
    test_basic_pod
    test_deployment
    test_scaling
    test_resource_security
    test_health_checks
    test_rollouts
    test_advanced_features
    cleanup_test_resources
    
    # Summary
    print_header "Validation Summary"
    echo -e "Tests passed: ${GREEN}$PASSED${NC}"
    echo -e "Tests failed: ${RED}$FAILED${NC}"
    
    if [[ $FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}🎉 All tests passed! You've successfully completed the deploying-apps module.${NC}"
        echo -e "${GREEN}You can now proceed to the services-ingress module.${NC}"
        exit 0
    else
        echo -e "\n${YELLOW}⚠️  Some tests failed. Review the issues above and retry the exercises.${NC}"
        echo -e "${YELLOW}Check the README.md for detailed instructions and troubleshooting.${NC}"
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Deploying Apps Module Validation Script"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --cleanup      Clean up test resources"
        echo "  --verbose      Show detailed output"
        echo ""
        echo "This script validates successful completion of the deploying-apps module."
        exit 0
        ;;
    --cleanup)
        kubectl delete -f ../manifests/ 2>/dev/null || true
        echo "Cleanup completed."
        exit 0
        ;;
    --verbose)
        set -x
        main
        ;;
    "")
        main
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac