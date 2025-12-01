pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/udaychaturvedi/prometheus-setup',
                        credentialsId: 'git-creds'
                    ]]
                ])
            }
        }

        stage('Load AWS Credentials') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    sh 'echo "[INFO] AWS credentials loaded"'
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    dir('terraform') {
                        sh '''
                            echo "[INFO] Terraform init"
                            terraform init -input=false
                        '''
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    dir('terraform') {
                        sh '''
                            echo "[INFO] Terraform plan"
                            terraform plan -out=tfplan
                        '''
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    dir('terraform') {
                        sh '''
                            echo "[INFO] Terraform apply"
                            terraform apply -auto-approve tfplan
                        '''
                    }
                }
            }
        }

        stage('Export Bastion IP') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    script {
                        env.BASTION_IP = sh(
                            script: "terraform -chdir=terraform output -raw bastion_public_ip",
                            returnStdout: true
                        ).trim()

                        echo "[INFO] Bastion Public IP = ${env.BASTION_IP}"
                    }
                }
            }
        }

        stage('Prepare SSH Config') {
            steps {
                sh '''
                    echo "[INFO] Creating SSH config for bastion proxy"
                    mkdir -p /var/lib/jenkins/.ssh

                    cat > /var/lib/jenkins/.ssh/config <<EOF
Host bastion
    HostName ${BASTION_IP}
    User ubuntu
    IdentityFile /var/lib/jenkins/.ssh/prometheus.pem

Host 10.*
    User ubuntu
    IdentityFile /var/lib/jenkins/.ssh/prometheus.pem
    ProxyCommand ssh -o StrictHostKeyChecking=no -W %h:%p bastion
EOF

                    chmod 600 /var/lib/jenkins/.ssh/config
                '''
            }
        }

        stage('Generate Dynamic Inventory') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    sh '''
                        echo "[INFO] Generating dynamic inventory"
                        ansible-inventory -i ansible/inventory.aws_ec2.yml --list
                    '''
                }
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                sshagent (credentials: ['a69af01d-c489-495b-86e1-a646fea4f6e6']) {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-creds'
                    ]]) {
                        sh '''
                            echo "[INFO] Running Ansible"
                            ansible-playbook -i ansible/inventory.aws_ec2.yml ansible/playbook.yml
                        '''
                    }
                }
            }
        }
    }

    post {
        failure {
            echo "❌ Pipeline failed."
        }
        success {
            echo "✅ Pipeline completed successfully."
        }
    }
}
