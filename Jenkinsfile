pipeline {
  agent any

  environment {
    DOCKERHUB_CRED = 'dockerhub'
  }

  stages {
    stage('Préparation') {
      steps {
        echo '🔧 Installation de Trivy si absent, puis Docker login'
        sh '''
          if ! command -v trivy &> /dev/null; then
            wget https://github.com/aquasecurity/trivy/releases/download/v0.44.1/trivy_0.44.1_Linux-64bit.deb
            sudo dpkg -i trivy_0.44.1_Linux-64bit.deb
          fi
        '''
        withCredentials([usernamePassword(
          credentialsId: "${env.DOCKERHUB_CRED}",
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
        }
      }
    }

    stage('Build Maven') {
      steps {
        echo '🧱 mvn clean package'
        sh 'mvn clean package -B'
      }
    }

    stage('Docker Build & Scan') {
      steps {
        echo '🐳 docker build + trivy scan'
        sh '''
          docker build -t demoapp:${GIT_COMMIT} .
          trivy image --exit-code 1 --severity HIGH,CRITICAL demoapp:${GIT_COMMIT}
        '''
      }
    }

    stage('Push to DockerHub') {
      steps {
        echo '📤 push image DockerHub'
        sh '''
          docker tag demoapp:${GIT_COMMIT} $DOCKER_USER/demoapp:${GIT_COMMIT}
          docker tag demoapp:${GIT_COMMIT} $DOCKER_USER/demoapp:latest
          docker push $DOCKER_USER/demoapp:${GIT_COMMIT}
          docker push $DOCKER_USER/demoapp:latest
        '''
      }
    }
  }

  post {
    success {
      echo '✅ Pipeline terminé avec succès'
    }
    failure {
      echo '❌ Pipeline en échec'
    }
  }
}
