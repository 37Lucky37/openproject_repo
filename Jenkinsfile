pipeline {
    agent { label 'vagrant' } // Виконання на агенті з міткою 'build-agent'

    environment {
        REPO = "git@github.com:37Lucky37/openproject_repo.git"
        BRANCH = "main"
        CREDENTIALS_ID = "agent-ssh-key" // ID SSH-ключа з Jenkins Credentials
    }

    stages {
        stage('Clone Repository') {
            steps {
                script {
                    checkout([$class: 'GitSCM',
                        branches: [[name: "*/${BRANCH}"]],
                        userRemoteConfigs: [[
                            url: REPO,
                            credentialsId: CREDENTIALS_ID
                        ]]
                    ])
                }
            }
        }
    }
}
