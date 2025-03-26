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
                    echo "Waiting for OpenProject to be ready..."
                    until docker logs openproject_app 2>&1 | grep -q "CI checks passed successfully!"; do
                        sleep 5
                    done
                '''
              
                sh 'docker compose ps'
                sh 'docker logs openproject_app'
            }
        }
    }
}
