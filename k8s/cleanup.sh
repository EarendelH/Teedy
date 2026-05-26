#!/bin/bash

# Teedy Kubernetes Cleanup Script
# This script removes all Teedy resources from Kubernetes cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed."
    exit 1
fi

print_warn "This will delete all Teedy resources including data!"
read -p "Are you sure you want to continue? (yes/no) " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    print_info "Cleanup cancelled."
    exit 0
fi

print_info "Starting cleanup..."

# Delete resources in reverse order
if kubectl get namespace teedy &> /dev/null; then
    print_info "Deleting HPA..."
    kubectl delete -f hpa.yaml --ignore-not-found=true

    print_info "Deleting Ingress..."
    kubectl delete -f ingress.yaml --ignore-not-found=true

    print_info "Deleting Services..."
    kubectl delete -f service.yaml --ignore-not-found=true
    kubectl delete -f postgres-service.yaml --ignore-not-found=true

    print_info "Deleting Deployments..."
    kubectl delete -f deployment.yaml --ignore-not-found=true
    kubectl delete -f postgres-deployment.yaml --ignore-not-found=true

    print_info "Deleting PVCs..."
    kubectl delete -f pvc.yaml --ignore-not-found=true
    kubectl delete -f postgres-pvc.yaml --ignore-not-found=true

    print_info "Deleting ConfigMap and Secret..."
    kubectl delete -f configmap.yaml --ignore-not-found=true
    kubectl delete -f secret.yaml --ignore-not-found=true

    print_info "Deleting namespace..."
    kubectl delete -f namespace.yaml --ignore-not-found=true

    print_info "Cleanup completed successfully!"
else
    print_warn "Namespace 'teedy' does not exist. Nothing to clean up."
fi
