pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        SSH_KEY = "~/.ssh/prometheus.pem"
        ANSIBLE_CONFIG = "ansible/ansible.cfg"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/udaychaturvedi/prometheus-setup.git'
            }
        }

        stage('Setup SSH Agent') {
            steps {
                sshagent(credentials: ['4c88630f-7f20-4587-88d7-7b4aca7edaf3']) {
                    sh "chmod 600 ${SSH_KEY}"
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh """
                        terraform init -input=false
                    """
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh """
                        terraform plan -out=tfplan -input=false
                    """
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh """
                        terraform apply -input=false -auto-approve tfplan
                    """
                }
            }
        }

        stage('Generate Dynamic Inventory') {
            steps {
                sh """
                    ansible-inventory \
                      -i ansible/inventory.aws_ec2.yml \
                      --list > inventory_output.json
                """
                archiveArtifacts artifacts: 'inventory_output.json', fingerprint: true
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                sshagent(credentials: ['prometheus-ssh-key']) {
                    sh """
                        ansible-playbook \
                          -i ansible/inventory.aws_ec2.yml \
                          ansible/playbook.yml
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                sh """
                    PROM_IP=\$(aws ec2 describe-instances \
                        --filters "Name=tag:Role,Values=prometheus_primary" \
                        --query "Reservations[].Instances[].PrivateIpAddress" \
                        --output text)

                    echo "Checking Prometheus at: \$PROM_IP"

                    curl -I http://\$PROM_IP:9090/-/healthy
                """
            }
        }
    }

    post {
        success {
            echo "🎉 Deployment pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed. Check logs."
        }
        always {
            archiveArtifacts artifacts: '**/*.log', allowEmptyArchive: true
        }
    }
}
