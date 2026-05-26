#!/bin/bash

# Teedy Kubernetes Deployment Script
# This script deploys Teedy application to Kubernetes cluster

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
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

print_info "Starting Teedy deployment to Kubernetes..."

# Deploy resources in order
print_info "Creating namespace..."
kubectl apply -f namespace.yaml

print_info "Creating secrets..."
kubectl apply -f secret.yaml

print_info "Creating configmap..."
kubectl apply -f configmap.yaml

print_info "Creating persistent volume claims..."
kubectl apply -f pvc.yaml
kubectl apply -f postgres-pvc.yaml

print_info "Deploying PostgreSQL database..."
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml

print_info "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=teedy-db -n teedy --timeout=300s

print_info "Deploying Teedy application..."
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

print_info "Waiting for Teedy pods to be ready..."
kubectl wait --for=condition=ready pod -l app=teedy -n teedy --timeout=300s

print_info "Creating HorizontalPodAutoscaler..."
kubectl apply -f hpa.yaml

# Optional: Deploy ingress
read -p "Do you want to deploy Ingress? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Deploying Ingress..."
    kubectl apply -f ingress.yaml
fi

print_info "Deployment completed successfully!"
echo ""
print_info "Checking deployment status..."
kubectl get all -n teedy

echo ""
print_info "Access Teedy application:"
echo "  - NodePort: http://<node-ip>:30080"
echo "  - Port Forward: kubectl port-forward -n teedy svc/teedy-service 8080:8080"
echo ""
print_info "Default credentials:"
echo "  - Username: admin"
echo "  - Password: admin"
echo ""
print_warn "Remember to change the default password after first login!"
