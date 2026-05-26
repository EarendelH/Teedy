# Teedy Docker 镜像空白页面问题解决方案

## 问题描述

访问 `http://localhost:8084` 时页面空白，但 API 端点 `/api/app` 正常工作。

## 根本原因

检查发现 WAR 文件中的前端资源文件大小为 0：
```bash
docker exec teedy_manual01 ls -la /tmp/jetty-*/webapp/
# index.html: 0 bytes
# docs.min.js: 0 bytes
# share.html: 0 bytes
# share.min.js: 0 bytes
```

**原因**：Docker 镜像构建时没有使用 Maven 的 `prod` profile，导致前端资源没有被正确打包。

## 解决方案

### 方案 1: 重新构建 Docker 镜像（推荐）

需要先使用 `-Pprod` profile 构建项目，然后再构建 Docker 镜像。

#### 步骤 1: 使用生产模式构建

```bash
# 清理并使用 prod profile 构建
mvn clean package -Pprod -DskipTests

# 验证 WAR 文件大小（应该 > 80MB）
ls -lh docs-web/target/docs-web-*.war
```

#### 步骤 2: 构建 Docker 镜像

```bash
# 构建镜像
docker build -t earendelheng/teedy:latest .

# 推送到 Docker Hub
docker push earendelheng/teedy:latest
```

#### 步骤 3: 运行新镜像

```bash
# 停止旧容器
docker stop teedy_manual01
docker rm teedy_manual01

# 运行新容器
docker run -d -p 8084:8080 --name teedy_manual01 earendelheng/teedy:latest

# 等待启动（约 30 秒）
sleep 30

# 访问应用
open http://localhost:8084
```

### 方案 2: 修改 Jenkinsfile（自动化）

更新 Jenkinsfile 的 Package 阶段，添加 `-Pprod` profile：

```groovy
stage('Package') {
    steps {
        sh 'mvn package -Pprod -DskipTests'
    }
}
```

### 方案 3: 修改 GitHub Actions

更新 `.github/workflows/docker-image.yml`，在构建前添加 Maven 构建步骤：

```yaml
- name: Build with Maven
  run: mvn clean package -Pprod -DskipTests

- name: Build and push
  uses: docker/build-push-action@v4
  with:
    context: .
    platforms: linux/amd64,linux/arm64
    push: true
    tags: ${{ steps.metadata.outputs.tags }}
```

## 验证修复

### 1. 检查 WAR 文件内容

```bash
# 解压 WAR 文件检查
unzip -l docs-web/target/docs-web-*.war | grep index.html

# 应该看到 index.html 有实际大小（不是 0）
```

### 2. 检查容器内文件

```bash
# 检查容器内的文件大小
docker exec teedy_manual01 ls -lh /tmp/jetty-*/webapp/index.html

# 应该显示实际大小，不是 0
```

### 3. 测试前端页面

```bash
# 测试首页
curl -I http://localhost:8084/

# 应该返回 200 OK 和 Content-Length > 0
```

### 4. 浏览器访问

打开浏览器访问 `http://localhost:8084`，应该能看到 Teedy 登录页面。

## 临时解决方案（快速测试）

如果只是想快速测试，可以使用官方镜像：

```bash
# 使用官方镜像
docker run -d -p 8084:8080 --name teedy-official sismics/docs:latest

# 访问
open http://localhost:8084
```

## 为什么会出现这个问题？

1. **Maven Profile 的作用**：
   - 默认 profile：开发模式，前端资源未压缩
   - `prod` profile：生产模式，前端资源会被压缩和优化

2. **构建流程**：
   - `mvn package`：只打包后端代码
   - `mvn package -Pprod`：打包后端 + 构建和压缩前端资源

3. **Dockerfile 的问题**：
   - Dockerfile 直接复制 `docs-web/target/*.war`
   - 如果 WAR 文件是用 `mvn package` 构建的，前端资源会缺失

## 最佳实践

### 1. 多阶段 Dockerfile（推荐）

创建一个多阶段 Dockerfile，在镜像内部构建：

```dockerfile
# Stage 1: Build
FROM maven:3.8-openjdk-11 AS builder
WORKDIR /build
COPY . .
RUN mvn clean package -Pprod -DskipTests

# Stage 2: Runtime
FROM ubuntu:22.04
# ... (现有的运行时配置)
COPY --from=builder /build/docs-web/target/docs-web-*.war /app/webapps/docs.war
```

### 2. 更新 CI/CD 配置

确保所有 CI/CD 流程都使用 `-Pprod` profile：

**Jenkinsfile:**
```groovy
sh 'mvn package -Pprod -DskipTests'
```

**GitHub Actions:**
```yaml
run: mvn clean package -Pprod -DskipTests
```

### 3. 文档说明

在 README 中明确说明构建命令：

```markdown
## Building for Production

```bash
mvn clean package -Pprod -DskipTests
docker build -t earendelheng/teedy:latest .
```
```

## 总结

**问题**：前端资源文件大小为 0，导致页面空白  
**原因**：构建时未使用 `-Pprod` profile  
**解决**：使用 `mvn clean package -Pprod -DskipTests` 重新构建  

---

**创建时间**: 2026-05-26  
**问题状态**: 已识别，待修复
