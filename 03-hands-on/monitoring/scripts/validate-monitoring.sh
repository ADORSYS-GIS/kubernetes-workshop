#!/bin/bash

# Validation script for monitoring module
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

# Test Prometheus
test_prometheus() {
    print_test "Prometheus metrics collection"
    
    # Check Prometheus deployment
    if kubectl get deployment prometheus -n monitoring >/dev/null 2>&1; then
        local ready_replicas=$(kubectl get deployment prometheus -n monitoring -o jsonpath='{.status.readyReplicas}' || echo "0")
        local desired_replicas=$(kubectl get deployment prometheus -n monitoring -o jsonpath='{.spec.replicas}' || echo "1")
        
        if [[ "$ready_replicas" == "$desired_replicas" ]] && [[ "$ready_replicas" -gt "0" ]]; then
            print_pass "Prometheus deployment is ready ($ready_replicas/$desired_replicas)"
        else
            print_fail "Prometheus deployment not ready ($ready_replicas/$desired_replicas)"
        fi
    else
        print_fail "Prometheus deployment not found"
    fi
    
    # Check Prometheus service
    if kubectl get service prometheus -n monitoring >/dev/null 2>&1; then
        local service_port=$(kubectl get service prometheus -n monitoring -o jsonpath='{.spec.ports[0].port}')
        if [[ "$service_port" == "9090" ]]; then
            print_pass "Prometheus service configured correctly"
        else
            print_fail "Prometheus service has incorrect port: $service_port"
        fi
    else
        print_fail "Prometheus service not found"
    fi
    
    # Test Prometheus configuration
    if kubectl get configmap prometheus-config -n monitoring >/dev/null 2>&1; then
        local config_data=$(kubectl get configmap prometheus-config -n monitoring -o jsonpath='{.data}')
        if [[ -n "$config_data" ]]; then
            print_pass "Prometheus configuration exists"
            
            # Check if configuration has scrape configs
            if kubectl get configmap prometheus-config -n monitoring -o yaml | grep -q "scrape_configs"; then
                print_pass "Prometheus has scrape configurations"
            else
                print_fail "Prometheus missing scrape configurations"
            fi
        else
            print_fail "Prometheus configuration is empty"
        fi
    else
        print_fail "Prometheus configuration not found"
    fi
}

# Test Grafana
test_grafana() {
    print_test "Grafana visualization"
    
    # Check Grafana deployment
    if kubectl get deployment grafana -n monitoring >/dev/null 2>&1; then
        local ready_replicas=$(kubectl get deployment grafana -n monitoring -o jsonpath='{.status.readyReplicas}' || echo "0")
        local desired_replicas=$(kubectl get deployment grafana -n monitoring -o jsonpath='{.spec.replicas}' || echo "1")
        
        if [[ "$ready_replicas" == "$desired_replicas" ]] && [[ "$ready_replicas" -gt "0" ]]; then
            print_pass "Grafana deployment is ready ($ready_replicas/$desired_replicas)"
        else
            print_fail "Grafana deployment not ready ($ready_replicas/$desired_replicas)"
        fi
    else
        print_fail "Grafana deployment not found"
    fi
    
    # Check Grafana service
    if kubectl get service grafana -n monitoring >/dev/null 2>&1; then
        local service_port=$(kubectl get service grafana -n monitoring -o jsonpath='{.spec.ports[0].port}')
        if [[ "$service_port" == "3000" ]]; then
            print_pass "Grafana service configured correctly"
        else
            print_fail "Grafana service has incorrect port: $service_port"
        fi
    else
        print_fail "Grafana service not found"
    fi
    
    # Check for dashboard configurations
    if kubectl get configmap grafana-dashboards-config -n monitoring >/dev/null 2>&1; then
        print_pass "Grafana dashboard configuration exists"
    else
        print_fail "Grafana dashboard configuration not found"
    fi
}

# Test Logging Stack
test_logging() {
    print_test "Centralized logging"
    
    # Check Elasticsearch
    if kubectl get deployment elasticsearch -n monitoring >/dev/null 2>&1; then
        local es_ready=$(kubectl get deployment elasticsearch -n monitoring -o jsonpath='{.status.readyReplicas}' || echo "0")
        if [[ "$es_ready" -gt "0" ]]; then
            print_pass "Elasticsearch is running"
        else
            print_fail "Elasticsearch is not ready"
        fi
    else
        print_fail "Elasticsearch deployment not found"
    fi
    
    # Check Kibana
    if kubectl get deployment kibana -n monitoring >/dev/null 2>&1; then
        local kibana_ready=$(kubectl get deployment kibana -n monitoring -o jsonpath='{.status.readyReplicas}' || echo "0")
        if [[ "$kibana_ready" -gt "0" ]]; then
            print_pass "Kibana is running"
        else
            print_fail "Kibana is not ready"
        fi
    else
        print_fail "Kibana deployment not found"
    fi
    
    # Check Fluent Bit DaemonSet
    if kubectl get daemonset fluent-bit -n monitoring >/dev/null 2>&1; then
        local desired_nodes=$(kubectl get daemonset fluent-bit -n monitoring -o jsonpath='{.status.desiredNumberScheduled}' || echo "0")
        local ready_nodes=$(kubectl get daemonset fluent-bit -n monitoring -o jsonpath='{.status.numberReady}' || echo "0")
        
        if [[ "$ready_nodes" == "$desired_nodes" ]] && [[ "$ready_nodes" -gt "0" ]]; then
            print_pass "Fluent Bit is running on all nodes ($ready_nodes/$desired_nodes)"
        else
            print_fail "Fluent Bit not running on all nodes ($ready_nodes/$desired_nodes)"
        fi
    else
        print_fail "Fluent Bit DaemonSet not found"
    fi
    
    # Check log collection configuration
    if kubectl get configmap fluent-bit-config -n monitoring >/dev/null 2>&1; then
        if kubectl get configmap fluent-bit-config -n monitoring -o yaml | grep -q "INPUT"; then
            print_pass "Fluent Bit has input configuration"
        else
            print_fail "Fluent Bit missing input configuration"
        fi
    else
        print_fail "Fluent Bit configuration not found"
    fi
}

# Test AlertManager
test_alerting() {
    print_test "Alerting system"
    
    # Check AlertManager
    if kubectl get deployment alertmanager -n monitoring >/dev/null 2>&1; then
        local am_ready=$(kubectl get deployment alertmanager -n monitoring -o jsonpath='{.status.readyReplicas}' || echo "0")
        if [[ "$am_ready" -gt "0" ]]; then
            print_pass "AlertManager is running"
        else
            print_fail "AlertManager is not ready"
        fi
    else
        print_fail "AlertManager deployment not found"
    fi
    
    # Check alert rules in Prometheus config
    if kubectl get configmap prometheus-config -n monitoring >/dev/null 2>&1; then
        if kubectl get configmap prometheus-config -n monitoring -o yaml | grep -q "alert_rules"; then
            print_pass "Prometheus has alert rules configured"
        else
            print_fail "Prometheus missing alert rules"
        fi
    fi
    
    # Check AlertManager configuration
    if kubectl get configmap alertmanager-config -n monitoring >/dev/null 2>&1; then
        if kubectl get configmap alertmanager-config -n monitoring -o yaml | grep -q "receivers"; then
            print_pass "AlertManager has receiver configuration"
        else
            print_fail "AlertManager missing receiver configuration"
        fi
    else
        print_fail "AlertManager configuration not found"
    fi
}

# Test Application Monitoring
test_application_monitoring() {
    print_test "Application monitoring"
    
    # Check for instrumented applications
    if kubectl get pods -o yaml | grep -q "prometheus.io/scrape"; then
        print_pass "Found pods with Prometheus scraping annotations"
    else
        print_fail "No pods with Prometheus scraping annotations found"
    fi
    
    # Check sample application
    if kubectl get deployment sample-app >/dev/null 2>&1; then
        local app_ready=$(kubectl get deployment sample-app -o jsonpath='{.status.readyReplicas}' || echo "0")
        if [[ "$app_ready" -gt "0" ]]; then
            print_pass "Sample application is running for monitoring"
        else
            print_fail "Sample application is not ready"
        fi
    else
        print_fail "Sample application for monitoring not found"
    fi
    
    # Check for load generator
    if kubectl get deployment load-generator >/dev/null 2>&1; then
        local lg_ready=$(kubectl get deployment load-generator -o jsonpath='{.status.readyReplicas}' || echo "0")
        if [[ "$lg_ready" -gt "0" ]]; then
            print_pass "Load generator is running"
        else
            print_fail "Load generator is not ready"
        fi
    else
        print_fail "Load generator not found"
    fi
}

# Test Monitoring Endpoints
test_monitoring_endpoints() {
    print_test "Monitoring endpoints accessibility"
    
    # Test if we can reach Prometheus (assumes port-forward or ingress)
    if kubectl port-forward -n monitoring service/prometheus 9090:9090 --timeout=5s &>/dev/null &
        local pf_pid=$!
        sleep 2
        
        if curl -s http://localhost:9090/api/v1/targets >/dev/null 2>&1; then
            print_pass "Prometheus API is accessible"
        else
            print_fail "Cannot access Prometheus API"
        fi
        
        kill $pf_pid 2>/dev/null || true
    fi
    
    # Check monitoring namespace
    if kubectl get namespace monitoring >/dev/null 2>&1; then
        local pod_count=$(kubectl get pods -n monitoring --no-headers | wc -l || echo "0")
        if [[ "$pod_count" -gt "3" ]]; then
            print_pass "Monitoring namespace has multiple components ($pod_count pods)"
        else
            print_fail "Monitoring namespace has insufficient components ($pod_count pods)"
        fi
    else
        print_fail "Monitoring namespace not found"
    fi
}

# Test Resource Usage
test_resource_usage() {
    print_test "Monitoring resource usage"
    
    # Check resource requests/limits for monitoring components
    local components_with_resources=0
    local monitoring_pods=$(kubectl get pods -n monitoring --no-headers -o name | wc -l || echo "0")
    
    if kubectl get pods -n monitoring -o yaml | grep -q "resources:"; then
        print_pass "Monitoring components have resource specifications"
        ((components_with_resources++))
    else
        print_fail "Monitoring components missing resource specifications"
    fi
    
    # Check for persistent storage (if needed)
    local pv_count=$(kubectl get pv | grep monitoring | wc -l || echo "0")
    if [[ "$pv_count" -gt "0" ]]; then
        print_pass "Persistent storage configured for monitoring ($pv_count volumes)"
    else
        print_fail "No persistent storage found for monitoring (data may be lost on restart)"
    fi
}

# Main execution
main() {
    print_header "Monitoring Module Validation"
    
    test_prometheus
    test_grafana
    test_logging
    test_alerting
    test_application_monitoring
    test_monitoring_endpoints
    test_resource_usage
    
    # Summary
    print_header "Validation Summary"
    echo -e "Tests passed: ${GREEN}$PASSED${NC}"
    echo -e "Tests failed: ${RED}$FAILED${NC}"
    
    if [[ $FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}📊 All tests passed! Monitoring module completed successfully.${NC}"
        echo -e "${GREEN}Your observability stack is ready for production workloads!${NC}"
        echo -e "\n${BLUE}Access your monitoring tools:${NC}"
        echo -e "  Prometheus: kubectl port-forward -n monitoring service/prometheus 9090:9090"
        echo -e "  Grafana:    kubectl port-forward -n monitoring service/grafana 3000:3000"
        echo -e "  Kibana:     kubectl port-forward -n monitoring service/kibana 5601:5601"
        exit 0
    else
        echo -e "\n${YELLOW}⚠️  Some tests failed. Review the monitoring issues above.${NC}"
        echo -e "${YELLOW}Monitoring is critical for production operations - please address these issues.${NC}"
        exit 1
    fi
}

# Handle arguments
case "${1:-}" in
    --help|-h)
        echo "Monitoring Module Validation Script"
        echo "Usage: $0 [OPTIONS]"
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --cleanup      Clean up test resources"
        echo "  --quick        Run quick validation only"
        echo "  --metrics      Test metrics collection only"
        echo "  --logging      Test logging stack only"
        echo "  --alerting     Test alerting system only"
        exit 0
        ;;
    --cleanup)
        kubectl delete namespace monitoring 2>/dev/null || true
        kubectl delete -f ../manifests/ 2>/dev/null || true
        echo "Monitoring test cleanup completed."
        exit 0
        ;;
    --quick)
        test_prometheus
        test_grafana
        print_header "Quick Validation Summary"
        echo -e "Tests passed: ${GREEN}$PASSED${NC}"
        echo -e "Tests failed: ${RED}$FAILED${NC}"
        exit 0
        ;;
    --metrics)
        test_prometheus
        test_application_monitoring
        exit 0
        ;;
    --logging)
        test_logging
        exit 0
        ;;
    --alerting)
        test_alerting
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