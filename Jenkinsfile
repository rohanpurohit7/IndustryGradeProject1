pipeline {
  agent any

  environment {
    AWS_REGION = '<region>'
    AWS_ACCOUNT_ID = credentials('aws-account-id')
    ECR_REPOSITORY = 'retail-portal'
    IMAGE_TAG = "${BUILD_NUMBER}"
    IMAGE_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}"
    VERACODE_APP = 'retail-portal'
    NEXUS_URL = '<nexus-iq-url>'
    AQUA_CONSOLE = '<aqua-console>'
    KUBE_NAMESPACE = 'retail'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build and Unit Test') {
      steps {
        sh 'mvn clean verify'
        archiveArtifacts artifacts: '**/target/*.war', fingerprint: true
        junit '**/target/surefire-reports/*.xml'
      }
    }

    stage('Contrast IAST') {
      steps {
        echo 'Run integration tests with the approved Contrast Java agent attached.'
        sh 'mvn verify -Pcontrast'
      }
    }

    stage('Veracode SAST') {
      steps {
        sh '''
          veracode package --source . --output target/veracode-upload.zip
          veracode static scan target/veracode-upload.zip --app ${VERACODE_APP}
        '''
      }
    }

    stage('Nexus IQ Policy Evaluation') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'nexus-iq', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
          sh '''
            nexus-iq-cli -i ${VERACODE_APP} -s ${NEXUS_URL} \
              -a ${NEXUS_USER}:${NEXUS_PASS} target/*.war
          '''
        }
      }
    }

    stage('Build Container') {
      steps {
        sh 'docker build --pull -t ${IMAGE_URI} .'
      }
    }

    stage('Aqua Container Scan') {
      steps {
        sh '''
          scannercli scan --host ${AQUA_CONSOLE} --local ${IMAGE_URI} \
            --show-negligible --htmlfile aqua-report.html
        '''
        archiveArtifacts artifacts: 'aqua-report.html', fingerprint: true
      }
    }

    stage('Push to Amazon ECR') {
      steps {
        sh '''
          aws ecr describe-repositories --repository-names ${ECR_REPOSITORY} --region ${AWS_REGION} || \
            aws ecr create-repository --repository-name ${ECR_REPOSITORY} --region ${AWS_REGION}
          aws ecr get-login-password --region ${AWS_REGION} | \
            docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
          docker push ${IMAGE_URI}
        '''
      }
    }

    stage('Ansible Configuration') {
      steps {
        sh 'ansible-playbook -i ansible/inventory.ini ansible/deploy.yml --extra-vars "image_uri=${IMAGE_URI}"'
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        sh '''
          kubectl create namespace ${KUBE_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
          sed "s|IMAGE_URI_PLACEHOLDER|${IMAGE_URI}|g" k8s/deployment.yaml | kubectl apply -n ${KUBE_NAMESPACE} -f -
          kubectl apply -n ${KUBE_NAMESPACE} -f k8s/service.yaml
          kubectl apply -n ${KUBE_NAMESPACE} -f k8s/servicemonitor.yaml
          kubectl apply -n ${KUBE_NAMESPACE} -f monitoring/prometheus-rules.yaml
          kubectl rollout status deployment/retail-portal -n ${KUBE_NAMESPACE} --timeout=180s
        '''
      }
    }

    stage('Burp Suite DAST') {
      steps {
        sh '''
          burp-rest-api --headless --config-file burp/burp-config.json > burp-api.log 2>&1 &
          sleep 20
          curl -sS -X POST http://127.0.0.1:8090/v0.1/scan \
            -H 'Content-Type: application/json' \
            -d @burp/scan-request.json
        '''
      }
    }

    stage('Verify Metrics and Logs') {
      steps {
        sh '''
          kubectl get pods -n ${KUBE_NAMESPACE}
          kubectl get service -n ${KUBE_NAMESPACE}
          kubectl logs deployment/retail-portal -n ${KUBE_NAMESPACE} --tail=100
          kubectl get servicemonitor,prometheusrule -n ${KUBE_NAMESPACE}
        '''
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'target/**/*,aqua-report.html,burp-api.log', allowEmptyArchive: true
    }
    failure {
      sh 'kubectl rollout undo deployment/retail-portal -n ${KUBE_NAMESPACE} || true'
    }
  }
}
