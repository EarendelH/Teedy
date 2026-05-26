# 快速解决 Docker 空白页面问题

## 问题原因

Docker 镜像中的前端资源文件（index.html, docs.min.js）大小为 0，因为构建时没有使用 `-Pprod` profile。

## 快速解决方案

### 方案 1: 使用官方镜像（最快）

```bash
# 停止当前容器
docker stop teedy_manual01
docker rm teedy_manual01

# 使用官方镜像
docker run -d -p 8084:8080 --name teedy-official sismics/docs:latest

# 等待启动
sleep 30

# 访问
open http://localhost:8084
```

### 方案 2: 本地运行（开发模式）

```bash
# 使用 Maven 直接运行
cd /Users/earendelh/Documents/junior_second/SoftEngineering/Labs/lab2/Teedy
mvn jetty:run -pl docs-web

# 访问 http://localhost:8080
```

### 方案 3: 修复并重新构建（完整方案）

#### 步骤 1: 更新 Jenkinsfile

修改 `Jenkinsfile` 的 Package 阶段：

```groovy
stage('Package') {
    steps {
        sh 'mvn package -Pprod -DskipTests'  // 添加 -Pprod
    }
}
```

#### 步骤 2: 更新 GitHub Actions

修改 `.github/workflows/docker-image.yml`：

```yaml
- name: Build with Maven (Production)
  run: mvn clean package -Pprod -DskipTests

- name: Build and push
  uses: docker/build-push-action@v4
  with:
    context: .
    platforms: linux/amd64,linux/arm64
    push: true
    tags: ${{ steps.metadata.outputs.tags }}
```

#### 步骤 3: 推送更新并触发构建

```bash
git add Jenkinsfile .github/workflows/docker-image.yml
git commit -m "Fix: Add -Pprod profile to build frontend resources"
git push origin master
```

等待 GitHub Actions 构建完成后，新的镜像就会包含完整的前端资源。

## 验证

### 检查 WAR 文件内容

```bash
# 检查本地 WAR 文件
unzip -l docs-web/target/docs-web-*.war | grep -E "index.html|docs.min.js"

# 应该看到实际大小，不是 0
```

### 测试新镜像

```bash
# 拉取新镜像
docker pull earendelheng/teedy:latest

# 运行
docker run -d -p 8084:8080 --name teedy-test earendelheng/teedy:latest

# 检查文件大小
docker exec teedy-test ls -lh /tmp/jetty-*/webapp/index.html

# 访问
open http://localhost:8084
```

## 为什么需要 -Pprod？

Maven 的 `prod` profile 会：
1. 编译和压缩前端 JavaScript 代码
2. 优化 CSS 文件
3. 生成生产环境配置
4. 将所有资源打包到 WAR 文件中

没有 `-Pprod`，前端资源不会被构建，导致 WAR 文件中的前端文件为空。

## 当前状态

- ✅ 已识别问题：缺少 `-Pprod` profile
- ✅ 已创建修复文档
- ⏳ 待更新：Jenkinsfile 和 GitHub Actions
- ⏳ 待重新构建：Docker 镜像

## 下一步

1. 更新 CI/CD 配置文件
2. 推送到 GitHub
3. 等待自动构建完成
4. 测试新镜像

---

**临时解决方案**：使用官方镜像 `sismics/docs:latest` 进行测试。
