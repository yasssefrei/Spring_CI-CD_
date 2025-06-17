pipeline {
  agent any

  tools {
    jdk   'jdk17'
    maven 'maven3'
  }

  environment {
    DOCKER_CRED = 'dockerhub'  // Jenkins credentials ID
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Maven') {
      steps {
        sh 'mvn clean package -B'
      }
    }

    stage('Docker Build') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: "${DOCKER_CRED}",
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          script {
            env.DOCKER_USER = DOCKER_USER  // rendre DOCKER_USER global
            sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
            sh "docker build -t $DOCKER_USER/demoapp:${GIT_COMMIT} ."
          }
        }
      }
    }

    stage('Trivy Scan') {
      steps {
        echo '🔍 Scanning image with Trivy'
        catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
          sh "trivy image --exit-code 1 --severity HIGH,CRITICAL $DOCKER_USER/demoapp:${GIT_COMMIT}"
        }
      }
    }

    stage('Push to Docker Hub') {
      steps {
        sh """
          docker push $DOCKER_USER/demoapp:${GIT_COMMIT}
          docker tag $DOCKER_USER/demoapp:${GIT_COMMIT} $DOCKER_USER/demoapp:latest
          docker push $DOCKER_USER/demoapp:latest
        """
      }
    }
  }

  post {
    success  { echo '✅ Pipeline terminé avec succès' }
    unstable { echo '⚠️ Pipeline instable (Trivy a détecté des vulnérabilités)' }
    failure  { echo '❌ Pipeline échoué' }
  }
}
