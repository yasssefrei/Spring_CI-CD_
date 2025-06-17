pipeline {
  agent any

  tools { jdk 'jdk17'; maven 'maven3' }

  environment {
    DOCKER_CRED    = 'dockerhub'
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
        catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
          withSonarQubeEnv('MySonar') {
            sh """
              mvn sonar:sonar \
                -Dsonar.projectKey=Spring_CI-CD \
                -Dsonar.host.url=${SONAR_HOST_URL} \
                -Dsonar.login=${SONAR_TOKEN}
            """
          }
        }
      }
    }

    stage('Quality Gate') {
      steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
          timeout(time: 2, unit: 'MINUTES') {
            def qg = waitForQualityGate()
            if (qg.status != 'OK') {
              currentBuild.result = 'UNSTABLE'
              echo "⚠️ Quality Gate: ${qg.status}"
            }
          }
        }
      }
    }

    stage('Docker Build') {
      steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
          script {
            withCredentials([usernamePassword(
              credentialsId: DOCKER_CRED,
              usernameVariable: 'DOCKER_USER',
              passwordVariable: 'DOCKER_PASS'
            )]) {
              sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
              sh "docker build -t $DOCKER_USER/demoapp:${env.GIT_COMMIT} ."
            }
          }
        }
      }
    }

    stage('Push to Docker Hub') {
      steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
          sh '''
            docker push $DOCKER_USER/demoapp:${GIT_COMMIT}
            docker tag  $DOCKER_USER/demoapp:${GIT_COMMIT} $DOCKER_USER/demoapp:latest
            docker push $DOCKER_USER/demoapp:latest
          '''
        }
      }
    }
  }

  post {
    success  { echo '✅ Pipeline OK (all stages passed)' }
    unstable { echo '⚠️ Pipeline instable (vérifier les logs)' }
    failure  { echo '❌ Pipeline échoué' }
  }
}
