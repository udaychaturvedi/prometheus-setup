pipeline {
    agent any

    environment {
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

        stage('Terraform + AWS Setup') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-creds']
                ]) {

                    echo "AWS credentials loaded into environment"

                    withEnv([
                        "AWS_ACCESS_KEY_ID=${env.AWS_ACCESS_KEY_ID}",
                        "AWS_SECRET_ACCESS_KEY=${env.AWS_SECRET_ACCESS_KEY}"
                    ]) {
                        echo "[INFO] Exported AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
                    }
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
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-creds']
                ]) {
                    withEnv([
                        "AWS_ACCESS_KEY_ID=${env.AWS_ACCESS_KEY_ID}",
                        "AWS_SECRET_ACCESS_KEY=${env.AWS_SECRET_ACCESS_KEY}"
                    ]) {
                        dir('terraform') {
                            sh '''
                                echo "[INFO] Running terraform init with AWS creds"
                                terraform init -input=false
                            '''
                        }
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-creds']
                ]) {
                    withEnv([
                        "AWS_ACCESS_KEY_ID=${env.AWS_ACCESS_KEY_ID}",
                        "AWS_SECRET_ACCESS_KEY=${env.AWS_SECRET_ACCESS_KEY}"
                    ]) {
                        dir('terraform') {
                            sh '''
                                terraform plan -out=tfplan
                            '''
                        }
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-creds']
                ]) {
                    withEnv([
                        "AWS_ACCESS_KEY_ID=${env.AWS_ACCESS_KEY_ID}",
                        "AWS_SECRET_ACCESS_KEY=${env.AWS_SECRET_ACCESS_KEY}"
                    ]) {
                        dir('terraform') {
                            sh '''
                                terraform apply -input=false -auto-approve tfplan
                            '''
                        }
                    }
                }
            }
        }

        stage('Generate Dynamic Inventory') {
            steps {
                sh '''
                    echo "[INFO] Generating AWS dynamic inventory"
                    ansible-inventory -i ansible/inventory.aws_ec2.yml --list > inventory_output.json
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'inventory_output.json', allowEmptyArchive: true
                }
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                sshagent(credentials: ['a69af01d-c489-495b-86e1-a646fea4f6e6']) {
                    sh '''
                        echo "[INFO] Running Ansible Playbook"
                        export ANSIBLE_CONFIG=ansible/ansible.cfg
                        ansible-playbook -i ansible/inventory.aws_ec2.yml ansible/playbook.yml
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    echo "[INFO] Checking Prometheus health"
                    curl -I http://<PUBLIC_NGINX_IP>/prometheus/-/healthy || true
                '''
            }
        }
    }

    post {
        success {
            echo "🎉 Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed. Check logs."
        }
    }
}
