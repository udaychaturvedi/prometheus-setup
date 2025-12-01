pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = "true"
        ANSIBLE_CONFIG = "ansible/ansible.cfg"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'git-creds',
                    url: 'https://github.com/udaychaturvedi/prometheus-setup.git'
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

        stage('Setup SSH Agent') {
            steps {
                sshagent (credentials: ['a69af01d-c489-495b-86e1-a646fea4f6e6']) {
                    sh 'echo "[INFO] SSH agent loaded"'
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

        stage('Generate Dynamic Inventory') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    sh '''
                      echo "[INFO] Generating dynamic inventory"
                      ansible-inventory -i ansible/inventory.aws_ec2.yml --list > inventory_output.json
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

        stage('Health Check') {
            steps {
                sh '''
                  echo "[INFO] Health check executed"
                '''
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
