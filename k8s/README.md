# Teedy Kubernetes Deployment

This directory contains Kubernetes manifests for deploying Teedy document management system.

## Architecture

- **Teedy Application**: 2 replicas with auto-scaling (2-5 pods)
- **PostgreSQL Database**: 1 replica with persistent storage
- **Persistent Storage**: 5Gi for Teedy data, 2Gi for PostgreSQL
- **Service**: NodePort on port 30080
- **Auto-scaling**: Based on CPU (70%) and Memory (80%) utilization

## Prerequisites

- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured
- Docker image: `earendelheng/teedy:latest`

## Quick Start

### 1. Deploy all resources

```bash
# Apply all manifests in order
kubectl apply -f namespace.yaml
kubectl apply -f secret.yaml
kubectl apply -f configmap.yaml
kubectl apply -f pvc.yaml
kubectl apply -f postgres-pvc.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml

# Or apply all at once
kubectl apply -f .
```

### 2. Check deployment status

```bash
# Check all resources in teedy namespace
kubectl get all -n teedy

# Check pods
kubectl get pods -n teedy

# Check services
kubectl get svc -n teedy

# Check PVCs
kubectl get pvc -n teedy

# Check HPA
kubectl get hpa -n teedy
```

### 3. Access the application

**Using NodePort:**
```bash
# Get the node IP (for minikube)
minikube ip

# Access at: http://<node-ip>:30080
# For minikube: http://$(minikube ip):30080
```

**Using Port Forward:**
```bash
kubectl port-forward -n teedy svc/teedy-service 8080:8080

# Access at: http://localhost:8080
```

**Using Ingress (optional):**
```bash
# Apply ingress
kubectl apply -f ingress.yaml

# Add to /etc/hosts
echo "$(minikube ip) teedy.local" | sudo tee -a /etc/hosts

# Access at: http://teedy.local
```

### 4. Default credentials

- **Username**: admin
- **Password**: admin

## Resource Files

| File | Description |
|------|-------------|
| `namespace.yaml` | Creates teedy namespace |
| `secret.yaml` | Database passwords |
| `configmap.yaml` | Application configuration |
| `pvc.yaml` | Persistent volume claim for Teedy data |
| `postgres-pvc.yaml` | Persistent volume claim for PostgreSQL |
| `postgres-deployment.yaml` | PostgreSQL database deployment |
| `postgres-service.yaml` | PostgreSQL service (ClusterIP) |
| `deployment.yaml` | Teedy application deployment |
| `service.yaml` | Teedy service (NodePort) |
| `hpa.yaml` | Horizontal Pod Autoscaler |
| `ingress.yaml` | Ingress configuration (optional) |

## Monitoring

### View logs

```bash
# Teedy application logs
kubectl logs -n teedy -l app=teedy -f

# PostgreSQL logs
kubectl logs -n teedy -l app=teedy-db -f
```

### Check pod status

```bash
# Describe pod
kubectl describe pod -n teedy <pod-name>

# Get pod details
kubectl get pod -n teedy <pod-name> -o yaml
```

### Check HPA metrics

```bash
# Watch HPA status
kubectl get hpa -n teedy -w

# Describe HPA
kubectl describe hpa -n teedy teedy-hpa
```

## Scaling

### Manual scaling

```bash
# Scale to 3 replicas
kubectl scale deployment -n teedy teedy --replicas=3

# Check scaling
kubectl get pods -n teedy -l app=teedy
```

### Auto-scaling

The HPA automatically scales based on:
- CPU utilization > 70%
- Memory utilization > 80%
- Min replicas: 2
- Max replicas: 5

## Troubleshooting

### Pods not starting

```bash
# Check pod events
kubectl describe pod -n teedy <pod-name>

# Check logs
kubectl logs -n teedy <pod-name>

# Check if PVC is bound
kubectl get pvc -n teedy
```

### Database connection issues

```bash
# Check PostgreSQL pod
kubectl get pods -n teedy -l app=teedy-db

# Test database connection
kubectl exec -it -n teedy <teedy-pod-name> -- nc -zv teedy-db 5432

# Check database logs
kubectl logs -n teedy -l app=teedy-db
```

### Service not accessible

```bash
# Check service endpoints
kubectl get endpoints -n teedy

# Check service details
kubectl describe svc -n teedy teedy-service

# For minikube, ensure tunnel is running
minikube service -n teedy teedy-service
```

## Cleanup

```bash
# Delete all resources
kubectl delete namespace teedy

# Or delete individually
kubectl delete -f .
```

## Production Considerations

1. **Security**:
   - Change default passwords in `secret.yaml`
   - Use external secret management (e.g., Sealed Secrets, Vault)
   - Enable TLS/SSL for Ingress

2. **Storage**:
   - Use appropriate StorageClass for your environment
   - Consider backup strategies for PVCs
   - Use StatefulSet for database in production

3. **High Availability**:
   - Use managed database service (e.g., Cloud SQL, RDS)
   - Configure pod anti-affinity
   - Use multiple availability zones

4. **Monitoring**:
   - Set up Prometheus and Grafana
   - Configure alerts for pod failures
   - Monitor resource usage

5. **Resource Limits**:
   - Adjust CPU/memory requests and limits based on load
   - Configure appropriate HPA thresholds
   - Use ResourceQuota for namespace

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Teedy Documentation](https://teedy.io/)
- Tutorial11-k8s.pdf
- Practice11-k8s.pdf
