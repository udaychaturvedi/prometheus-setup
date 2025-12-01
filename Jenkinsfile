pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = "true"
        ANSIBLE_CONFIG = "ansible/ansible.cfg"
    }

    stages {

        /* ------------------------------------------------------
         * 1. CHECKOUT SOURCE CODE
         * ------------------------------------------------------ */
        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'git-creds',
                    url: 'https://github.com/udaychaturvedi/prometheus-setup.git'
            }
        }

        /* ------------------------------------------------------
         * 2. LOAD AWS CREDS (Required for TF + Ansible inventory)
         * ------------------------------------------------------ */
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

        /* ------------------------------------------------------
         * 3. SSH PRIVATE KEY (ubuntu)
         * ------------------------------------------------------ */
        stage('Setup SSH Agent') {
            steps {
                sshagent (credentials: ['ubuntu']) {
                    sh 'echo "[INFO] SSH agent loaded"'
                }
            }
        }

        /* ------------------------------------------------------
         * 4. TERRAFORM INIT
         * ------------------------------------------------------ */
        stage('Terraform Init') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    dir('terraform') {
                        sh '''
                          echo "[INFO] Running terraform init"
                          terraform init -input=false
                        '''
                    }
                }
            }
        }

        /* ------------------------------------------------------
         * 5. TERRAFORM PLAN
         * ------------------------------------------------------ */
        stage('Terraform Plan') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    dir('terraform') {
                        sh '''
                          echo "[INFO] Running terraform plan"
                          terraform plan -out=tfplan
                        '''
                    }
                }
            }
        }

        /* ------------------------------------------------------
         * 6. TERRAFORM APPLY
         * ------------------------------------------------------ */
        stage('Terraform Apply') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    dir('terraform') {
                        sh '''
                          echo "[INFO] Running terraform apply"
                          terraform apply -input=false -auto-approve tfplan
                        '''
                    }
                }
            }
        }

        /* ------------------------------------------------------
         * 7. GENERATE ANSIBLE DYNAMIC INVENTORY
         * ------------------------------------------------------ */
        stage('Generate Dynamic Inventory') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    sh '''
                      echo "[INFO] Generating Dynamic Inventory"
                      ansible-inventory -i ansible/inventory.aws_ec2.yml --list > inventory_output.json
                    '''
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'inventory_output.json', allowEmptyArchive: true
                }
            }
        }

        /* ------------------------------------------------------
         * 8. RUN ANSIBLE PLAYBOOK
         * ------------------------------------------------------ */
        stage('Run Ansible Playbook') {
            steps {
                sshagent (credentials: ['ubuntu']) {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-creds'
                    ]]) {
                        sh '''
                          echo "[INFO] Running Ansible Playbook"
                          ansible-playbook -i ansible/inventory.aws_ec2.yml ansible/playbook.yml
                        '''
                    }
                }
            }
        }

        /* ------------------------------------------------------
         * 9. VALIDATION
         * ------------------------------------------------------ */
        stage('Health Check') {
            steps {
                sh '''
                  echo "[INFO] Checking Prometheus health"
                  echo "Skipping remote HTTP check (handled by NGINX public IP in terraform output)"
                '''
            }
        }
    }

    /* ------------------------------------------------------
     * POST ACTIONS
     * ------------------------------------------------------ */
    post {
        success {
            echo "🎉 Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed. Check logs."
        }
    }
}
