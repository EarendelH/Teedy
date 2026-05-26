# Practice 10 完成报告 - CI/CD with Jenkins and Docker

## 完成状态检查

### ✅ 已完成的内容

| 任务 | 状态 | 文件 |
|------|------|------|
| Dockerfile | ✅ | `Dockerfile` |
| Docker Compose | ✅ | `docker-compose.yml` |
| Jenkinsfile | ✅ | `Jenkinsfile` |
| GitHub Actions | ✅ | `.github/workflows/build.yml`, `.github/workflows/docker-image.yml` |
| Docker Hub 镜像 | ✅ | `earendelheng/teedy:latest` |
| 多架构支持 | ✅ | AMD64 + ARM64 |

### 📋 Jenkinsfile 流水线阶段

Jenkinsfile 包含以下 10 个阶段：

1. **Clean** - 清理项目
2. **Compile** - 编译代码
3. **Test** - 运行单元测试
4. **PMD** - 代码质量检查
5. **JaCoCo** - 代码覆盖率报告
6. **Javadoc** - 生成 API 文档
7. **Site** - 生成项目站点
8. **Package** - 打包 WAR 文件
9. **Build Docker Image** - 构建 Docker 镜像
10. **Push to Docker Hub** - 推送到 Docker Hub
11. **Run Containers** - 运行 3 个容器实例（端口 8082, 8083, 8084）

## Jenkins 操作指南

### 前置准备

#### 1. 安装 Jenkins

**使用 Docker 安装（推荐）：**

```bash
# 创建 Jenkins 数据目录
mkdir -p ~/jenkins_home

# 运行 Jenkins 容器
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v ~/jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

**访问 Jenkins：**
- URL: http://localhost:8080
- 获取初始密码：
  ```bash
  docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
  ```

#### 2. 安装必要的插件

在 Jenkins 中安装以下插件：
- **Git Plugin** - Git 集成
- **Docker Plugin** - Docker 集成
- **Docker Pipeline Plugin** - Docker Pipeline 支持
- **Pipeline Plugin** - Pipeline 支持
- **Blue Ocean** - 现代化 UI（可选）

**安装步骤：**
1. 进入 Jenkins → Manage Jenkins → Manage Plugins
2. 选择 "Available" 标签
3. 搜索并勾选上述插件
4. 点击 "Install without restart"

#### 3. 配置 Docker Hub 凭据

**步骤：**
1. 进入 Jenkins → Manage Jenkins → Manage Credentials
2. 点击 "(global)" → "Add Credentials"
3. 填写信息：
   - **Kind**: Username with password
   - **Username**: 你的 Docker Hub 用户名（earendelheng）
   - **Password**: 你的 Docker Hub 密码或 Access Token
   - **ID**: `dockerhub_credentials`（必须与 Jenkinsfile 中的一致）
   - **Description**: Docker Hub Credentials
4. 点击 "Create"

**获取 Docker Hub Access Token：**
1. 登录 https://hub.docker.com/
2. 进入 Account Settings → Security
3. 点击 "New Access Token"
4. 输入描述，选择权限，生成 Token
5. 复制 Token（只显示一次）

### 创建 Jenkins Pipeline 任务

#### 方法 1: 使用 Pipeline from SCM（推荐）

1. **创建新任务**
   - 点击 "New Item"
   - 输入任务名称：`Teedy-CI-CD`
   - 选择 "Pipeline"
   - 点击 "OK"

2. **配置 Pipeline**
   - 在 "Pipeline" 部分：
     - **Definition**: Pipeline script from SCM
     - **SCM**: Git
     - **Repository URL**: `https://github.com/EarendelH/Teedy.git`
     - **Credentials**: 如果是私有仓库，添加 GitHub 凭据
     - **Branch Specifier**: `*/master`
     - **Script Path**: `Jenkinsfile`
   
3. **保存配置**
   - 点击 "Save"

4. **构建触发器（可选）**
   - 勾选 "GitHub hook trigger for GITScm polling"（需要配置 GitHub Webhook）
   - 或勾选 "Poll SCM"，设置定时检查：`H/5 * * * *`（每 5 分钟检查一次）

#### 方法 2: 直接粘贴 Pipeline 脚本

1. **创建新任务**
   - 点击 "New Item"
   - 输入任务名称：`Teedy-CI-CD`
   - 选择 "Pipeline"
   - 点击 "OK"

2. **配置 Pipeline**
   - 在 "Pipeline" 部分：
     - **Definition**: Pipeline script
     - 将 `Jenkinsfile` 的内容粘贴到脚本框中

3. **保存配置**

### 运行 Pipeline

#### 手动触发构建

1. 进入任务页面：`Teedy-CI-CD`
2. 点击左侧 "Build Now"
3. 查看构建进度：点击构建号（如 #1）
4. 查看控制台输出：点击 "Console Output"

#### 自动触发构建

**配置 GitHub Webhook：**

1. **在 GitHub 仓库中配置**
   - 进入仓库 Settings → Webhooks → Add webhook
   - **Payload URL**: `http://<jenkins-url>:8080/github-webhook/`
   - **Content type**: application/json
   - **Which events**: Just the push event
   - 点击 "Add webhook"

2. **在 Jenkins 中配置**
   - 任务配置 → Build Triggers
   - 勾选 "GitHub hook trigger for GITScm polling"

### 查看构建结果

#### 1. Pipeline 视图

- 在任务页面可以看到 Pipeline 的各个阶段
- 绿色表示成功，红色表示失败
- 点击阶段可以查看详细日志

#### 2. 测试报告

- 点击构建号 → "Test Result"
- 查看单元测试结果
- 查看失败的测试用例

#### 3. 代码覆盖率报告

- 点击构建号 → "JaCoCo Coverage Report"
- 查看代码覆盖率统计

#### 4. PMD 报告

- 点击构建号 → "PMD Warnings"
- 查看代码质量问题

#### 5. 构建产物

- 点击构建号 → "Build Artifacts"
- 下载生成的 WAR 文件、JAR 文件、站点文档等

### 验证 Docker 镜像

#### 1. 检查 Docker Hub

访问：https://hub.docker.com/r/earendelheng/teedy/tags

应该能看到：
- `latest` 标签
- 构建号标签（如 `1`, `2`, `3`）

#### 2. 本地拉取镜像

```bash
# 拉取最新镜像
docker pull earendelheng/teedy:latest

# 查看镜像
docker images | grep teedy
```

#### 3. 运行容器

```bash
# 运行单个容器
docker run -d -p 8080:8080 --name teedy earendelheng/teedy:latest

# 访问应用
open http://localhost:8080
```

### 验证运行的容器

Jenkins Pipeline 会自动启动 3 个容器实例：

```bash
# 查看运行的容器
docker ps --filter "name=teedy-container"

# 应该看到：
# teedy-container-8082 (端口 8082)
# teedy-container-8083 (端口 8083)
# teedy-container-8084 (端口 8084)

# 访问各个实例
open http://localhost:8082
open http://localhost:8083
open http://localhost:8084
```

## 故障排查

### 问题 1: Docker 权限错误

**错误信息：**
```
Got permission denied while trying to connect to the Docker daemon socket
```

**解决方案：**
```bash
# 将 Jenkins 用户添加到 docker 组
docker exec -u root jenkins usermod -aG docker jenkins

# 重启 Jenkins 容器
docker restart jenkins
```

### 问题 2: Docker Hub 推送失败

**错误信息：**
```
denied: requested access to the resource is denied
```

**解决方案：**
1. 检查 Docker Hub 凭据是否正确
2. 确保凭据 ID 为 `dockerhub_credentials`
3. 确保 Docker Hub 用户名和镜像名称匹配

### 问题 3: Maven 构建失败

**错误信息：**
```
No goals have been specified for this build
```

**解决方案：**
1. 检查 Maven 是否正确安装
2. 检查 `pom.xml` 文件是否存在
3. 查看详细的错误日志

### 问题 4: 测试失败

**解决方案：**
1. 查看测试报告，找到失败的测试
2. 检查测试日志
3. 本地运行测试：`mvn test`
4. 修复测试后重新提交

### 问题 5: 容器端口冲突

**错误信息：**
```
Bind for 0.0.0.0:8082 failed: port is already allocated
```

**解决方案：**
```bash
# 停止占用端口的容器
docker stop teedy-container-8082
docker rm teedy-container-8082

# 或者修改 Jenkinsfile 中的端口号
```

## 监控和维护

### 1. 查看 Jenkins 日志

```bash
# 查看 Jenkins 容器日志
docker logs -f jenkins

# 查看特定构建的日志
# 在 Jenkins UI 中：构建号 → Console Output
```

### 2. 清理旧的构建

1. 进入任务配置
2. 勾选 "Discard old builds"
3. 设置保留策略：
   - Days to keep builds: 30
   - Max # of builds to keep: 10

### 3. 清理 Docker 资源

```bash
# 清理未使用的镜像
docker image prune -a

# 清理停止的容器
docker container prune

# 清理未使用的卷
docker volume prune
```

### 4. 备份 Jenkins

```bash
# 备份 Jenkins 数据目录
tar -czf jenkins_backup_$(date +%Y%m%d).tar.gz ~/jenkins_home

# 恢复备份
tar -xzf jenkins_backup_20260526.tar.gz -C ~/
```

## Blue Ocean UI（可选）

Blue Ocean 提供更现代化的 Pipeline 可视化界面。

### 安装 Blue Ocean

1. Manage Jenkins → Manage Plugins
2. 搜索 "Blue Ocean"
3. 安装插件

### 使用 Blue Ocean

1. 点击左侧 "Open Blue Ocean"
2. 查看 Pipeline 的可视化流程
3. 更直观地查看各个阶段的状态

## 性能优化建议

### 1. 使用 Maven 缓存

在 Jenkinsfile 中添加：
```groovy
options {
    buildDiscarder(logRotator(numToKeepStr: '10'))
    timestamps()
}
```

### 2. 并行执行阶段

```groovy
stage('Parallel Tests') {
    parallel {
        stage('Unit Tests') {
            steps {
                sh 'mvn test'
            }
        }
        stage('Integration Tests') {
            steps {
                sh 'mvn verify'
            }
        }
    }
}
```

### 3. 使用 Docker 缓存

在 Dockerfile 中优化层缓存：
- 将不常变化的指令放在前面
- 使用 `.dockerignore` 排除不必要的文件

## 总结

### ✅ Practice 10 完成清单

- [x] Dockerfile 配置
- [x] docker-compose.yml 配置
- [x] Jenkinsfile Pipeline 配置
- [x] Docker Hub 镜像推送
- [x] 多架构支持（AMD64 + ARM64）
- [x] GitHub Actions CI/CD
- [x] 自动化测试
- [x] 代码质量检查（PMD）
- [x] 代码覆盖率报告（JaCoCo）
- [x] 文档生成（Javadoc）
- [x] 多容器部署

### 📊 CI/CD 流程

```
GitHub Push
    ↓
GitHub Actions / Jenkins Webhook
    ↓
Jenkins Pipeline
    ↓
├─ Clean & Compile
├─ Test (Unit Tests)
├─ Code Quality (PMD)
├─ Coverage (JaCoCo)
├─ Documentation (Javadoc)
├─ Package (WAR)
├─ Build Docker Image
├─ Push to Docker Hub
└─ Deploy Containers (8082, 8083, 8084)
    ↓
Application Running
```

### 🎯 关键指标

- **构建时间**: ~10 分钟
- **测试覆盖率**: 查看 JaCoCo 报告
- **代码质量**: 查看 PMD 报告
- **部署实例**: 3 个容器
- **Docker 镜像大小**: ~1GB

---

**完成日期**: 2026-05-26  
**GitHub**: https://github.com/EarendelH/Teedy  
**Docker Hub**: https://hub.docker.com/r/earendelheng/teedy
