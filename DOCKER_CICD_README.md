# Practice 10 - CI/CD with Jenkins and Docker

## Overview
This project implements CI/CD pipeline for Teedy application using Jenkins and Docker, as well as GitHub Actions as an alternative.

## Requirements
- Build a Docker image by Jenkins
- Push to Docker Hub by Jenkins
- Run three containers by Jenkins on ports: 8082, 8083, 8084

## Setup Instructions

### Option 1: Using Jenkins

#### Prerequisites
1. Jenkins installed with Docker Pipeline plugin
2. Docker installed on Jenkins server
3. Docker Hub account

#### Step 1: Configure Jenkins
1. Install "Docker Pipeline" plugin in Jenkins
   - Go to "Manage Jenkins" → "Manage Plugins" → "Available Plugins"
   - Search for "Docker Pipeline" and install it

2. Configure Docker Hub credentials in Jenkins
   - Go to "Manage Jenkins" → "Manage Credentials" → "System" → "Global credentials"
   - Add new credentials:
     - Kind: Username with password
     - ID: `dockerhub_credentials`
     - Username: Your Docker Hub username
     - Password: Your Docker Hub password or access token

#### Step 2: Jenkinsfile Configuration
The `DOCKER_IMAGE` environment variable in `Jenkinsfile` is already configured:
```groovy
environment {
    DOCKER_HUB_CREDENTIALS = 'dockerhub_credentials'
    DOCKER_IMAGE = 'earendelheng/teedy'
    DOCKER_TAG = "${env.BUILD_NUMBER}"
}
```

#### Step 3: Create Jenkins Pipeline
1. Create a new Pipeline job in Jenkins
2. Configure the pipeline to use the `Jenkinsfile` from your repository
3. Run the pipeline

#### Pipeline Stages
The Jenkinsfile includes the following stages:
1. **Clean** - Clean previous builds
2. **Compile** - Compile the source code
3. **Test** - Run unit tests
4. **PMD** - Run static code analysis
5. **JaCoCo** - Generate code coverage reports
6. **Javadoc** - Generate API documentation
7. **Site** - Generate project site
8. **Package** - Package the application as WAR file
9. **Build Docker Image** - Build Docker image with tag
10. **Push to Docker Hub** - Push image to Docker Hub
11. **Run Containers** - Run three containers on ports 8082, 8083, 8084

### Option 2: Using GitHub Actions

#### Prerequisites
1. GitHub repository
2. Docker Hub account

#### Step 1: Configure GitHub Secrets
Go to your repository → Settings → Secrets and variables → Actions → New repository secret

Add the following secrets:
- `DOCKERHUB_USERNAME`: Your Docker Hub username
- `DOCKERHUB_TOKEN`: Your Docker Hub access token

#### Step 2: Workflow Configuration
The workflow file `.github/workflows/docker-image.yml` is already configured with:
```yaml
images: earendelheng/teedy
```

#### Step 3: Push to GitHub
Commit and push your changes to the `master` branch. The workflow will automatically:
1. Build the application with Maven
2. Build the Docker image
3. Push to Docker Hub

## Dockerfile
The `Dockerfile` is based on Ubuntu 22.04 and includes:
- Java 11 (OpenJDK)
- Jetty 11.0.20 web server
- Tesseract OCR with multiple language packs
- FFmpeg and mediainfo for media processing

## Running Containers Manually

### Build the Docker image:
```bash
docker build -t teedy:latest .
```

### Run three containers:
```bash
docker run -d -p 8082:8080 --name teedy-container-8082 teedy:latest
docker run -d -p 8083:8080 --name teedy-container-8083 teedy:latest
docker run -d -p 8084:8080 --name teedy-container-8084 teedy:latest
```

### Check running containers:
```bash
docker ps --filter "name=teedy-container"
```

### Access the application:
- Container 1: http://localhost:8082
- Container 2: http://localhost:8083
- Container 3: http://localhost:8084

### Stop and remove containers:
```bash
docker stop teedy-container-8082 teedy-container-8083 teedy-container-8084
docker rm teedy-container-8082 teedy-container-8083 teedy-container-8084
```

## Evaluation Checklist

To complete Practice 10, you need to show:

1. ✅ **Jenkins running result**
   - Screenshot of successful Jenkins pipeline execution
   - All stages should be green/successful

2. ✅ **Docker Hub repository**
   - Screenshot of your Docker Hub repository showing the pushed image
   - URL: https://hub.docker.com/r/earendelheng/teedy

3. ✅ **Three running containers**
   - Screenshot of `docker ps` command showing three containers running
   - Containers should be on ports 8082, 8083, 8084
   - All containers should be in "Up" status

## Troubleshooting

### Maven not found error in Jenkins
Configure Maven in Jenkins Global Tool Configuration:
1. Go to Jenkins Dashboard → System Manage → Global Tool Configuration
2. In the Maven section, add Maven installation
3. Name: M3 (or any name)
4. Install automatically: Check this box
5. Version: Select desired version (e.g., 3.8.7)
6. Save

Then update Jenkinsfile to use the tools directive:
```groovy
pipeline {
    agent any
    tools {
        maven 'M3'  // Use the name defined in Global Tool Configuration
    }
    // ... rest of the pipeline
}
```

### Docker permission denied
If Jenkins cannot access Docker, add Jenkins user to docker group:
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Port already in use
If ports 8082, 8083, or 8084 are already in use, stop the existing containers:
```bash
docker stop $(docker ps -q --filter "publish=8082")
docker stop $(docker ps -q --filter "publish=8083")
docker stop $(docker ps -q --filter "publish=8084")
```

## References
- Tutorial 10: Docker
- Practice 10: CI/CD with Jenkins and Docker
- Jenkins Documentation: https://www.jenkins.io/doc/
- Docker Documentation: https://docs.docker.com/
- GitHub Actions Documentation: https://docs.github.com/en/actions
