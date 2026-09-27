pipeline {

    agent any

    environment {

        AWS_REGION = 'ap-south-1'

        ECR_REGISTRY = '024757002695.dkr.ecr.ap-south-1.amazonaws.com'

        BACKEND_REPO = 'nutriflow-backend'
        FRONTEND_REPO = 'nutriflow-frontend'

        EKS_CLUSTER = 'nutriflow-cluster'

        SONARQUBE_SERVER = 'sonarqube'

        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        // =====================================================
        // 1. CHECKOUT
        // =====================================================

        stage('Checkout') {
            steps {
                checkout scm
            }
        }


        // =====================================================
        // 2. TERRAFORM
        // =====================================================

        stage('Terraform Init') {
            steps {
                
                    sh 'terraform init'
                }
            }
        

        stage('Terraform Plan') {
            steps {
                
                    sh 'terraform plan'
                }
            }
        

        stage('Terraform Apply') {
            steps {
                
                    sh 'terraform apply -auto-approve'
                }
            }
        


        // =====================================================
        // 3. SONARQUBE
        // =====================================================

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {

                    sh '''
                        sonarscanner \
                        -Dsonar.projectKey=nutriflow \
                        -Dsonar.projectName=NutriFlow \
                        -Dsonar.sources=backend,frontend \
                        -Dsonar.exclusions=**/node_modules/**,**/dist/**,**/public/**
                    '''
                }
            }
        }


        // =====================================================
        // 4. DOCKER BUILD - BACKEND
        // =====================================================

        stage('Build Backend Image') {
            steps {
                sh """
                    docker build \
                    --target backend \
                    -t ${ECR_REGISTRY}/${BACKEND_REPO}:${IMAGE_TAG} \
                    .
                """
            }
        }


        // =====================================================
        // 5. DOCKER BUILD - FRONTEND
        // =====================================================

        stage('Build Frontend Image') {
            steps {
                sh """
                    docker build \
                    --target frontend \
                    -t ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG} \
                    .
                """
            }
        }


        // =====================================================
        // 6. LOGIN TO ECR
        // =====================================================

        stage('Login to ECR') {
            steps {
                sh """
                    aws ecr get-login-password \
                    --region ${AWS_REGION} | \
                    docker login \
                    --username AWS \
                    --password-stdin ${ECR_REGISTRY}
                """
            }
        }


        // =====================================================
        // 7. PUSH BACKEND IMAGE
        // =====================================================

        stage('Push Backend Image') {
            steps {
                sh """
                    docker push \
                    ${ECR_REGISTRY}/${BACKEND_REPO}:${IMAGE_TAG}
                """
            }
        }


        // =====================================================
        // 8. PUSH FRONTEND IMAGE
        // =====================================================

        stage('Push Frontend Image') {
            steps {
                sh """
                    docker push \
                    ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}
                """
            }
        }


        // =====================================================
        // 9. UPDATE KUBERNETES MANIFEST
        // =====================================================

        stage('Update Kubernetes Manifest') {
            steps {

                sh """
                    sed -i \
                    's|ECR_BACKEND_IMAGE|${ECR_REGISTRY}/${BACKEND_REPO}:${IMAGE_TAG}|g' \
                    k8s/deployment.yaml

                    sed -i \
                    's|ECR_FRONTEND_IMAGE|${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}|g' \
                    k8s/deployment.yaml
                """
            }
        }


        // =====================================================
        // 10. PUSH UPDATED MANIFEST TO GIT
        // =====================================================

        stage('Push Updated Manifest') {
            steps {

                sh '''
                    git config user.name "Jenkins"
                    git config user.email "jenkins@localhost"

                    git add k8s/deployment.yaml

                    git commit -m "Update NutriFlow image tags [skip ci]" || true

                    git push origin HEAD:main
                '''
            }
        }
    }


    // =========================================================
    // POST ACTIONS
    // =========================================================

    post {

        success {
            echo 'NutriFlow pipeline completed successfully.'
            echo 'ArgoCD will detect the updated Kubernetes manifest.'
        }

        failure {
            echo 'NutriFlow pipeline failed.'
        }

        always {
            sh 'docker system prune -f || true'
        }
    }
}
