pipeline {
    agent { label 'agent-build' } // Виконання на агенті з міткою 'build-agent'

    environment {
        REPO = "git@github.com:37Lucky37/openproject_repo.git"
        BRANCH = "main"
        CREDENTIALS_ID = "jenkins-openproject-cred" // ID SSH-ключа з Jenkins Credentials
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

        stage('Verify Files') {
            steps {
                script {
                    sh """
                        echo '📂 Перевіряємо файли у репозиторії:'
                        ls -la
                    """
                }
            }
        }

        stage('Run Simple Test') {
            steps {
                script {
                    sh """
                        echo '✅ Виконуємо тестову команду:'
                        echo 'Hello, Jenkins Agent!'
                    """
                }
            }
        }

        stage('Check Environment') {
            steps {
                script {
                    sh """
                        echo '🖥️ Перевіряємо середовище на агенті:'
                        uname -a
                        whoami
                        pwd
                    """
                }
            }
        }
    }
}
