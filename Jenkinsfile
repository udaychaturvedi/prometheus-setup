pipeline {
  agent any
  options {
    ansiColor('xterm')
    timestamps()
  }

  // Do NOT try to use credentials(...) inside environment map.
  // We'll inject them with `withCredentials` where needed.
  environment {
    REPO = 'https://github.com/udaychaturvedi/prometheus-setup.git'
    TF_DIR = 'terraform'
    ANSIBLE_DIR = 'ansible'
  }

  stages {
    stage('Checkout') {
      steps {
        script {
          // explicit checkout of main — avoids job branch mismatch
          checkout([$class: 'GitSCM',
                    branches: [[name: 'refs/heads/main']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [[$class: 'WipeWorkspace']], // optional: start clean
                    userRemoteConfigs: [[url: env.REPO, credentialsId: 'git-creds']]])
        }
      }
    }

    stage('Load AWS Credentials') {
      steps {
        // aws-creds assumed to be username/password (username=KEY, password=SECRET).
        // If you use AWS plugin, adapt accordingly.
        withCredentials([usernamePassword(credentialsId: 'aws-creds',
                                         usernameVariable: 'AWS_ACCESS_KEY_ID',
                                         passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh '''
            echo "[INFO] AWS creds loaded into environment"
            env | grep -E 'AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY' || true
          '''
        }
      }
    }

    stage('Setup SSH Agent') {
      steps {
        // Use your SSH credential id (replace if different)
        sshagent (credentials: ['a69af01d-c489-495b-86e1-a646fea4f6e6']) {
          sh 'echo "[INFO] SSH agent available to steps"'
        }
      }
    }

    stage('Terraform Init') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-creds',
                                         usernameVariable: 'AWS_ACCESS_KEY_ID',
                                         passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          dir(env.TF_DIR) {
            sh '''
              echo "[INFO] Running terraform init (non-interactive)"
              terraform init -input=false
            '''
          }
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-creds',
                                         usernameVariable: 'AWS_ACCESS_KEY_ID',
                                         passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          dir(env.TF_DIR) {
            sh '''
              echo "[INFO] Running terraform plan"
              terraform plan -out=tfplan
            '''
          }
        }
      }
    }

    stage('Terraform Apply') {
      when { expression { fileExists("${env.TF_DIR}/tfplan") } }
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-creds',
                                         usernameVariable: 'AWS_ACCESS_KEY_ID',
                                         passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          dir(env.TF_DIR) {
            sh '''
              echo "[INFO] Applying terraform plan"
              terraform apply -input=false -auto-approve tfplan || (echo "[ERROR] terraform apply failed" && exit 1)
            '''
          }
        }
      }
    }

    stage('Generate Dynamic Inventory') {
      steps {
        sshagent (credentials: ['a69af01d-c489-495b-86e1-a646fea4f6e6']) {
          dir('.') {
            sh '''
              echo "[INFO] Generating ansible inventory"
              ANSIBLE_CONFIG=${ANSIBLE_CONFIG:-ansible/ansible.cfg}
              ansible-inventory -i ansible/inventory.aws_ec2.yml --list > inventory.json || true
              echo "[INFO] inventory.json contents:"
              cat inventory.json || true
            '''
          }
        }
      }
    }

    stage('Run Ansible Playbook') {
      steps {
        sshagent (credentials: ['a69af01d-c489-495b-86e1-a646fea4f6e6']) {
          dir('.') {
            sh '''
              echo "[INFO] Running ansible-playbook"
              export ANSIBLE_CONFIG=ansible/ansible.cfg
              ansible-playbook -i ansible/inventory.aws_ec2.yml ansible/playbook.yml -vv || (echo "[ERROR] Ansible failed" && exit 1)
            '''
          }
        }
      }
    }

    stage('Health Check') {
      steps {
        sh '''
          echo "[INFO] Health check (example)"
          # adapt to your actual health-check commands, e.g. curl the NGINX public IP from terraform output
          echo "[INFO] (no-op health check)"
        '''
      }
    }
  } // stages

  post {
    always {
      archiveArtifacts artifacts: '**/tfplan,**/inventory.json', allowEmptyArchive: true
      echo "Pipeline finished — check logs."
    }
    success { echo "🎉 Pipeline succeeded." }
    failure { echo "❌ Pipeline failed." }
  }
}
