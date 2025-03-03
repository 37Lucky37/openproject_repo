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

    stages {  // ❗ Один блок stages
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

        stage('Install rbenv and Ruby') {  // ❗ Виправлено вкладення
            steps {
                script {
                    sh """
                        echo '⬇️ Встановлюємо rbenv...'
                        if [ ! -d "\$HOME/.rbenv" ]; then
                            git clone https://github.com/rbenv/rbenv.git \$HOME/.rbenv
                        else
                            echo '✅ rbenv вже встановлено'
                        fi

                        echo 'export PATH="\$HOME/.rbenv/bin:\$PATH"' >> \$HOME/.bashrc
                        echo 'eval "\$(rbenv init -)"' >> \$HOME/.bashrc

                        echo '⬇️ Встановлюємо ruby-build...'
                        mkdir -p \$HOME/.rbenv/plugins
                        if [ ! -d "\$HOME/.rbenv/plugins/ruby-build" ]; then
                            git clone https://github.com/rbenv/ruby-build.git \$HOME/.rbenv/plugins/ruby-build
                        else
                            echo '✅ ruby-build вже встановлено'
                        fi

                        echo '⬇️ Встановлюємо Ruby ${RUBY_VERSION}...'
                        bash -c "source \$HOME/.bashrc && rbenv install ${RUBY_VERSION} -s && rbenv global ${RUBY_VERSION} && ruby -v"
                    """
                }
            }
        }

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
    } // ❗ Закриваємо єдиний блок `stages`
} // ❗ Закриваємо `pipeline`
