pipeline {
  agent any

  tools {
    jdk    'jdk17'    // configurer en Global Tool Configuration
    maven  'maven3'
  }

  environment {
    DOCKERHUB_CRED = 'dockerhub'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Maven') {
      steps {
        echo '🔧 mvn clean package'
        sh 'mvn clean package -B'
      }
    }

    stage('Docker Build') {
      steps {
        echo '🐳 docker build'
        sh 'docker build -t demoapp:${GIT_COMMIT} .'
      }
    }

    stage('Push to Docker Hub') {
      steps {
        echo '📤 Push image to Docker Hub'
        withCredentials([usernamePassword(
          credentialsId: "${DOCKERHUB_CRED}",
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh '''
            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
            docker tag demoapp:${GIT_COMMIT} $DOCKER_USER/demoapp:${GIT_COMMIT}
            docker tag demoapp:${GIT_COMMIT} $DOCKER_USER/demoapp:latest
            docker push $DOCKER_USER/demoapp:${GIT_COMMIT}
            docker push $DOCKER_USER/demoapp:latest
          '''
        }
      }
    }
  }

  post {
    success { echo '✅ Pipeline terminé avec succès' }
    failure { echo '❌ Pipeline échoué' }
  }
}
