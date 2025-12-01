pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        SSH_KEY_PATH = "/var/lib/jenkins/.ssh/prometheus.pem"
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/main"]],
                    userRemoteConfigs: [[
                        url: 'https://github.com/udaychaturvedi/prometheus-setup',
                        credentialsId: 'git-creds'
                    ]]
                ])
            }
        }

        stage('Load AWS Credentials') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh 'echo [INFO] AWS credentials loaded'
                }
            }
        }

        stage('Extract SSH Private Key') {
            steps {
                echo "[INFO] Extracting SSH key to Jenkins home"

                withCredentials([sshUserPrivateKey(
                    credentialsId: 'a69af01d-c489-495b-86e1-a646fea4f6e6',
                    keyFileVariable: 'SSH_KEY_TEMP'
                )]) {

                    sh '''
                        mkdir -p /var/lib/jenkins/.ssh
                        cp $SSH_KEY_TEMP /var/lib/jenkins/.ssh/prometheus.pem
                        chmod 600 /var/lib/jenkins/.ssh/prometheus.pem
                        echo "[INFO] SSH key installed at ${SSH_KEY_PATH}"
                    '''
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    dir('terraform') {
                        sh """
                            echo "[INFO] Terraform init"
                            terraform init -input=false
                        """
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    dir('terraform') {
                        sh """
                            echo "[INFO] Terraform plan"
                            terraform plan -out=tfplan
                        """
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    dir('terraform') {
                        sh """
                            echo "[INFO] Terraform apply"
                            terraform apply -auto-approve tfplan
                        """
                    }
                }
            }
        }

        stage('Export Bastion IP') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {

                    script {
                        env.BASTION_IP = sh(
                            script: "terraform -chdir=terraform output -raw bastion_public_ip",
                            returnStdout: true
                        ).trim()
                    }

                    echo "[INFO] Bastion Public IP = ${env.BASTION_IP}"
                }
            }
        }

        stage('Prepare SSH Config') {
            steps {
                sh '''
                    echo "[INFO] Creating SSH config"

                    mkdir -p /var/lib/jenkins/.ssh

                    cat > /var/lib/jenkins/.ssh/config <<EOF
Host bastion
    HostName ${BASTION_IP}
    User ubuntu
    IdentityFile ${SSH_KEY_PATH}
    StrictHostKeyChecking no

Host 10.*
    User ubuntu
    IdentityFile ${SSH_KEY_PATH}
    ProxyCommand ssh -W %h:%p bastion
    StrictHostKeyChecking no
EOF

                    chmod 600 /var/lib/jenkins/.ssh/config
                '''
            }
        }

        stage('Generate Dynamic Inventory') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh '''
                        echo "[INFO] Checking inventory"
                        ansible-inventory -i ansible/inventory.aws_ec2.yml --list
                    '''
                }
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                sshagent(['a69af01d-c489-495b-86e1-a646fea4f6e6']) {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                        sh '''
                            echo "[INFO] Running playbook"
                            ansible-playbook -i ansible/inventory.aws_ec2.yml ansible/playbook.yml -u ubuntu
                        '''
                    }
                }
            }
        }
    }

    post {
        failure { echo "❌ Pipeline failed." }
        success { echo "✅ Pipeline completed successfully." }
    }
}
