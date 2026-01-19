pipeline {
    agent any
    tools {
        jdk 'jdk17'
        maven 'maven3'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        DOCKER_USRN = 'mahmoud58'
        IMAGE_NAME = "${DOCKER_USRN}/boardgame:${env.BUILD_NUMBER}"
    }
    stages {
        stage('Git Checkout') {
            steps {
              git branch: 'main', credentialsId: 'git_cred', url: 'https://github.com/mahmoudSh58/Boardgame.git'  
            }
        }
        stage('Compile') {
            steps {
                sh 'mvn compile'
            }
        }
        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
        stage('File System Scan') {
            steps {
                sh 'trivy fs --format template --template "@/usr/local/share/trivy/templates/html.tpl" -o trivy-fs-report.html .'
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=BoardGame -Dsonar.projectKey=BoardGame \
                      -Dsonar.java.binaries=. '''
                }
            }
        }
        stage('Quailty Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                     waitForQualityGate abortPipeline: true
                }
            }
        }
        stage('Build') {
            steps {
                sh 'mvn -DskipTests package'
            }
        }
        stage('Publish To nexus') {
            steps {
                withMaven(mavenSettingsConfig: 'nexus-maven-file') {
                    sh 'mvn deploy -DskipTests'
                }
            }
        }
        stage('Build & Tag Docker Image') {
            steps {
                sh 'docker build -t ${IMAGE_NAME} .'
            }
        }
        stage('Image Scan') {
            steps {
                sh 'trivy image --format template --template "@/usr/local/share/trivy/templates/html.tpl" -o trivy-Image-report.html $DOCKER_USRN/boardgame:${BUILD_NUMBER}'
            }
        } 
        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'Docker_cred', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USR')]) {
                    sh 'echo "$DOCKER_PASS" | docker login -u $DOCKER_USR --password-stdin'
                    sh 'docker push  ${IMAGE_NAME}'
                }
            }
        }
        stage('K8S deploy') {
            steps {
                withKubeConfig(caCertificate: '', clusterName: 'kubernetes', contextName: '', credentialsId: 'k8s-cred', namespace: 'myapp', restrictKubeConfigAccess: false, serverUrl: 'https://172.31.40.18:6443') {
                    sh 'envsubst < deployment-service.yaml |kubectl apply -f -'
                    sleep time: 3, unit: 'SECONDS'
                }
            }
        }
        stage('Verify K8S deploy') {
            steps {
                withKubeConfig(caCertificate: '', clusterName: 'kubernetes', contextName: '', credentialsId: 'k8s-cred', namespace: 'myapp', restrictKubeConfigAccess: false, serverUrl: 'https://172.31.40.18:6443') {
                    sh 'kubectl rollout status deployment/boardgame-deployment --timeout=120s -n myapp'
                    sleep time: 5, unit: 'SECONDS'
                    sh 'kubectl wait pod -l app=boardgame --for=condition=Ready --timeout=120s -n myapp'
                    sh 'kubectl get pods'
                    sh 'kubectl get svc'

                }
            }
        }
    }
    post {
        always {
            script {
            def jobName = env.JOB_NAME
            def buildNumber = env.BUILD_NUMBER
            def pipelineStatus = currentBuild.result ?: 'UNKNOWN'
            def bannerColor = pipelineStatus.toUpperCase() == 'SUCCESS' ? 'green' : 'red'

            def body = """
                <html>
                <body>
                <div style="border: 4px solid ${bannerColor}; padding: 10px;">
                <h2>${jobName} - Build ${buildNumber}</h2>
                <div style="background-color: ${bannerColor}; padding: 10px;">
                <h3 style="color: white;">Pipeline Status: ${pipelineStatus.toUpperCase()}</h3>
                </div>
                <p>Check the <a href="${BUILD_URL}">console output</a>.</p>
                </div>
                </body>
                </html>
            """

            emailext (
                subject: "${jobName} - Build ${buildNumber} - ${pipelineStatus.toUpperCase()}",
                body: body,
                to: 'mahmoudsharif914@gmail.com',
                mimeType: 'text/html',
                attachmentsPattern: 'trivy-image-report.html'
            )
        }
        }
    }
}
