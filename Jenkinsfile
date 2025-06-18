pipeline {
  agent any

  tools {
    jdk   'jdk17'
    maven 'maven3'
  }

  environment {
    DOCKER_CRED = 'dockerhub'
    SONAR_TOKEN = credentials('sonar-token')
    SONAR_URL   = 'http://localhost:9000'
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
        catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
          withSonarQubeEnv('MySonar') {
            sh "mvn sonar:sonar -Dsonar.host.url=${SONAR_URL} -Dsonar.login=${SONAR_TOKEN}"
          }
        }
      }
    }

    stage('Quality Gate') {
      steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
          timeout(time: 2, unit: 'MINUTES') {
            script {
              def qg = waitForQualityGate()
              echo "Quality Gate: ${qg.status}"
              if (qg.status != 'OK') { currentBuild.result = 'UNSTABLE' }
            }
          }
        }
      }
    }

    stage('Docker Login, Build & Push') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: DOCKER_CRED,
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh '''
            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
            docker build -t $DOCKER_USER/demoapp:${GIT_COMMIT} .
            docker push $DOCKER_USER/demoapp:${GIT_COMMIT}
            docker tag $DOCKER_USER/demoapp:${GIT_COMMIT} $DOCKER_USER/demoapp:latest
            docker push $DOCKER_USER/demoapp:latest
          '''
        }
      }
    }

    stage('Deploy to Nexus') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'nexus-credentials',
          usernameVariable: 'NEXUS_USERNAME',
          passwordVariable: 'NEXUS_PASSWORD'
        )]) {
          sh '''
            mvn deploy -B \
              -s settings-nexus.xml \
              -DaltDeploymentRepository=nexus::default::http://34.227.110.97:8081/repository/maven-snapshots/
          '''
        }
      }
    }
  }

  post {
    success  { echo '✅ Pipeline terminé avec succès' }
    unstable { echo '⚠️ Pipeline instable (vérifier les logs)' }
    failure  { echo '❌ Pipeline échoué' }
  }
}
