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

                 sh '''
                    echo "Waiting for openproject to be healthy..."
                    until [ "$(docker inspect -f '{{.State.Health.Status}}' openproject_app)" == "healthy" ]; do
                        sleep 5
                    done
                '''
              
                sh 'docker compose ps'
                sh 'docker logs openproject_app'
            }
        }
    }
}
