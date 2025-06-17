pipeline {
  agent any

  tools {
    jdk    'jdk17'
    maven  'maven3'
  }

  environment {
    DOCKERHUB_CRED = 'dockerhub'
    SONAR_TOKEN    = credentials('sonar-token')
    SONAR_SERVER   = 'MySonar'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build & Test Maven') {
      steps {
        echo '🧱 mvn clean package'
        sh 'mvn clean package -B'
      }
    }

    stage('SonarQube Analysis') {
      steps {
        echo '🔍 SonarQube scan'
        withSonarQubeEnv("${SONAR_SERVER}") {
          sh """
            mvn sonar:sonar \
              -Dsonar.projectKey=Spring_CI_CD \
              -Dsonar.host.url=$SONAR_HOST_URL \
              -Dsonar.login=$SONAR_TOKEN
          """
        }
      }
    }

    stage('Quality Gate') {
      steps {
        echo '⏳ Waiting for SonarQube Quality Gate'
        timeout(time: 2, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('Docker Build & Push') {
      steps {
        script {
          def user = ''
          withCredentials([usernamePassword(
            credentialsId: "${DOCKERHUB_CRED}",
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
          )]) {
            user = env.DOCKER_USER
            sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
          }
          sh "docker build -t ${user}/demoapp:${env.GIT_COMMIT} ."
          sh """
            docker push ${user}/demoapp:${env.GIT_COMMIT}
            docker tag ${user}/demoapp:${env.GIT_COMMIT} ${user}/demoapp:latest
            docker push ${user}/demoapp:latest
          """
        }
      }
    }
  }

  post {
    success { echo '✅ Pipeline terminé avec succès' }
    failure { echo '❌ Pipeline échoué' }
  }
}
