pipeline {
  agent any

  options {
    timestamps()
  }

  environment {
    REPO = 'https://github.com/udaychaturvedi/prometheus-setup.git'
    TF_DIR = 'terraform'
    ANSIBLE_DIR = 'ansible'
  }

  stages {

    stage('Checkout') {
      steps {
        script {
          checkout([$class: 'GitSCM',
                    branches: [[name: 'refs/heads/main']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [[$class: 'WipeWorkspace']],
                    userRemoteConfigs: [[url: env.REPO, credentialsId: 'git-creds']]
          ])
        }
      }
    }

    stage('Load AWS Credentials') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'aws-creds',
          usernameVariable: 'AWS_ACCESS_KEY_ID',
          passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
          sh '''
            echo "[INFO] AWS creds loaded"
          '''
        }
      }
    }

    stage('Setup SSH Agent') {
      steps {
        sshagent (credentials: ['a69af01d-c489-495b-86e1-a646fea4f6e6']) {
          sh 'echo "[INFO] SSH agent is active"'
        }
      }
    }

    stage('Terraform Init') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'aws-creds',
          usernameVariable: 'AWS_ACCESS_KEY_ID',
          passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {

          dir(env.TF_DIR) {
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
        withCredentials([usernamePassword(
          credentialsId: 'aws-creds',
          usernameVariable: 'AWS_ACCESS_KEY_ID',
          passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {

          dir(env.TF_DIR) {
            sh '''
              echo "[INFO] Terraform plan"
              terraform plan -out=tfplan
            '''
          }

        }
      }
    }

    stage('Terraform Apply') {
      when { expression { fileExists("${env.TF_DIR}/tfplan") } }
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'aws-creds',
          usernameVariable: 'AWS_ACCESS_KEY_ID',
          passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {

          dir(env.TF_DIR) {
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
        sshagent (credentials: ['a69af01d-c489-495b-86e1-a646fea4f6e6']) {
          sh '''
            echo "[INFO] Generating inventory"
            ansible-inventory -i ansible/inventory.aws_ec2.yml --list > inventory.json || true
            cat inventory.json || true
          '''
        }
      }
    }

    stage('Run Ansible Playbook') {
      steps {
        sshagent (credentials: ['a69af01d-c489-495b-86e1-a646fea4f6e6']) {
          sh '''
            echo "[INFO] Running Ansible"
            export ANSIBLE_CONFIG=ansible/ansible.cfg
            ansible-playbook -i ansible/inventory.aws_ec2.yml ansible/playbook.yml -vv || true
          '''
        }
      }
    }

    stage('Health Check') {
      steps {
        sh '''
          echo "[INFO] Health check here"
        '''
      }
    }

  }

  post {
    always {
      archiveArtifacts artifacts: '**/tfplan, **/inventory.json', allowEmptyArchive: true
      echo "Pipeline finished."
    }
    success {
      echo "🎉 Pipeline success"
    }
    failure {
      echo "❌ Pipeline failed"
    }
  }
}
