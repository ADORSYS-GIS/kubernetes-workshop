#!/bin/bash

# Validation script for security module
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Test Pod Security Standards
test_pod_security_standards() {
    print_test "Pod Security Standards"
    
    # Check namespace labels for PSS
    local namespaces=("privileged-workloads" "baseline-workloads" "restricted-workloads")
    local pss_count=0
    
    for ns in "${namespaces[@]}"; do
        if kubectl get namespace "$ns" >/dev/null 2>&1; then
            local pss_label=$(kubectl get namespace "$ns" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}')
            if [[ -n "$pss_label" ]]; then
                print_pass "Namespace $ns has PSS enforcement: $pss_label"
                ((pss_count++))
            else
                print_fail "Namespace $ns missing PSS labels"
            fi
        else
            print_fail "Namespace $ns not found"
        fi
    done
    
    if [[ "$pss_count" -ge "2" ]]; then
        print_pass "Multiple Pod Security Standards implemented"
    else
        print_fail "Insufficient Pod Security Standards implementation"
    fi
    
    # Test restricted pod compliance
    if kubectl get pod restricted-pod -n restricted-workloads >/dev/null 2>&1; then
        local run_as_non_root=$(kubectl get pod restricted-pod -n restricted-workloads -o jsonpath='{.spec.securityContext.runAsNonRoot}')
        if [[ "$run_as_non_root" == "true" ]]; then
            print_pass "Restricted pod runs as non-root"
        else
            print_fail "Restricted pod not configured for non-root"
        fi
        
        local read_only_fs=$(kubectl get pod restricted-pod -n restricted-workloads -o jsonpath='{.spec.containers[0].securityContext.readOnlyRootFilesystem}')
        if [[ "$read_only_fs" == "true" ]]; then
            print_pass "Restricted pod has read-only root filesystem"
        else
            print_fail "Restricted pod missing read-only root filesystem"
        fi
    else
        print_fail "Restricted pod not found"
    fi
}

# Test RBAC
test_rbac() {
    print_test "Role-Based Access Control (RBAC)"
    
    # Check service accounts
    local service_accounts=("pod-reader" "deployment-manager" "cluster-admin-limited")
    local sa_count=0
    
    for sa in "${service_accounts[@]}"; do
        if kubectl get serviceaccount "$sa" >/dev/null 2>&1; then
            print_pass "ServiceAccount $sa exists"
            ((sa_count++))
        else
            print_fail "ServiceAccount $sa not found"
        fi
    done
    
    # Test permissions
    local can_read_pods=$(kubectl auth can-i get pods --as=system:serviceaccount:default:pod-reader 2>/dev/null || echo "no")
    if [[ "$can_read_pods" == "yes" ]]; then
        print_pass "pod-reader can read pods"
    else
        print_fail "pod-reader cannot read pods"
    fi
    
    local cannot_create_deployments=$(kubectl auth can-i create deployments --as=system:serviceaccount:default:pod-reader 2>/dev/null || echo "no")
    if [[ "$cannot_create_deployments" == "no" ]]; then
        print_pass "pod-reader correctly denied deployment creation"
    else
        print_fail "pod-reader has excessive permissions"
    fi
    
    local can_manage_deployments=$(kubectl auth can-i create deployments --as=system:serviceaccount:default:deployment-manager 2>/dev/null || echo "no")
    if [[ "$can_manage_deployments" == "yes" ]]; then
        print_pass "deployment-manager can create deployments"
    else
        print_fail "deployment-manager cannot create deployments"
    fi
}

# Test Network Policies
test_network_policies() {
    print_test "Network Policies"
    
    # Check if network policies exist
    local policies_count=$(kubectl get networkpolicies --all-namespaces --no-headers 2>/dev/null | wc -l || echo "0")
    if [[ "$policies_count" -gt "0" ]]; then
        print_pass "Network policies configured ($policies_count found)"
    else
        print_fail "No network policies found"
    fi
    
    # Check specific policies
    local key_policies=("database-default-deny" "database-allow-backend" "backend-policy" "frontend-policy")
    local policy_count=0
    
    for policy in "${key_policies[@]}"; do
        if kubectl get networkpolicy "$policy" --all-namespaces >/dev/null 2>&1; then
            ((policy_count++))
        fi
    done
    
    if [[ "$policy_count" -ge "3" ]]; then
        print_pass "Key network policies implemented ($policy_count/4)"
    else
        print_fail "Missing key network policies ($policy_count/4 found)"
    fi
    
    # Test namespace segmentation
    local namespaces=("frontend" "backend" "database")
    local ns_count=0
    
    for ns in "${namespaces[@]}"; do
        if kubectl get namespace "$ns" >/dev/null 2>&1; then
            ((ns_count++))
        fi
    done
    
    if [[ "$ns_count" -eq "3" ]]; then
        print_pass "Multi-tier namespace architecture implemented"
    else
        print_fail "Incomplete multi-tier namespace architecture ($ns_count/3 found)"
    fi
}

# Test Security Contexts
test_security_contexts() {
    print_test "Security Contexts"
    
    # Find pods with security contexts
    local pods_with_security_context=0
    
    # Check if any pods have security contexts
    if kubectl get pods -o yaml | grep -q "securityContext"; then
        print_pass "Found pods with security contexts"
        ((pods_with_security_context++))
    else
        print_fail "No pods found with security contexts"
    fi
    
    # Check for non-root execution
    if kubectl get pods -o yaml | grep -q "runAsNonRoot: true"; then
        print_pass "Found pods configured to run as non-root"
    else
        print_fail "No pods configured to run as non-root"
    fi
    
    # Check for read-only root filesystem
    if kubectl get pods -o yaml | grep -q "readOnlyRootFilesystem: true"; then
        print_pass "Found pods with read-only root filesystem"
    else
        print_fail "No pods with read-only root filesystem found"
    fi
    
    # Check for dropped capabilities
    if kubectl get pods -o yaml | grep -A 5 "capabilities:" | grep -q "drop:"; then
        print_pass "Found pods with dropped capabilities"
    else
        print_fail "No pods with dropped capabilities found"
    fi
}

# Test Image Security
test_image_security() {
    print_test "Image Security"
    
    # Check for pinned image versions (not using latest)
    local latest_images=$(kubectl get pods -o yaml | grep "image:" | grep -c ":latest" || echo "0")
    if [[ "$latest_images" -eq "0" ]]; then
        print_pass "No pods using ':latest' tag"
    else
        print_fail "$latest_images pods using ':latest' tag"
    fi
    
    # Check for official/trusted images
    local nginx_images=$(kubectl get pods -o yaml | grep "image:" | grep -c "nginx:" || echo "0")
    local alpine_images=$(kubectl get pods -o yaml | grep "image:" | grep -c "alpine" || echo "0")
    
    if [[ "$nginx_images" -gt "0" ]] || [[ "$alpine_images" -gt "0" ]]; then
        print_pass "Using trusted base images (nginx/alpine)"
    else
        print_fail "No trusted base images detected"
    fi
    
    # Check for image digests (if available)
    local digest_images=$(kubectl get pods -o yaml | grep "image:" | grep -c "@sha256:" || echo "0")
    if [[ "$digest_images" -gt "0" ]]; then
        print_pass "Found $digest_images images using digest pinning"
    else
        print_fail "No images using digest pinning (recommended for production)"
    fi
}

# Test Resource Security
test_resource_security() {
    print_test "Resource Security"
    
    # Check for resource limits
    local pods_with_limits=$(kubectl get pods -o yaml | grep -c "limits:" || echo "0")
    if [[ "$pods_with_limits" -gt "0" ]]; then
        print_pass "Found pods with resource limits"
    else
        print_fail "No pods with resource limits found"
    fi
    
    # Check for resource requests
    local pods_with_requests=$(kubectl get pods -o yaml | grep -c "requests:" || echo "0")
    if [[ "$pods_with_requests" -gt "0" ]]; then
        print_pass "Found pods with resource requests"
    else
        print_fail "No pods with resource requests found"
    fi
    
    # Check for security policies (if OPA Gatekeeper is available)
    if kubectl get constrainttemplates >/dev/null 2>&1; then
        local constraint_count=$(kubectl get constrainttemplates --no-headers | wc -l || echo "0")
        if [[ "$constraint_count" -gt "0" ]]; then
            print_pass "OPA Gatekeeper constraint templates found ($constraint_count)"
        else
            print_fail "No OPA Gatekeeper constraint templates found"
        fi
    fi
}

# Main execution
main() {
    print_header "Security Module Validation"
    
    test_pod_security_standards
    test_rbac
    test_network_policies
    test_security_contexts
    test_image_security
    test_resource_security
    
    # Summary
    print_header "Validation Summary"
    echo -e "Tests passed: ${GREEN}$PASSED${NC}"
    echo -e "Tests failed: ${RED}$FAILED${NC}"
    
    if [[ $FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}🛡️  All tests passed! Security module completed successfully.${NC}"
        echo -e "${GREEN}Your Kubernetes environment follows security best practices!${NC}"
        exit 0
    else
        echo -e "\n${YELLOW}⚠️  Some tests failed. Review the security issues above.${NC}"
        echo -e "${YELLOW}Security is critical - please address these issues before production deployment.${NC}"
        exit 1
    fi
}

# Handle arguments
case "${1:-}" in
    --help|-h)
        echo "Security Module Validation Script"
        echo "Usage: $0 [OPTIONS]"
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --cleanup      Clean up test resources"
        echo "  --audit        Run security audit only"
        exit 0
        ;;
    --cleanup)
        # Cleanup security test resources
        kubectl delete namespace privileged-workloads baseline-workloads restricted-workloads frontend backend database 2>/dev/null || true
        kubectl delete -f ../manifests/ 2>/dev/null || true
        echo "Security test cleanup completed."
        exit 0
        ;;
    --audit)
        echo "Running security audit only..."
        test_security_contexts
        test_image_security
        test_resource_security
        exit 0
        ;;
    "")
        main
        ;;
    *)
        echo "Unknown option: $1"
        exit 1
        ;;
esac