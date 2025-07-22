#!/bin/bash

# Validation script for services-ingress module
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

# Test Service types
test_services() {
    print_test "Service types and connectivity"
    
    # Check ClusterIP service
    if kubectl get service nginx-clusterip >/dev/null 2>&1; then
        local cluster_ip=$(kubectl get service nginx-clusterip -o jsonpath='{.spec.clusterIP}')
        if [[ "$cluster_ip" != "<none>" ]] && [[ "$cluster_ip" != "" ]]; then
            print_pass "ClusterIP service has valid IP: $cluster_ip"
        else
            print_fail "ClusterIP service has invalid IP"
        fi
    else
        print_fail "ClusterIP service not found"
    fi
    
    # Check NodePort service
    if kubectl get service nginx-nodeport >/dev/null 2>&1; then
        local node_port=$(kubectl get service nginx-nodeport -o jsonpath='{.spec.ports[0].nodePort}')
        if [[ "$node_port" -gt 30000 ]] && [[ "$node_port" -lt 32768 ]]; then
            print_pass "NodePort service has valid port: $node_port"
        else
            print_fail "NodePort service has invalid port range"
        fi
    else
        print_fail "NodePort service not found"
    fi
}

# Test DNS resolution
test_dns() {
    print_test "Service discovery and DNS"
    
    # Test DNS resolution
    if kubectl run dns-test --image=busybox:1.35 --rm --restart=Never --timeout=30s -- nslookup nginx-clusterip >/dev/null 2>&1; then
        print_pass "DNS resolution working for services"
    else
        print_fail "DNS resolution failed"
    fi
    
    # Test service connectivity
    if kubectl run connectivity-test --image=busybox:1.35 --rm --restart=Never --timeout=30s -- wget -qO- http://nginx-clusterip --timeout=5 >/dev/null 2>&1; then
        print_pass "Service connectivity working"
    else
        print_fail "Service connectivity failed"
    fi
}

# Test Ingress
test_ingress() {
    print_test "Ingress configuration"
    
    # Check if ingress exists
    if kubectl get ingress web-ingress >/dev/null 2>&1; then
        print_pass "Ingress resource exists"
        
        # Check ingress rules
        local rules_count=$(kubectl get ingress web-ingress -o jsonpath='{.spec.rules}' | jq length 2>/dev/null || echo "0")
        if [[ "$rules_count" -gt "0" ]]; then
            print_pass "Ingress has routing rules configured"
        else
            print_fail "Ingress has no routing rules"
        fi
    else
        print_fail "Ingress resource not found"
    fi
    
    # Check ingress controller
    if kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller >/dev/null 2>&1; then
        local controller_ready=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}')
        if [[ "$controller_ready" == "True" ]]; then
            print_pass "Ingress controller is ready"
        else
            print_fail "Ingress controller is not ready"
        fi
    else
        print_fail "Ingress controller not found"
    fi
}

# Test Network Policies
test_network_policies() {
    print_test "Network policies"
    
    # Check if network policies exist
    local policies_count=$(kubectl get networkpolicies --all-namespaces --no-headers 2>/dev/null | wc -l || echo "0")
    if [[ "$policies_count" -gt "0" ]]; then
        print_pass "Network policies are configured ($policies_count found)"
        
        # Test policy enforcement (if possible)
        # This is a basic test - more sophisticated testing would require controlled environments
        if kubectl get networkpolicy -n production >/dev/null 2>&1; then
            print_pass "Production namespace has network policies"
        else
            print_fail "Production namespace missing network policies"
        fi
    else
        print_fail "No network policies found"
    fi
}

# Test TLS/SSL
test_tls() {
    print_test "TLS configuration"
    
    # Check TLS secrets
    if kubectl get secret myapp-tls >/dev/null 2>&1; then
        print_pass "TLS secret exists"
        
        # Verify secret has required data
        local cert_data=$(kubectl get secret myapp-tls -o jsonpath='{.data.tls\.crt}')
        local key_data=$(kubectl get secret myapp-tls -o jsonpath='{.data.tls\.key}')
        
        if [[ -n "$cert_data" ]] && [[ -n "$key_data" ]]; then
            print_pass "TLS secret has certificate and key data"
        else
            print_fail "TLS secret missing certificate or key data"
        fi
    else
        print_fail "TLS secret not found"
    fi
    
    # Check TLS ingress configuration
    if kubectl get ingress web-ingress-tls >/dev/null 2>&1; then
        local tls_hosts=$(kubectl get ingress web-ingress-tls -o jsonpath='{.spec.tls[0].hosts}' | jq length 2>/dev/null || echo "0")
        if [[ "$tls_hosts" -gt "0" ]]; then
            print_pass "TLS ingress has host configurations"
        else
            print_fail "TLS ingress missing host configurations"
        fi
    else
        print_fail "TLS ingress not found"
    fi
}

# Test load balancing
test_load_balancing() {
    print_test "Load balancing functionality"
    
    # Check service endpoints
    if kubectl get endpoints frontend-service >/dev/null 2>&1; then
        local endpoint_count=$(kubectl get endpoints frontend-service -o jsonpath='{.subsets[0].addresses}' | jq length 2>/dev/null || echo "0")
        if [[ "$endpoint_count" -gt "1" ]]; then
            print_pass "Service has multiple endpoints for load balancing ($endpoint_count endpoints)"
        else
            print_fail "Service has insufficient endpoints for load balancing"
        fi
    else
        print_fail "Service endpoints not found"
    fi
}

# Main execution
main() {
    print_header "Services and Ingress Module Validation"
    
    test_services
    test_dns
    test_ingress
    test_network_policies
    test_tls
    test_load_balancing
    
    # Summary
    print_header "Validation Summary"
    echo -e "Tests passed: ${GREEN}$PASSED${NC}"
    echo -e "Tests failed: ${RED}$FAILED${NC}"
    
    if [[ $FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}🎉 All tests passed! Services and Ingress module completed successfully.${NC}"
        exit 0
    else
        echo -e "\n${YELLOW}⚠️  Some tests failed. Review the issues above.${NC}"
        exit 1
    fi
}

# Handle arguments
case "${1:-}" in
    --help|-h)
        echo "Services and Ingress Module Validation Script"
        echo "Usage: $0 [OPTIONS]"
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --cleanup      Clean up test resources"
        exit 0
        ;;
    --cleanup)
        kubectl delete -f ../manifests/ 2>/dev/null || true
        echo "Cleanup completed."
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