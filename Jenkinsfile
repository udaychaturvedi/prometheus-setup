pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
    }

    stages {

        /* -------------------------------
         *  CHECKOUT REPOSITORY
         * ------------------------------- */
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/udaychaturvedi/prometheus-setup.git',
                        credentialsId: 'git-creds'
                    ]]
                ])
            }
        }

        /* -------------------------------
         *  LOAD AWS CREDENTIALS
         * ------------------------------- */
        stage('Load AWS Credentials') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-creds']
                ]) {
                    sh 'echo "[INFO] AWS credentials loaded"'
                }
            }
        }

        /* -------------------------------
         *  TERRAFORM INIT
         * ------------------------------- */
        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: 'aws-creds']]) {
                    dir('terraform') {
                        sh """
                        echo "[INFO] Terraform init"
                        terraform init -input=false
                        """
                    }
                }
            }
        }

        /* -------------------------------
         *  TERRAFORM PLAN
         * ------------------------------- */
        stage('Terraform Plan') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: 'aws-creds']]) {
                    dir('terraform') {
                        sh """
                        echo "[INFO] Terraform plan"
                        terraform plan -out=tfplan
                        """
                    }
                }
            }
        }

        /* -------------------------------
         *  TERRAFORM APPLY
         * ------------------------------- */
        stage('Terraform Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: 'aws-creds']]) {
                    dir('terraform') {
                        sh """
                        echo "[INFO] Terraform apply"
                        terraform apply -auto-approve tfplan
                        """
                    }
                }
            }
        }

        /* -------------------------------
         *  EXTRACT BASTION PUBLIC IP
         * ------------------------------- */
        stage('Export Bastion IP') {
            steps {
                dir('terraform') {
                    script {
                        env.BASTION_IP = sh(
                            returnStdout: true,
                            script: "terraform output -raw bastion_public_ip"
                        ).trim()
                    }
                }
                echo "[INFO] Bastion IP = ${env.BASTION_IP}"
            }
        }

        /* -------------------------------
         *  GENERATE SSH CONFIG FOR BASTION PROXY
         * ------------------------------- */
        stage('Prepare SSH Config') {
            steps {
                sh """
                cat > ansible/ssh.cfg <<EOF
Host bastion
  HostName ${BASTION_IP}
  User ubuntu
  IdentityFile ~/.ssh/id_rsa
  ForwardAgent yes

Host 10.10.*
  ProxyCommand ssh -W %h:%p ubuntu@${BASTION_IP}
  User ubuntu
  IdentityFile ~/.ssh/id_rsa
  StrictHostKeyChecking=no
EOF

                echo "[INFO] SSH config generated"
                """
            }
        }

        /* -------------------------------
         *  GENERATE DYNAMIC INVENTORY
         * ------------------------------- */
        stage('Generate Dynamic Inventory') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: 'aws-creds']]) {
                    sh """
                    echo "[INFO] Generating dynamic inventory"
                    ansible-inventory -i ansible/inventory.aws_ec2.yml --list
                    """
                }
            }
        }

        /* -------------------------------
         *  RUN ANSIBLE PLAYBOOK
         * ------------------------------- */
        stage('Run Ansible Playbook') {
            steps {
                sshagent(['ubuntu']) {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                      credentialsId: 'aws-creds']]) {

                        sh """
                        echo "[INFO] Running Ansible via Bastion"
                        export ANSIBLE_CONFIG=ansible/ansible.cfg
                        ansible-playbook -i ansible/inventory.aws_ec2.yml ansible/playbook.yml
                        """
                    }
                }
            }
        }
    }

    /* -------------------------------
     *  POST ACTIONS
     * ------------------------------- */
    post {
        success {
            echo "🎉 Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed."
        }
    }
}
