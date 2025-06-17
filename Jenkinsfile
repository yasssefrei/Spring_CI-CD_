pipeline {
  agent any

  tools {
    jdk   'jdk17'
    maven 'maven3'
  }

  environment {
    DOCKER_CRED  = 'dockerhub'
    SONAR_TOKEN  = credentials('sonar-token')
    SONAR_URL    = 'http://localhost:9000'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build & Test') {
      steps {
        sh 'mvn clean package -B'
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('MySonar') {
          sh """
            mvn sonar:sonar \
              -Dsonar.projectKey=Spring_CI-CD \
              -Dsonar.host.url=${SONAR_URL} \
              -Dsonar.login=${SONAR_TOKEN}
          """
        }
      }
    }

    stage('Quality Gate') {
      steps {
        timeout(time: 2, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('Docker Build') {
      steps {
        script {
          withCredentials([usernamePassword(
            credentialsId: DOCKER_CRED,
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
          )]) {
            sh 'docker login -u $DOCKER_USER --password-stdin <<< $DOCKER_PASS'
            sh "docker build -t $DOCKER_USER/demoapp:${env.GIT_COMMIT} ."
          }
        }
      }
    }

    stage('Push to DockerHub') {
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
    success { echo '✅ Pipeline OK' }
    failure { echo '❌ Pipeline KO' }
  }
}
