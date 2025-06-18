pipeline {
  agent any

  tools {
    jdk    'jdk17'
    maven  'maven3'
  }

  environment {
    DOCKERHUB_CRED = 'dockerhub'
    NEXUS_CRED     = 'nexus-creds'
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

    stage('Docker Build & Login') {
      steps {
        echo '🐳 docker build & login'
        script {
          def user = ''
          withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CRED}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
            user = env.DOCKER_USER
            sh '''
              echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
            '''
          }
          sh "docker build -t ${user}/demoapp:${env.GIT_COMMIT} ."
        }
      }
    }

    stage('Trivy Scan') {
      steps {
        echo '🔍 Trivy Scan'
        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
          sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${env.DOCKER_USER}/demoapp:${env.GIT_COMMIT}"
        }
      }
    }

    stage('Push to Docker Hub') {
      steps {
        echo '📤 Push image to Docker Hub'
        withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CRED}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
            docker push $DOCKER_USER/demoapp:${GIT_COMMIT}
            docker tag $DOCKER_USER/demoapp:${GIT_COMMIT} $DOCKER_USER/demoapp:latest
            docker push $DOCKER_USER/demoapp:latest
          '''
        }
      }
    }

    stage('Deploy JAR to Nexus') {
      steps {
        echo '📦 Déploiement JAR vers Nexus'
        withCredentials([usernamePassword(credentialsId: "${NEXUS_CRED}", usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
          sh '''
            cat > settings.xml <<EOF
<settings>
  <servers>
    <server>
      <id>nexus-releases</id>
      <username>${NEXUS_USER}</username>
      <password>${NEXUS_PASS}</password>
    </server>
  </servers>
</settings>
EOF
            mvn deploy -s settings.xml -DskipTests
          '''
        }
      }
    }
  }

  post {
    success { echo '✅ Pipeline terminé avec succès' }
    failure { echo '❌ Pipeline échoué' }
    unstable { echo '⚠️ Pipeline terminé avec des problèmes (Trivy ?)' }
  }
}
