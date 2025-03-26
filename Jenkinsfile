pipeline {
    agent { label 'docker-agent' }
    
    stages {
        stage("verify tooling") {
            steps {
                sh '''
                    docker info
                    docker version
                    docker compose version
                    curl --version
                '''
            }
        }
        stage("Start building") {
            steps {
                sh 'docker compose up openproject -d --build --wait'
                sh 'docker compose ps'
                sh 'docker logs openproject_app'
            }
        }
    }
}
