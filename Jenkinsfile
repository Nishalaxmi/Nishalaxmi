
pipeline {
    agent any

    environment {
        DOCKER_TOKEN = credentials('docker-cred')
        DOCKER_USERNAME = "dinesh10275"
        DOCKER_REGISTRY = "docker.io"
        DOCKER_IMAGE_NAME = "dinesh10275/dev-backend"
        DOCKER_IMAGE_TAG = "${env.BUILD_NUMBER}" // Set Docker image tag to Jenkins build number
        DEPLOYMENT_REPO_URL = "https://github.com/TheTym-ProjectManagement/kubernetes-argocd-deployement.git"
        GIT_CREDENTIALS_ID = "Git-cred"
        APPLICATION_NAME = "dev-backend"
        ARGOCD_SERVER_URL = "13.126.156.63:30866"
        ARGOCD_USERNAME = "admin"
        ARGOCD_PASSWORD = "thetymapplication@2024*"
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

        stage('Docker Build') {
            steps {
                script {
                    // Build Docker image
                    dockerImage = docker.build("${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:kv0.${DOCKER_IMAGE_TAG}", ".")
                }
            }
        }

        stage('Docker Push') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-cred', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_TOKEN')]) {
                        sh "docker login -u ${env.DOCKER_USERNAME} -p ${env.DOCKER_TOKEN} ${DOCKER_REGISTRY}"
                        sh "docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:kv0.${DOCKER_IMAGE_TAG}"
                    }
                }
            }
        }
        stage('Update Deployment YAML and Push Changes') {
            steps {
                script {
                    // Clone the deployment repository with the 'Backend' branch
                    git branch: 'Backend', credentialsId: 'Git-cred', url: "${DEPLOYMENT_REPO_URL}"

                    // Update the deployment YAML file with the new Docker image tag
                    if (isUnix()) {
                        sh """sed -i 's|image:.*|image: ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:kv0.${DOCKER_IMAGE_TAG}|' rollout.yml"""
                    } else {
                        bat """sed -i 's|image:.*|image: ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:kv0.${DOCKER_IMAGE_TAG}|' rollout.yml"""
                    }

                    // Add and commit the changes
                    sh "git add rollout.yml"
                    sh "git commit -m 'Update Docker image tag in rollout.yml'"

                    // Verify the contents of deployment.yml after changes and commit
                    sh "cat rollout.yml"

                    // Push the changes with credentials in the URL
                    withCredentials([usernamePassword(credentialsId: 'Git-cred', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_TOKEN')]) {
                        sh "git config user.name 'Jenkins'"
                        sh "git config user.email 'jenkins@example.com'"
                        // Push the changes from the 'Backend' branch
                        sh "git push --force https://${env.DOCKER_USERNAME}:${env.DOCKER_TOKEN}@github.com/TheTym-ProjectManagement/kubernetes-argocd-deployement.git HEAD:Backend"
                    }
                }
            }
        }

        stage('Sync Argo CD Application') {
            steps {
                script {
                    // Log in to Argo CD
                    sh "argocd login ${ARGOCD_SERVER_URL} --insecure --username ${ARGOCD_USERNAME} --password ${ARGOCD_PASSWORD}"

                    // Sync the application to apply changes
                    sh "argocd app sync ${APPLICATION_NAME}"
                }
            }
        }
    }
    
    post {
        success {
            emailext(
                subject: "Build Successful: ${env.JOB_NAME} #kv0.${env.BUILD_NUMBER}",
                body: "The build succeeded. Congratulations!\n\nBuild URL: ${env.BUILD_URL}",
                to: 'dinesh@thetym.com',
                attachLog: true
            )
            slackSend(
                color: '#36a64f', // Green color for success
                message: "Build Successful: ${env.JOB_NAME} #kv0.${env.BUILD_NUMBER}\n\nBuild URL: ${env.BUILD_URL}",
                channel: '#jenkins-notifications' // Replace with your Slack channel name
            )
        }
        failure {
            emailext(
                subject: "Build Failed: ${env.JOB_NAME} #kv0.${env.BUILD_NUMBER}",
                body: "The build failed. Please check the Jenkins console output for more details.\n\nBuild URL: ${env.BUILD_URL}",
                to: 'dinesh@thetym.com',
                attachLog: true
            )
            slackSend(
                color: '#ff0000', // Red color for failure
                message: "Build Failed: ${env.JOB_NAME} #kv0.${env.BUILD_NUMBER}\n\nBuild URL: ${env.BUILD_URL}",
                channel: '#jenkins-notifications' // Replace with your Slack channel name
            )
        }
    }
}
