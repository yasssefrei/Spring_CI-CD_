pipeline {
  agent any

  environment {
    DOCKERHUB_CRED = 'dockerhub'
  }

  stages {
    stage('Preparation') {
      steps {
        // … (comme avant)
      }
    }

    stage('Build Maven') {
      steps {
        // Utilise mvn depuis le PATH
        sh 'mvn clean package -B'
      }
    }

    // … reste inchangé …
  }

  post {
    success { echo '✅ Build terminé' }
    failure { echo '❌ Build échoué' }
  }
}
