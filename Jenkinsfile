pipeline {
    agent any

    environment {
        TF_WORKSPACE = "${WORKSPACE}/terraform"
        ANSIBLE_DIR  = "${WORKSPACE}/ansible"
        SSH_KEY_PATH = "/var/lib/jenkins/.ssh/prometheus.pem"
    }

    stages {

        /* ---------------------------- CHECKOUT ---------------------------- */
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

        /* ---------------------------- AWS CREDS ---------------------------- */
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

        /* ---------------------------- TERRAFORM INIT ---------------------------- */
        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-creds'
                    ]]) {
                        sh '''
                            echo "[INFO] Terraform init"
                            terraform init -input=false
                        '''
                    }
                }
            }
        }

        /* ---------------------------- TERRAFORM PLAN ---------------------------- */
        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-creds'
                    ]]) {
                        sh '''
                            echo "[INFO] Terraform plan"
                            terraform plan -out=tfplan
                        '''
                    }
                }
            }
        }

        /* ---------------------------- TERRAFORM APPLY ---------------------------- */
        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-creds'
                    ]]) {
                        sh '''
                            echo "[INFO] Terraform apply"
                            terraform apply -auto-approve tfplan
                        '''
                    }
                }
            }
        }

        /* ---------------------------- BASTION IP ---------------------------- */
        stage('Export Bastion IP') {
            steps {
                script {
                    BASTION_IP = sh(
                        script: "terraform -chdir=terraform output -raw bastion_public_ip",
                        returnStdout: true
                    ).trim()
                    echo "[INFO] Bastion Public IP = ${BASTION_IP}"
                }
            }
        }

        /* ---------------------------- SSH CONFIG ---------------------------- */
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
    ProxyCommand ssh -i ${SSH_KEY_PATH} ubuntu@${BASTION_IP} -W %h:%p
    StrictHostKeyChecking no
EOF

                    chmod 600 /var/lib/jenkins/.ssh/config
                '''
            }
        }

        /* ---------------------------- ANSIBLE ---------------------------- */
        stage('Run Ansible Playbook') {
            steps {
                sshagent(credentials: ['ssh-key-prometheus']) {
                    sh '''
                        echo "[INFO] Running Ansible Playbook"
                        ansible-playbook -i ansible/inventory.aws_ec2.yml ansible/site.yml
                    '''
                }
            }
        }
    }

    post {
        failure { echo "❌ Pipeline failed." }
        success { echo "✅ Pipeline completed successfully!" }
    }
}
