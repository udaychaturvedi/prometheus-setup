pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = "true"
        ANSIBLE_CONFIG = "ansible/ansible.cfg"
    }

    stages {

        /* --------------------------
         * CHECKOUT MAIN REPOSITORY
         * -------------------------- */
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

        /* --------------------------
         * AWS CREDENTIALS LOADED
         * -------------------------- */
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

        /* --------------------------
         * TERRAFORM INIT
         * -------------------------- */
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

        /* --------------------------
         * TERRAFORM PLAN
         * -------------------------- */
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

        /* --------------------------
         * TERRAFORM APPLY
         * -------------------------- */
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

        /* --------------------------------------------------
         * EXPORT BASTION IP (FIXED BLOCK with credentials!)
         * -------------------------------------------------- */
        stage('Export Bastion IP') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    dir('terraform') {
                        script {
                            env.BASTION_IP = sh(
                                returnStdout: true,
                                script: "terraform output -raw bastion_public_ip"
                            ).trim()
                        }
                    }
                    sh 'echo "[INFO] Bastion Public IP = ${BASTION_IP}"'
                }
            }
        }

        /* --------------------------------------------------
         * PREPARE SSH CONFIG FOR ANSIBLE
         * -------------------------------------------------- */
        stage('Prepare SSH Config') {
            steps {
                sh '''
                echo "[INFO] Creating SSH config for bastion proxy"
                mkdir -p ~/.ssh

cat <<EOF > ~/.ssh/config
Host bastion
    HostName ${BASTION_IP}
    User ubuntu
    IdentityFile ~/.ssh/prometheus.pem

Host 10.10.*.*
    ProxyCommand ssh -W %h:%p bastion
    User ubuntu
    IdentityFile ~/.ssh/prometheus.pem
EOF

                chmod 600 ~/.ssh/config
                '''
            }
        }

        /* --------------------------
         * GENERATE DYNAMIC INVENTORY
         * -------------------------- */
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

        /* --------------------------
         * RUN ANSIBLE PLAYBOOK (BASTION JUMP HOST)
         * -------------------------- */
        stage('Run Ansible Playbook') {
            steps {
                sshagent (credentials: ['ubuntu']) {
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
        success {
            echo "🎉 Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed."
        }
    }
}
