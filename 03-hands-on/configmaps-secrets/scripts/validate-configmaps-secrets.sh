#!/bin/bash

# Validation script for configmaps-secrets module
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

# Test ConfigMaps
test_configmaps() {
    print_test "ConfigMap functionality"
    
    # Check basic configmap
    if kubectl get configmap app-config >/dev/null 2>&1; then
        local config_data=$(kubectl get configmap app-config -o jsonpath='{.data}')
        if [[ -n "$config_data" ]]; then
            print_pass "ConfigMap has data"
        else
            print_fail "ConfigMap exists but has no data"
        fi
    else
        print_fail "ConfigMap 'app-config' not found"
    fi
    
    # Check configmap volume mount
    if kubectl get pod config-demo >/dev/null 2>&1; then
        local volume_count=$(kubectl get pod config-demo -o jsonpath='{.spec.volumes}' | jq length 2>/dev/null || echo "0")
        if [[ "$volume_count" -gt "0" ]]; then
            print_pass "Pod has volumes configured"
        else
            print_fail "Pod missing volume mounts"
        fi
    else
        print_fail "Demo pod not found"
    fi
    
    # Test environment variable injection
    if kubectl get pod config-demo >/dev/null 2>&1; then
        local env_vars=$(kubectl get pod config-demo -o jsonpath='{.spec.containers[0].env}' | jq length 2>/dev/null || echo "0")
        if [[ "$env_vars" -gt "0" ]]; then
            print_pass "Pod has environment variables from ConfigMap"
        else
            print_fail "Pod missing environment variables"
        fi
    fi
}

# Test Secrets
test_secrets() {
    print_test "Secret functionality"
    
    # Check basic secret
    if kubectl get secret app-secret >/dev/null 2>&1; then
        local secret_type=$(kubectl get secret app-secret -o jsonpath='{.type}')
        if [[ "$secret_type" == "Opaque" ]]; then
            print_pass "Secret has correct type"
        else
            print_fail "Secret has incorrect type: $secret_type"
        fi
    else
        print_fail "Secret 'app-secret' not found"
    fi
    
    # Check TLS secret
    if kubectl get secret tls-secret >/dev/null 2>&1; then
        local secret_type=$(kubectl get secret tls-secret -o jsonpath='{.type}')
        if [[ "$secret_type" == "kubernetes.io/tls" ]]; then
            print_pass "TLS Secret has correct type"
            
            # Check if it has required keys
            local tls_crt=$(kubectl get secret tls-secret -o jsonpath='{.data.tls\.crt}')
            local tls_key=$(kubectl get secret tls-secret -o jsonpath='{.data.tls\.key}')
            
            if [[ -n "$tls_crt" ]] && [[ -n "$tls_key" ]]; then
                print_pass "TLS Secret has certificate and key"
            else
                print_fail "TLS Secret missing certificate or key"
            fi
        else
            print_fail "TLS Secret has incorrect type: $secret_type"
        fi
    else
        print_fail "TLS Secret not found"
    fi
    
    # Check secret mount
    if kubectl get pod secret-demo >/dev/null 2>&1; then
        local secret_mounts=$(kubectl get pod secret-demo -o jsonpath='{.spec.containers[0].volumeMounts}' | jq length 2>/dev/null || echo "0")
        if [[ "$secret_mounts" -gt "0" ]]; then
            print_pass "Pod has secret volume mounts"
        else
            print_fail "Pod missing secret volume mounts"
        fi
    else
        print_fail "Secret demo pod not found"
    fi
}

# Test configuration management patterns
test_config_patterns() {
    print_test "Configuration management patterns"
    
    # Check multi-env configuration
    local envs=("development" "staging" "production")
    local env_count=0
    
    for env in "${envs[@]}"; do
        if kubectl get configmap ${env}-config >/dev/null 2>&1; then
            ((env_count++))
        fi
    done
    
    if [[ "$env_count" -ge "2" ]]; then
        print_pass "Multiple environment configurations exist ($env_count environments)"
    else
        print_fail "Insufficient environment configurations ($env_count found)"
    fi
    
    # Check immutable ConfigMap
    if kubectl get configmap immutable-config >/dev/null 2>&1; then
        local immutable=$(kubectl get configmap immutable-config -o jsonpath='{.immutable}')
        if [[ "$immutable" == "true" ]]; then
            print_pass "Immutable ConfigMap configured correctly"
        else
            print_fail "ConfigMap is not immutable"
        fi
    else
        print_fail "Immutable ConfigMap not found"
    fi
}

# Test secret security
test_secret_security() {
    print_test "Secret security practices"
    
    # Check for secrets in environment variables (anti-pattern)
    local pods_with_secret_env=0
    
    # This is a basic check - in real scenarios you'd want more sophisticated detection
    if kubectl get pods -o yaml | grep -q "secretKeyRef"; then
        print_pass "Found pods using secretKeyRef (good practice)"
    else
        print_fail "No pods found using secretKeyRef for secrets"
    fi
    
    # Check ServiceAccount token automounting
    if kubectl get pod secret-demo >/dev/null 2>&1; then
        local automount=$(kubectl get pod secret-demo -o jsonpath='{.spec.automountServiceAccountToken}')
        if [[ "$automount" == "false" ]]; then
            print_pass "ServiceAccount token automounting disabled"
        else
            print_fail "ServiceAccount token automounting not disabled"
        fi
    fi
}

# Test data validation
test_data_validation() {
    print_test "Data validation and integrity"
    
    # Test config file syntax validation
    if kubectl exec config-demo -- cat /etc/config/app.properties >/dev/null 2>&1; then
        print_pass "Configuration files accessible in container"
    else
        print_fail "Cannot access configuration files in container"
    fi
    
    # Test secret data accessibility
    if kubectl exec secret-demo -- ls /etc/secrets/ >/dev/null 2>&1; then
        print_pass "Secret files accessible in container"
        
        # Check secret file permissions
        local perms=$(kubectl exec secret-demo -- stat -c "%a" /etc/secrets/username 2>/dev/null || echo "000")
        if [[ "$perms" -le "644" ]]; then
            print_pass "Secret files have appropriate permissions ($perms)"
        else
            print_fail "Secret files have overly permissive permissions ($perms)"
        fi
    else
        print_fail "Cannot access secret files in container"
    fi
}

# Main execution
main() {
    print_header "ConfigMaps and Secrets Module Validation"
    
    test_configmaps
    test_secrets
    test_config_patterns
    test_secret_security
    test_data_validation
    
    # Summary
    print_header "Validation Summary"
    echo -e "Tests passed: ${GREEN}$PASSED${NC}"
    echo -e "Tests failed: ${RED}$FAILED${NC}"
    
    if [[ $FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}🎉 All tests passed! ConfigMaps and Secrets module completed successfully.${NC}"
        exit 0
    else
        echo -e "\n${YELLOW}⚠️  Some tests failed. Review the issues above.${NC}"
        exit 1
    fi
}

# Handle arguments
case "${1:-}" in
    --help|-h)
        echo "ConfigMaps and Secrets Module Validation Script"
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