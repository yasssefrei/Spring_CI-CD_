pipeline {
  agent any

  tools {
    jdk    'jdk17'
    maven  'maven3'
  }

  environment {
    DOCKERHUB_CRED = 'dockerhub'    // ID de tes credentials Jenkins
    SONAR_TOKEN    = credentials('sonar-token') // token SonarQube stocké dans Jenkins
    SONAR_HOST_URL = 'http://localhost:9000'    // URL de ton SonarQube
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

    stage('SonarQube Analysis') {
      steps {
        echo '🔍 Lancement de l’analyse SonarQube'
        sh """
          mvn sonar:sonar \
            -Dsonar.host.url=${SONAR_HOST_URL} \
            -Dsonar.login=${SONAR_TOKEN}
        """
      }
    }

    stage('Docker Build') {
      steps {
        echo '🐳 docker build'
        script {
          def user = ''
          withCredentials([usernamePassword(
            credentialsId: "${DOCKERHUB_CRED}",
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
          )]) {
            user = env.DOCKER_USER
          }
          sh "docker build -t ${user}/demoapp:${env.GIT_COMMIT} ."
        }
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
