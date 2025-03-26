pipeline {
    agent { label 'docker-agent' }

    environment {
        DOCKERHUB_USER = '37lucky37'   
        DOCKERHUB_REPO = 'my-openproject'              
        IMAGE_TAG = 'latest'                        
    }
    
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
        // stage("Start building") {
        //     steps {
        //         sh 'docker compose up openproject -d --build --wait'

        //          sh '''
        //             echo "Waiting for OpenProject to be ready..."
        //             until docker logs openproject_app 2>&1 | grep -q "CI checks passed successfully!"; do
        //                 sleep 5
        //             done
        //         '''
              
        //         sh 'docker compose ps'
        //         sh 'docker logs openproject_app'
        //     }
        // }

        stage("Push to Docker Hub") {
            steps {
                script {
                    
                    withCredentials([string(credentialsId: 'docker-hub-password', variable: 'DOCKERHUB_PASS')]) {
                        sh 'echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin'
                    }

                    sh 'docker tag docker-compose-openproject $DOCKERHUB_USER/$DOCKERHUB_REPO:$IMAGE_TAG'

                    sh 'docker push $DOCKERHUB_USER/$DOCKERHUB_REPO:$IMAGE_TAG'

                    sh 'docker logout'
                }
            }
        }
    }
}
