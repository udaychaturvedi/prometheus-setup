pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = "true"
        ANSIBLE_CONFIG = "ansible/ansible.cfg"
    }

    stages {

        stage('Checkout') {
            steps {
                git url: 'https://github.com/udaychaturvedi/prometheus-setup.git', credentialsId: 'git-creds'
            }
        }

        stage('Terraform + AWS Setup') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        echo "[INFO] AWS credentials loaded into environment"
                        export AWS_DEFAULT_REGION=ap-south-1
                    '''
                }
            }
        }

        stage('Setup SSH Agent') {
            steps {
                sshagent(credentials: ['a69af01d-c489-495b-86e1-a646fea4f6e6']) {
                    sh 'echo "[INFO] SSH agent loaded successfully"'
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        export AWS_DEFAULT_REGION=ap-south-1
                        cd terraform
                        echo "[INFO] Running terraform init with AWS creds"
                        terraform init -input=false
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        export AWS_DEFAULT_REGION=ap-south-1
                        cd terraform
                        terraform plan -out=tfplan
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        export AWS_DEFAULT_REGION=ap-south-1
                        cd terraform
                        terraform apply -input=false -auto-approve tfplan
                    '''
                }
            }
        }

        stage('Generate Dynamic Inventory') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        export AWS_DEFAULT_REGION=ap-south-1
                        echo "[INFO] Generating AWS dynamic inventory"
                        ansible-inventory -i ansible/inventory.aws_ec2.yml --list
                    '''
                }
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                sshagent(credentials: ['a69af01d-c489-495b-86e1-a646fea4f6e6']) {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-creds',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        sh '''
                            export AWS_DEFAULT_REGION=ap-south-1
                            echo "[INFO] Running Ansible Playbook"
                            ansible-playbook -i ansible/inventory.aws_ec2.yml ansible/playbook.yml
                        '''
                    }
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    sh '''
                        cd terraform
                        BASTION_IP=$(terraform output -raw bastion_public_ip)
                        echo "[INFO] Checking Prometheus via Bastion: $BASTION_IP"
                        curl -I http://$BASTION_IP || true
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "🎉 Deployment Pipeline SUCCESSFUL!"
        }
        failure {
            echo "❌ Pipeline failed. Check logs."
        }
    }
}
