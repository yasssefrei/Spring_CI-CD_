pipeline {
agent any

tools {
jdk   'jdk17'
maven 'maven3'
}

environment {
DOCKER\_CRED = 'dockerhub'  // Jenkins credentials ID for DockerHub
SONAR\_CRED  = 'sonar-token' // Jenkins credentials ID for SonarQube token
SONAR\_URL   = '[http://localhost:9000](http://localhost:9000)'
}

stages {
stage('Checkout') {
steps {
checkout scm
}
}

```
stage('Build & Test Maven') {
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
        sh "mvn sonar:sonar -Dsonar.host.url=${SONAR_URL} -Dsonar.login=${SONAR_CRED}"
      }
    }
  }
}

stage('Quality Gate') {
  steps {
    echo '⏳ Waiting for SonarQube Quality Gate'
    timeout(time: 2, unit: 'MINUTES') {
      script {
        def qg = waitForQualityGate()
        echo "Quality Gate status: ${qg.status}"
        if (qg.status != 'OK') {
          currentBuild.result = 'UNSTABLE'
        }
      }
    }
  }
}

stage('Docker Build') {
  steps {
    echo '🐳 docker build'
    withCredentials([usernamePassword(
      credentialsId: "${DOCKER_CRED}",
      usernameVariable: 'DOCKER_USER',
      passwordVariable: 'DOCKER_PASS'
    )]) {
      script {
        env.DOCKER_USER = DOCKER_USER  // rendre DOCKER_USER global
        sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
        sh "docker build -t $DOCKER_USER/demoapp:${GIT_COMMIT} ."
      }
    }
  }
}

stage('Trivy Scan') {
  steps {
    echo '🔍 Scanning image with Trivy'
    catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
      sh "trivy image --exit-code 1 --severity HIGH,CRITICAL $DOCKER_USER/demoapp:${GIT_COMMIT}"
    }
  }
}

stage('Push to Docker Hub') {
  steps {
    echo '📤 Push image to Docker Hub'
    sh '''
      docker push $DOCKER_USER/demoapp:${GIT_COMMIT}
      docker tag  $DOCKER_USER/demoapp:${GIT_COMMIT} $DOCKER_USER/demoapp:latest
      docker push $DOCKER_USER/demoapp:latest
    '''
  }
}
```

}

post {
success  { echo '✅ Pipeline terminé avec succès' }
unstable { echo '⚠️ Pipeline instable (check SonarQube/Trivy)' }
failure  { echo '❌ Pipeline échoué' }
}
}
