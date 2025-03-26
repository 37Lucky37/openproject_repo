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
        stage("verify tooling") {
            steps {
                sh 'docker compose up -d --build --wait'
                sh 'docker compose ps'
            }
        }
    }
}
