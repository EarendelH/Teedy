# Teedy Kubernetes 部署 - 快速开始指南

## Practice 11 完成内容

本项目完成了 Practice 11 的所有要求，包括：

### ✅ 已完成的任务

1. **Kubernetes 配置文件**
   - ✅ Namespace 配置
   - ✅ Deployment 配置（Teedy 应用 + PostgreSQL 数据库）
   - ✅ Service 配置（NodePort + ClusterIP）
   - ✅ PersistentVolumeClaim 配置
   - ✅ Secret 配置（数据库密码）
   - ✅ ConfigMap 配置（应用配置）
   - ✅ HorizontalPodAutoscaler 配置（自动扩缩容）
   - ✅ Ingress 配置（可选）

2. **部署脚本**
   - ✅ `deploy.sh` - 自动化部署脚本
   - ✅ `cleanup.sh` - 清理脚本
   - ✅ `test.sh` - 测试验证脚本

3. **文档**
   - ✅ 详细的 README.md
   - ✅ 快速开始指南
   - ✅ 故障排查指南

## 架构说明

```
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                    │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │              Namespace: teedy                      │ │
│  │                                                    │ │
│  │  ┌──────────────────┐      ┌──────────────────┐  │ │
│  │  │  Teedy Pods      │      │  PostgreSQL Pod  │  │ │
│  │  │  (2-5 replicas)  │◄────►│  (1 replica)     │  │ │
│  │  │                  │      │                  │  │ │
│  │  │  Port: 8080      │      │  Port: 5432      │  │ │
│  │  └────────┬─────────┘      └────────┬─────────┘  │ │
│  │           │                         │            │ │
│  │           │                         │            │ │
│  │  ┌────────▼─────────┐      ┌────────▼─────────┐  │ │
│  │  │  teedy-service   │      │  teedy-db        │  │ │
│  │  │  (NodePort)      │      │  (ClusterIP)     │  │ │
│  │  │  Port: 30080     │      │  Port: 5432      │  │ │
│  │  └──────────────────┘      └──────────────────┘  │ │
│  │                                                    │ │
│  │  ┌──────────────────┐      ┌──────────────────┐  │ │
│  │  │  teedy-data-pvc  │      │ postgres-data-pvc│  │ │
│  │  │  (5Gi)           │      │  (2Gi)           │  │ │
│  │  └──────────────────┘      └──────────────────┘  │ │
│  │                                                    │ │
│  │  ┌──────────────────────────────────────────────┐ │
│  │  │  HorizontalPodAutoscaler (HPA)               │ │
│  │  │  Min: 2, Max: 5                              │ │
│  │  │  CPU: 70%, Memory: 80%                       │ │
│  │  └──────────────────────────────────────────────┘ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## 快速部署（3 步）

### 方法 1: 使用自动化脚本（推荐）

```bash
# 1. 进入 k8s 目录
cd k8s

# 2. 运行部署脚本
./deploy.sh

# 3. 测试部署
./test.sh
```

### 方法 2: 手动部署

```bash
# 1. 应用所有配置
kubectl apply -f k8s/

# 2. 等待 Pod 就绪
kubectl wait --for=condition=ready pod -l app=teedy -n teedy --timeout=300s

# 3. 检查状态
kubectl get all -n teedy
```

### 方法 3: 使用 Kustomize

```bash
# 使用 Kustomize 部署
kubectl apply -k k8s/

# 检查状态
kubectl get all -n teedy
```

## 访问应用

### 选项 1: NodePort（推荐用于本地测试）

```bash
# 获取节点 IP（minikube）
minikube ip

# 访问: http://<node-ip>:30080
# 例如: http://192.168.49.2:30080
```

### 选项 2: Port Forward

```bash
# 端口转发
kubectl port-forward -n teedy svc/teedy-service 8080:8080

# 访问: http://localhost:8080
```

### 选项 3: Minikube Service

```bash
# 使用 minikube 自动打开浏览器
minikube service -n teedy teedy-service
```

## 默认登录凭据

- **用户名**: `admin`
- **密码**: `admin`

⚠️ **重要**: 首次登录后请立即修改密码！

## 验证部署

```bash
# 运行测试脚本
./k8s/test.sh

# 或手动检查
kubectl get all -n teedy
kubectl get pvc -n teedy
kubectl get hpa -n teedy
```

## 监控和日志

```bash
# 查看 Teedy 日志
kubectl logs -n teedy -l app=teedy -f

# 查看数据库日志
kubectl logs -n teedy -l app=teedy-db -f

# 查看 HPA 状态
kubectl get hpa -n teedy -w

# 查看 Pod 详情
kubectl describe pod -n teedy <pod-name>
```

## 扩缩容测试

### 手动扩容

```bash
# 扩展到 3 个副本
kubectl scale deployment -n teedy teedy --replicas=3

# 查看扩容状态
kubectl get pods -n teedy -l app=teedy -w
```

### 自动扩容（HPA）

HPA 会根据以下指标自动扩缩容：
- CPU 使用率 > 70%
- 内存使用率 > 80%
- 最小副本数: 2
- 最大副本数: 5

```bash
# 查看 HPA 状态
kubectl get hpa -n teedy

# 生成负载测试（可选）
kubectl run -it --rm load-generator --image=busybox -n teedy -- /bin/sh
# 在容器内运行:
while true; do wget -q -O- http://teedy-service:8080/api/app; done
```

## 清理部署

```bash
# 使用清理脚本
./k8s/cleanup.sh

# 或手动删除
kubectl delete namespace teedy
```

## 故障排查

### Pod 无法启动

```bash
# 查看 Pod 事件
kubectl describe pod -n teedy <pod-name>

# 查看日志
kubectl logs -n teedy <pod-name>

# 查看 PVC 状态
kubectl get pvc -n teedy
```

### 无法访问应用

```bash
# 检查 Service
kubectl get svc -n teedy
kubectl describe svc -n teedy teedy-service

# 检查 Endpoints
kubectl get endpoints -n teedy

# 测试 Pod 内部连接
kubectl exec -it -n teedy <pod-name> -- curl http://localhost:8080/api/app
```

### 数据库连接失败

```bash
# 检查数据库 Pod
kubectl get pods -n teedy -l app=teedy-db

# 测试数据库连接
kubectl exec -it -n teedy <teedy-pod-name> -- nc -zv teedy-db 5432

# 查看数据库日志
kubectl logs -n teedy -l app=teedy-db
```

## 文件清单

| 文件 | 说明 |
|------|------|
| `namespace.yaml` | 创建 teedy 命名空间 |
| `secret.yaml` | 数据库密码等敏感信息 |
| `configmap.yaml` | 应用配置 |
| `pvc.yaml` | Teedy 数据持久化卷 |
| `postgres-pvc.yaml` | PostgreSQL 数据持久化卷 |
| `postgres-deployment.yaml` | PostgreSQL 部署配置 |
| `postgres-service.yaml` | PostgreSQL 服务配置 |
| `deployment.yaml` | Teedy 应用部署配置 |
| `service.yaml` | Teedy 服务配置（NodePort） |
| `hpa.yaml` | 水平自动扩缩容配置 |
| `ingress.yaml` | Ingress 配置（可选） |
| `kustomization.yaml` | Kustomize 配置 |
| `deploy.sh` | 自动化部署脚本 |
| `cleanup.sh` | 清理脚本 |
| `test.sh` | 测试验证脚本 |
| `README.md` | 详细文档 |
| `QUICKSTART.md` | 本快速开始指南 |

## 生产环境建议

1. **安全性**
   - 修改 `secret.yaml` 中的默认密码
   - 使用外部密钥管理系统（如 Vault）
   - 启用 TLS/SSL

2. **高可用性**
   - 使用托管数据库服务
   - 配置 Pod 反亲和性
   - 使用多可用区

3. **监控**
   - 部署 Prometheus + Grafana
   - 配置告警规则
   - 监控资源使用

4. **备份**
   - 定期备份 PVC 数据
   - 配置数据库备份策略
   - 测试恢复流程

## 参考资料

- [Kubernetes 官方文档](https://kubernetes.io/docs/)
- [Teedy 官方文档](https://teedy.io/)
- Tutorial11-k8s.pdf
- Practice11-k8s.pdf

## 技术支持

如有问题，请查看：
1. `README.md` - 详细文档
2. `kubectl describe` - 资源详情
3. `kubectl logs` - 应用日志
4. GitHub Issues

---

**完成时间**: 2026-05-26  
**作者**: EarendelH  
**版本**: 1.0
