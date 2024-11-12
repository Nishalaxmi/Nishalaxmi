pipeline {
    agent any
    
    environment {
        DOCKER_PASSWORD = credentials('docker-cred')
        DOCKER_USERNAME = "dinesh10275"
        DOCKER_REGISTRY = "docker.io"
        DOCKER_IMAGE_NAME = "dinesh10275/dev-backend"
        GITHUB_REPO_URL = "https://github.com/TheTym-ProjectManagement/dev-backend.git"
        GIT_CREDENTIALS_ID = "Git-cred"
        STACK_NAME = "backend-dev-stack"
    }

    stages {

        stage('Static Code Analysis') {
            steps {
                script {
		    sh "mvn clean install"
                    sh "mvn sonar:sonar -Dsonar.login=sqa_258c854cca5fd8f951c577ecbfc92a5b933f6a48 -Dsonar.host.url=http://13.126.156.63:9001/ -Dsonar.java.binaries=target/classes"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:v0.${BUILD_NUMBER}", ".")
                }
            }
        }

        stage('Docker Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-cred', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    script {
                        def dockerImageTag = "${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:v0.${BUILD_NUMBER}"
                        sh "docker login -u ${env.DOCKER_USERNAME} -p ${env.DOCKER_PASSWORD} ${DOCKER_REGISTRY}"
                        sh "docker push ${dockerImageTag}"
                    }
                }
            }
        }

        stage('Update Deployment YAML') {
            steps {
                script {
                    // Update the docker-compose.yml file with the new Docker image tag
                    if (isUnix()) {
                        sh """sed -i 's|image:.*|image: ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:v0.${BUILD_NUMBER}|' docker-compose.yml"""
                    } else {
                        bat """sed -i 's|image:.*|image: ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:v0.${BUILD_NUMBER}|' docker-compose.yml"""
                    }

                    // Commit the changes1
                    sh "git add docker-compose.yml"
                    sh "git commit -m 'Update Docker image tag in docker-compose.yml'"

                    // Push the changes with credentials in the URL
                    withCredentials([usernamePassword(credentialsId: 'Git-cred', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh "git config user.name 'Jenkins'"
                        sh "git config user.email 'jenkins@example.com'"
                        sh "git push https://${env.DOCKER_USERNAME}:${env.DOCKER_PASSWORD}@github.com/TheTym-ProjectManagement/dev-backend.git HEAD:main"
                    }
                }
            }
        }

        stage('Update Service Image swarm') {
            steps {
                script {
                    // Update the Docker service with the new image tag
                    sh "docker stack deploy --with-registry-auth --compose-file docker-compose.yml ${STACK_NAME}"
                }
            }
        }
    }

    post {
        success {
            emailext(
                subject: "Build Successful: ${env.JOB_NAME} #v0.${env.BUILD_NUMBER}",
                body: "The build succeeded. Congratulations!\n\nBuild URL: ${env.BUILD_URL}",
                to: 'dinesh@thetym.com,ramesh@thetym.com',
                attachLog: true
            )
            slackSend(
                color: '#36a64f', // Green color for success
                message: "Build Successful: ${env.JOB_NAME} #v0.${env.BUILD_NUMBER}\n\nBuild URL: ${env.BUILD_URL}",
                channel: '#jenkins-notifications' // Replace with your Slack channel name
            )
        }
        failure {
            emailext(
                subject: "Build Failed: ${env.JOB_NAME} #v0.${env.BUILD_NUMBER}",
                body: "The build failed. Please check the Jenkins console output for more details.\n\nBuild URL: ${env.BUILD_URL}",
                to: 'dinesh@thetym.com,ramesh@thetym.com',
                attachLog: true
            )
            slackSend(
                color: '#ff0000', // Red color for failure
                message: "Build Failed: ${env.JOB_NAME} #v0.${env.BUILD_NUMBER}\n\nBuild URL: ${env.BUILD_URL}",
                channel: '#jenkins-notifications' // Replace with your Slack channel name
            )
        }
    }
}
