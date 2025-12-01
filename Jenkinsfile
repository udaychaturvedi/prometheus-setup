pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-creds').username
        AWS_SECRET_ACCESS_KEY = credentials('aws-creds').password
        TF_IN_AUTOMATION      = "true"
        ANSIBLE_HOST_KEY_CHECKING = "False"
    }

    stages {

        stage('Checkout') {
            steps {
                git credentialsId: 'git-creds', url: 'https://github.com/udaychaturvedi/prometheus-setup.git', branch: 'main'
            }
        }

        stage('Setup SSH Agent') {
            steps {
                sshagent(credentials: ['4c88630f-7f20-4587-88d7-7b4aca7edaf3']) {
                    sh 'echo "SSH agent is configured"'
                }
            }
        }

        stage('Terraform Init') {
            steps {
                sh '''
                cd terraform
                terraform init -input=false
                '''
            }
        }

        stage('Terraform Plan') {
            steps {
                sh '''
                cd terraform
                terraform plan -out=tfplan -input=false
                '''
            }
        }

        stage('Terraform Apply') {
            steps {
                sh '''
                cd terraform
                terraform apply -input=false -auto-approve tfplan
                '''
            }
        }

        stage('Generate Dynamic Inventory') {
            steps {
                sh '''
                cd ansible
                ansible-inventory -i inventory.aws_ec2.yml --graph
                '''
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                sshagent(credentials: ['4c88630f-7f20-4587-88d7-7b4aca7edaf3']) {
                    sh '''
                    cd ansible
                    ansible-playbook -i inventory.aws_ec2.yml playbook.yml
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                echo "Checking Prometheus health..."
                curl -I http://$(terraform -chdir=terraform output -raw nginx_public_ip)/
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/terraform/*.tfstate', fingerprint: true
            echo "❌ Pipeline finished with status: ${currentBuild.currentResult}"
        }
    }
}
