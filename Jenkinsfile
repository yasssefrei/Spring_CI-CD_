pipeline {
  agent any

  environment {
    DOCKERHUB_CRED = 'dockerhub' // ID des credentials DockerHub dans Jenkins
  }

  tools {
    maven 'Maven-3.8.8'   // Doit correspondre au nom dans Jenkins
    jdk    'OpenJDK-17'   // Idem pour Java
  }

  stages {
    stage('Préparation') {
      steps {
        echo '🔧 Installation de Trivy et Docker login'

        // Installation de Trivy (scan sécurité)
        sh '''
          if ! command -v trivy &> /dev/null; then
            wget https://github.com/aquasecurity/trivy/releases/download/v0.44.1/trivy_0.44.1_Linux-64bit.deb
            sudo dpkg -i trivy_0.44.1_Linux-64bit.deb
          fi
        '''

        // Authentification à DockerHub
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
        sh 'mvn clean package -B'
      }
    }

    stage('Docker build + Trivy') {
      steps {
        sh '''
          docker build -t demoapp:${GIT_COMMIT} .
          trivy image --exit-code 1 --severity HIGH,CRITICAL demoapp:${GIT_COMMIT}
        '''
      }
    }

    stage('Push DockerHub') {
      steps {
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
      echo '✅ Pipeline réussi'
    }
    failure {
      echo '❌ Échec du pipeline'
    }
  }
}
