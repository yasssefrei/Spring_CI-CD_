pipeline {
  agent any

  tools {
    jdk    'jdk17'
    maven  'maven3'
  }

  environment {
    DOCKERHUB_CRED = 'dockerhub'    // ID de tes credentials Jenkins
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
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
        script {
          // Récupère user de DockerHub pour tag
          def user = ''
          withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CRED}",
                                            usernameVariable: 'DOCKER_USER',
                                            passwordVariable: 'DOCKER_PASS')]) {
            user = env.DOCKER_USER
          }
          // Build l’image
          sh "docker build -t ${user}/demoapp:${env.GIT_COMMIT} ."
        }
      }
    }

    stage('Push to Docker Hub') {
      steps {
        echo '📤 Push image to Docker Hub'
        withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CRED}",
                                          usernameVariable: 'DOCKER_USER',
                                          passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
            docker push $DOCKER_USER/demoapp:${GIT_COMMIT}
            docker push $DOCKER_USER/demoapp:latest || true
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
