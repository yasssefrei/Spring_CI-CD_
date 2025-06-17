pipeline {
  agent any

  tools {
    jdk   'jdk17'
    maven 'maven3'
  }

  environment {
    DOCKER_CRED = 'dockerhub'
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
          withCredentials([usernamePassword(
            credentialsId: DOCKER_CRED,
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
          )]) {
            sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
            sh "docker build -t $DOCKER_USER/demoapp:${GIT_COMMIT} ."
          }
        }
      }
    }

    stage('Trivy Scan') {
      steps {
        echo '🔍 Scanning image with Trivy'
        // captureError pour ne pas breaker le pipeline si vulnérabilités trouvées
        catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
          script {
            // Utilise l’image que tu viens de builder
            def img = "${env.DOCKER_USER}/demoapp:${env.GIT_COMMIT}"
            // Scan ; exit code 1 si vulnérabilités HIGH/CRITICAL
            sh "trivy image --exit-code 1 --severity HIGH,CRITICAL $img"
          }
        }
      }
    }

    stage('Push to Docker Hub') {
      steps {
        echo '📤 Push image to Docker Hub'
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
    unstable { echo '⚠️ Pipeline instable (vulnérabilités détectées par Trivy)' }
    failure  { echo '❌ Pipeline KO' }
  }
}
