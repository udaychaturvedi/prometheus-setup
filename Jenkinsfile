pipeline {
    agent any

    environment {
        AWS_CREDS = credentials('aws-creds')   // Injects AWS_CREDS_USR and AWS_CREDS_PSW
        ANSIBLE_HOST_KEY_CHECKING = "False"
        TF_IN_AUTOMATION = "true"
    }

    stages {

        stage('Checkout') {
            steps {
                git credentialsId: 'git-creds',
                    url: 'https://github.com/udaychaturvedi/prometheus-setup.git',
                    branch: 'main'
            }
        }

        stage('Setup SSH Agent') {
            steps {
                sshagent(credentials: ['4c88630f-7f20-4587-88d7-7b4aca7edaf3']) {
                    sh 'echo "SSH agent configured"'
                }
            }
        }

        stage('Terraform Init') {
            steps {
                sh '''
                cd terraform
                export AWS_ACCESS_KEY_ID=$AWS_CREDS_USR
                export AWS_SECRET_ACCESS_KEY=$AWS_CREDS_PSW
                terraform init -input=false
                '''
            }
        }

        stage('Terraform Plan') {
            steps {
                sh '''
                cd terraform
                export AWS_ACCESS_KEY_ID=$AWS_CREDS_USR
                export AWS_SECRET_ACCESS_KEY=$AWS_CREDS_PSW
                terraform plan -out=tfplan -input=false
                '''
            }
        }

        stage('Terraform Apply') {
            steps {
                sh '''
                cd terraform
                export AWS_ACCESS_KEY_ID=$AWS_CREDS_USR
                export AWS_SECRET_ACCESS_KEY=$AWS_CREDS_PSW
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
                PUBLIC_IP=$(terraform -chdir=terraform output -raw nginx_public_ip)
                echo "Checking NGINX @ $PUBLIC_IP"
                curl -I http://$PUBLIC_IP/
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/*.tfstate', fingerprint: true
            echo "Pipeline finished with: ${currentBuild.currentResult}"
        }
    }
}
