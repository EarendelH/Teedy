#!/bin/bash

# Teedy Kubernetes Deployment Test Script
# This script tests the Teedy deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run test
run_test() {
    local test_name=$1
    local test_command=$2

    print_test "$test_name"
    if eval "$test_command" &> /dev/null; then
        print_pass "$test_name"
        ((TESTS_PASSED++))
        return 0
    else
        print_fail "$test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

print_info "Starting Teedy Kubernetes deployment tests..."
echo ""

# Test 1: Namespace exists
run_test "Namespace 'teedy' exists" \
    "kubectl get namespace teedy"

# Test 2: Secret exists
run_test "Secret 'teedy-db-secret' exists" \
    "kubectl get secret teedy-db-secret -n teedy"

# Test 3: ConfigMap exists
run_test "ConfigMap 'teedy-config' exists" \
    "kubectl get configmap teedy-config -n teedy"

# Test 4: PVCs are bound
run_test "PVC 'teedy-data-pvc' is bound" \
    "kubectl get pvc teedy-data-pvc -n teedy -o jsonpath='{.status.phase}' | grep -q Bound"

run_test "PVC 'postgres-data-pvc' is bound" \
    "kubectl get pvc postgres-data-pvc -n teedy -o jsonpath='{.status.phase}' | grep -q Bound"

# Test 5: PostgreSQL deployment
run_test "PostgreSQL deployment exists" \
    "kubectl get deployment teedy-db -n teedy"

run_test "PostgreSQL pod is running" \
    "kubectl get pods -n teedy -l app=teedy-db -o jsonpath='{.items[0].status.phase}' | grep -q Running"

run_test "PostgreSQL service exists" \
    "kubectl get service teedy-db -n teedy"

# Test 6: Teedy deployment
run_test "Teedy deployment exists" \
    "kubectl get deployment teedy -n teedy"

run_test "Teedy pods are running" \
    "kubectl get pods -n teedy -l app=teedy -o jsonpath='{.items[*].status.phase}' | grep -q Running"

run_test "Teedy has at least 2 replicas" \
    "[ \$(kubectl get deployment teedy -n teedy -o jsonpath='{.status.readyReplicas}') -ge 2 ]"

run_test "Teedy service exists" \
    "kubectl get service teedy-service -n teedy"

# Test 7: HPA exists
run_test "HorizontalPodAutoscaler exists" \
    "kubectl get hpa teedy-hpa -n teedy"

# Test 8: Service endpoints
run_test "Teedy service has endpoints" \
    "kubectl get endpoints teedy-service -n teedy -o jsonpath='{.subsets[*].addresses[*].ip}' | grep -q ."

run_test "PostgreSQL service has endpoints" \
    "kubectl get endpoints teedy-db -n teedy -o jsonpath='{.subsets[*].addresses[*].ip}' | grep -q ."

# Test 9: Health checks
print_test "Testing Teedy application health"
POD_NAME=$(kubectl get pods -n teedy -l app=teedy -o jsonpath='{.items[0].metadata.name}')
if kubectl exec -n teedy $POD_NAME -- curl -s http://localhost:8080/api/app > /dev/null 2>&1; then
    print_pass "Teedy application is responding"
    ((TESTS_PASSED++))
else
    print_fail "Teedy application is not responding"
    ((TESTS_FAILED++))
fi

# Test 10: Database connectivity
print_test "Testing database connectivity from Teedy pod"
if kubectl exec -n teedy $POD_NAME -- nc -zv teedy-db 5432 > /dev/null 2>&1; then
    print_pass "Database is reachable from Teedy pod"
    ((TESTS_PASSED++))
else
    print_fail "Database is not reachable from Teedy pod"
    ((TESTS_FAILED++))
fi

# Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo "Total Tests:  $((TESTS_PASSED + TESTS_FAILED))"
echo "=========================================="

if [ $TESTS_FAILED -eq 0 ]; then
    print_pass "All tests passed!"
    echo ""
    print_info "Deployment information:"
    kubectl get all -n teedy
    echo ""
    print_info "Access Teedy at:"
    echo "  - NodePort: http://\$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}'):30080"
    echo "  - Port Forward: kubectl port-forward -n teedy svc/teedy-service 8080:8080"
    exit 0
else
    print_fail "Some tests failed. Please check the deployment."
    echo ""
    print_info "Debugging commands:"
    echo "  - kubectl get all -n teedy"
    echo "  - kubectl describe pod -n teedy <pod-name>"
    echo "  - kubectl logs -n teedy <pod-name>"
    exit 1
fi
