pipeline {
    agent any

    environment {
        DOCKER_HUB_CREDENTIALS = 'dockerhub_credentials'
        DOCKER_IMAGE = 'earendelheng/teedy'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Clean') {
            steps {
                sh 'mvn clean'
            }
        }

        stage('Compile') {
            steps {
                sh 'mvn compile'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test -Dmaven.test.failure.ignore=true -Dsurefire.failIfNoSpecifiedTests=false'
            }
        }

        stage('PMD') {
            steps {
                sh 'mvn pmd:pmd'
            }
        }

        stage('JaCoCo') {
            steps {
                sh 'mvn jacoco:report'
            }
        }

        stage('Javadoc') {
            steps {
                sh 'mvn javadoc:javadoc'
            }
        }

        stage('Site') {
            steps {
                sh 'mvn site'
            }
        }

        stage('Package') {
            steps {
                sh 'mvn package -Pprod -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                    sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', DOCKER_HUB_CREDENTIALS) {
                        sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                        sh "docker push ${DOCKER_IMAGE}:latest"
                    }
                }
            }
        }

        stage('Run Containers') {
            steps {
                script {
                    sh 'docker stop teedy-container-8082 || true'
                    sh 'docker rm teedy-container-8082 || true'
                    sh 'docker stop teedy-container-8083 || true'
                    sh 'docker rm teedy-container-8083 || true'
                    sh 'docker stop teedy-container-8084 || true'
                    sh 'docker rm teedy-container-8084 || true'

                    sh "docker run -d -p 8082:8080 --name teedy-container-8082 ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    sh "docker run -d -p 8083:8080 --name teedy-container-8083 ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    sh "docker run -d -p 8084:8080 --name teedy-container-8084 ${DOCKER_IMAGE}:${DOCKER_TAG}"

                    sh 'docker ps --filter "name=teedy-container"'
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/target/site/**/*.*', fingerprint: true
            archiveArtifacts artifacts: '**/target/**/*.jar', fingerprint: true
            archiveArtifacts artifacts: '**/target/**/*.war', fingerprint: true
            junit '**/target/surefire-reports/*.xml'
        }
    }
}
