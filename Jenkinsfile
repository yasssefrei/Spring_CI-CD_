pipeline {
  agent any

  tools {
    jdk   'jdk17'
    maven 'maven3'
  }

  environment {
    DOCKERHUB_CRED = 'dockerhub'
    SONAR_TOKEN    = credentials('sonar-token')
    SONAR_HOST_URL = 'http://localhost:9000'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build Maven') {
      steps {
        sh 'mvn clean package -B'
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('MySonar') {
          sh "mvn sonar:sonar -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.login=${SONAR_TOKEN}"
        }
      }
    }

    stage('Quality Gate') {
      steps {
        echo '⏳ Vérification Quality Gate (pipeline NON stoppé)'
        timeout(time: 2, unit: 'MINUTES') {
          script {
            def qg = waitForQualityGate()
            if (qg.status != 'OK') {
              currentBuild.result = 'UNSTABLE'
              echo "⚠️ Quality Gate status: ${qg.status}"
            } else {
              echo "✅ Quality Gate passed"
            }
          }
        }
      }
    }

    stage('Docker Build') {
      steps {
        script {
          withCredentials([usernamePassword(
            credentialsId: DOCKERHUB_CRED,
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
          )]) {
            sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
            sh "docker build -t $DOCKER_USER/demoapp:${env.GIT_COMMIT} ."
          }
        }
      }
    }

    stage('Push to Docker Hub') {
      steps {
        sh '''
          docker push $DOCKER_USER/demoapp:${GIT_COMMIT}
          docker tag $DOCKER_USER/demoapp:${GIT_COMMIT} $DOCKER_USER/demoapp:latest
          docker push $DOCKER_USER/demoapp:latest
        '''
      }
    }
  }

  post {
    success  { echo '✅ Pipeline terminé avec succès' }
    unstable { echo '⚠️ Pipeline instable (Quality Gate)' }
    failure  { echo '❌ Pipeline échoué' }
  }
}
