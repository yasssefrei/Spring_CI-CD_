pipeline {
  agent any

  environment {
    DOCKERHUB_CRED = 'dockerhub'
  }

  tools {
    maven 'maven3'    // à configurer en Global Tool Configuration
    jdk    'jdk17'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Maven') {
      steps {
        echo '🧱 mvn clean package'
        sh 'mvn clean package -B'
      }
    }

    stage('SonarQube Analysis') {
      steps {
        echo '🧐 Analyse SonarQube'
        withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
          sh """
            mvn sonar:sonar \
              -Dsonar.projectKey=demoapp \
              -Dsonar.host.url=http://localhost:9000 \
              -Dsonar.login=$SONAR_TOKEN
          """
        }
      }
    }

    stage('Docker Build') {
      steps {
        echo '🐳 Construction de l’image'
        sh 'docker build -t demoapp:${GIT_COMMIT} .'
      }
    }

    stage('Trivy Scan') {
      steps {
        echo '🔍 Scan de sécurité Trivy'
        sh 'trivy image --exit-code 1 --severity HIGH,CRITICAL demoapp:${GIT_COMMIT}'
      }
    }

    stage('Push to DockerHub') {
      steps {
        echo '📤 Push image Docker Hub'
        withCredentials([usernamePassword(
          credentialsId: "${env.DOCKERHUB_CRED}",
          usernameVariable: 'USER',
          passwordVariable: 'PASS'
        )]) {
          sh '''
            echo $PASS | docker login -u $USER --password-stdin
            docker tag demoapp:${GIT_COMMIT} $USER/demoapp:${GIT_COMMIT}
            docker tag demoapp:${GIT_COMMIT} $USER/demoapp:latest
            docker push $USER/demoapp:${GIT_COMMIT}
            docker push $USER/demoapp:latest
          '''
        }
      }
    }
  }

  post {
    success { echo '✅ Pipeline terminé avec succès' }
    failure { echo '❌ Pipeline en échec' }
  }
}
