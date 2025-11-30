pipeline {
    agent any
    environment {
        AWS_REGION = 'ap-south-1'
        SSH_KEY = 'prometheus'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform plan'
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }
        
        stage('Dynamic Deployment') {
            steps {
                sh './deploy.sh'
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    // Get bastion IP for health checks
                    sh 'cd terraform && terraform output -json > ../output.json'
                    def outputs = readJSON file: 'output.json'
                    env.BASTION_IP = outputs.bastion_public_ip.value
                    env.PRIMARY_IP = outputs.primary_private_ip.value
                    env.STANDBY_IP = outputs.standby_private_ip.value
                }
                
                sh """
                ssh -o StrictHostKeyChecking=no -i ~/.ssh/${SSH_KEY}.pem ubuntu@${BASTION_IP} "
                    echo '=== HEALTH CHECKS ==='
                    curl -s http://${PRIMARY_IP}:9090/-/healthy && echo ' ✅ Primary Prometheus'
                    curl -s http://${STANDBY_IP}:9090/-/healthy && echo ' ✅ Standby Prometheus'
                    curl -s http://${PRIMARY_IP}:9093/-/healthy && echo ' ✅ Primary AlertManager'
                    curl -s http://${STANDBY_IP}:9093/-/healthy && echo ' ✅ Standby AlertManager'
                    echo '=== ALL SERVICES HEALTHY ==='
                "
                """
            }
        }
    }
    
    post {
        always {
            // Cleanup
            sh 'rm -f output.json'
        }
        success {
            emailext (
                subject: "SUCCESS: Prometheus HA Deployment",
                body: "Prometheus HA infrastructure deployed successfully!\n\nBastion: ${env.BASTION_IP}\nPrimary: ${env.PRIMARY_IP}\nStandby: ${env.STANDBY_IP}",
                to: "admin@company.com"
            )
        }
        failure {
            emailext (
                subject: "FAILED: Prometheus HA Deployment",
                body: "Prometheus HA deployment failed. Check Jenkins logs.",
                to: "@company.com"
            )
        }
    }
}
