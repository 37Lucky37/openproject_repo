pipeline {
    agent { label 'agent-build' } // Виконання на агенті

    environment {
        REPO = "git@github.com:37Lucky37/openproject_repo.git"
        BRANCH = "main"
        CREDENTIALS_ID = "jenkins-openproject-cred" // ID SSH-ключа з Jenkins Credentials
        WORKSPACE_DIR = "${HOME}/openproject" // Директорія для стягування репозиторію
        NODE_VERSION = "20.18.3"
        RUBY_VERSION = "3.4.1"
        BUNDLER_VERSION = "2.6.3"
    }

    stages {
        stage('Prepare Workspace') {
            steps {
                script {
                    sh """
                        echo '🛠️ Очищаємо робочу директорію...'
                        rm -rf ${WORKSPACE_DIR}
                        mkdir -p ${WORKSPACE_DIR}
                    """
                }
            }
        }

        stage('Clone Repository') {
            steps {
                script {
                    checkout([$class: 'GitSCM',
                        branches: [[name: "*/${BRANCH}"]],
                        userRemoteConfigs: [[
                            url: REPO,
                            credentialsId: CREDENTIALS_ID
                        ]],
                        extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: "${WORKSPACE_DIR}"]]
                    ])
                }
            }
        }

        stage('Install System Dependencies') {
            steps {
                script {
                    sh """
                        echo '📦 Встановлюємо системні залежності...'
                        sudo apt update && sudo apt install -y \
                          libffi-dev libyaml-dev libgmp-dev zlib1g-dev libssl-dev libreadline-dev \
                          libxml2-dev libxslt1-dev build-essential gcc g++ make libpq-dev memcached \
                          imagemagick libapr1 libaprutil1 libjansson4
                    """
                }
            }
        }

        stage('Install Node.js') {
            steps {
                script {
                    sh """
                        echo '⬇️ Встановлюємо Node.js ${NODE_VERSION}...'
                        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
                        sudo apt install -y nodejs
                        node -v
                        npm -v
                    """
                }
            }
        }

        stage('Install Ruby and Bundler') {
            steps {
                script {
                    sh """
                        echo '⬇️ Встановлюємо Ruby ${RUBY_VERSION}...'
                        sudo apt install -y rbenv
                        export PATH="$HOME/.rbenv/bin:$PATH"

                        # Виправлений eval
                        eval \"\$(rbenv init -)\"

                        rbenv install ${RUBY_VERSION} -s
                        rbenv global ${RUBY_VERSION}
                        ruby -v

                        echo '⬇️ Встановлюємо Bundler ${BUNDLER_VERSION}...'
                        gem install bundler -v ${BUNDLER_VERSION}
                        bundler -v
                    """
                }
            }
        }

        stage('Install Gem Dependencies') {
            steps {
                script {
                    sh """
                        echo '📦 Встановлюємо Gem залежності...'
                        cd ${WORKSPACE_DIR}
                        bundle install --without development test
                    """
                }
            }
        }

        stage('Install npm Dependencies') {
            steps {
                script {
                    sh """
                        echo '📦 Встановлюємо npm залежності...'
                        cd ${WORKSPACE_DIR}
                        if [ -f package.json ]; then
                            npm install
                        else
                            echo '⚠️ package.json не знайдено. Пропускаємо встановлення.'
                        fi
                    """
                }
            }
        }

        stage('Verify Installation') {
            steps {
                script {
                    sh """
                        echo '✅ Перевіряємо середовище:'
                        ruby -v
                        bundler -v
                        node -v
                        npm -v
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
