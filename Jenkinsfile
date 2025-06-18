pipeline {
agent any

tools {
jdk   'jdk17'
maven 'maven3'
}

environment {
DOCKER\_CRED = 'dockerhub'         // ID Jenkins credential Docker Hub
SONAR\_TOKEN = credentials('sonar-token')
SONAR\_URL   = '[http://localhost:9000](http://localhost:9000)'
}

stages {
stage('Checkout') {
steps { checkout scm }
}

```
stage('Build & Test') {
  steps {
    echo '🔧 mvn clean package'
    sh 'mvn clean package -B'
  }
}

stage('SonarQube Analysis') {
  steps {
    echo '🔍 SonarQube scan'
    catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
      withSonarQubeEnv('MySonar') {
        sh "mvn sonar:sonar -Dsonar.host.url=${SONAR_URL} -Dsonar.login=${SONAR_TOKEN}"
      }
    }
  }
}

stage('Quality Gate') {
  steps {
    echo '⏳ Attente Quality Gate Sonar'
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

stage('Docker Login, Build, Scan & Push') {
  steps {
    withCredentials([usernamePassword(
      credentialsId: DOCKER_CRED,
      usernameVariable: 'DOCKER_USER',
      passwordVariable: 'DOCKER_PASS'
    )]) {
      script {
        // Docker login
        echo '🐳 Docker login'
        sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'

        // Docker build
        echo '🏗️ Docker build'
        sh "docker build -t $DOCKER_USER/demoapp:${GIT_COMMIT} ."

        // Trivy scan (mark unstable on vulnerabilities)
        echo '🔍 Trivy scan'
        catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
          sh "trivy image --exit-code 1 --severity HIGH,CRITICAL $DOCKER_USER/demoapp:${GIT_COMMIT}"
        }

        // Push image
        echo '📤 Push to Docker Hub'
        sh "docker push $DOCKER_USER/demoapp:${GIT_COMMIT}"
        sh "docker tag $DOCKER_USER/demoapp:${GIT_COMMIT} $DOCKER_USER/demoapp:latest"
        sh "docker push $DOCKER_USER/demoapp:latest"
      }
    }
  }
}
```

}

post {
success  { echo '✅ Pipeline terminé avec succès' }
unstable { echo '⚠️ Pipeline instable (vulnérabilités détectées)' }
failure  { echo '❌ Pipeline échoué' }
}
}
