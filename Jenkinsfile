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
        RBENV_ROOT = "${HOME}/.rbenv"
        ARTIFACT_NAME = "openproject_build-5.0.tar.gz"
        DEPLOY_USER = "vagrant" // Юзер на сервері
        DEPLOY_HOST = "192.168.77.104" // IP цільового сервера
        DEPLOY_DIR = "/home/vagrant/ansible/openproject/artifacts" // Куди заливати
        DB_TEST_NAME = "openproject_test_db"
        DB_TEST_USER = "openproject_test_user"
        DB_TEST_PASS = "testpassword"
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

        stage('Install Ruby using RVM') {
            steps {
                script {
                    sh """
                        echo '📌 Додаємо GPG-ключі для RVM...'
                        gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB || \
                        (command curl -sSL https://rvm.io/mpapis.asc | gpg --import - && \
                        command curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -)

                        echo '⬇️ Встановлюємо RVM...'
                        if [ ! -d "\$HOME/.rvm" ]; then
                            sudo apt update
                            sudo apt install -y curl gpg
                            curl -sSL https://get.rvm.io | bash -s stable
                        fi

                        echo '⬇️ Завантажуємо середовище RVM...'
                        echo 'source \$HOME/.rvm/scripts/rvm' >> ~/.bashrc

                        echo '⬇️ Встановлюємо Ruby...'
                        /bin/bash --login -c "rvm install 3.4.1"
                        /bin/bash --login -c "rvm use 3.4.1 --default"
                        /bin/bash --login -c "ruby -v"
                    """
                }
            }
        }

        stage('Install Bundler') {
            steps {
                script {
                    sh """
                        echo '⬇️ Встановлюємо Bundler ${BUNDLER_VERSION}...'
                        /bin/bash --login -c "gem install bundler -v ${BUNDLER_VERSION}"
                        /bin/bash --login -c "bundler -v"
                        echo '⬇️ Встановлюємо Lefthook...'
                        /bin/bash --login -c "gem install lefthook"
                        /bin/bash --login -c "lefthook version"
                    """
                }
            }
        }

        stage('Upgrade Git') {
            steps {
                script {
                    sh """
                        echo '⬆️ Оновлюємо Git...'
                        sudo add-apt-repository ppa:git-core/ppa -y
                        sudo apt update
                        sudo apt install -y git
                        git --version
                    """
                }
            }
        }

        stage('Install PostgreSQL for Tests') {
            steps {
                script {
                    sh """
                        echo '📦 Встановлюємо PostgreSQL...'
                        sudo apt update
                        sudo apt install -y postgresql postgresql-contrib
                        sudo systemctl start postgresql
                        sudo systemctl enable postgresql
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
      
        stage('Setup Test Database') {
            steps {
                script {
                    sh """
                        # Створюємо користувача з правами SUPERUSER
                        sudo -u postgres psql -c "CREATE ROLE ${DB_TEST_USER} WITH SUPERUSER LOGIN PASSWORD '${DB_TEST_PASS}';"
                
                        # Створюємо тестову базу, якщо її немає
                        sudo -u postgres psql -c "CREATE DATABASE ${DB_TEST_NAME} OWNER ${DB_TEST_USER} ENCODING 'UTF8';"
                    """
                }
            }
        }


        stage('Setup Local Database Configuration') {
            steps {
                script {
                    sh """
                        echo '🛠 Створюємо config/database.yml для тестів...'
                        cd ${WORKSPACE_DIR}/config
                        cat > database.yml <<EOL
test:
  adapter: postgresql
  encoding: unicode
  database: ${DB_TEST_NAME}
  pool: 5
  username: ${DB_TEST_USER}
  password: ${DB_TEST_PASS}
  host: localhost
  port: 5432
EOL
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

        stage('Install Gem Dependencies') {
            steps {
                script {
                    sh """
                        echo '📦 Встановлюємо Gem залежності...'
                        cd ${WORKSPACE_DIR}
                        /bin/bash --login -c "bundle install"
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

        stage('Run Database Migrations') {
            steps {
                script {
                    sh """
                        echo '📂 Запускаємо міграції для тестової БД...'
                        cd ${WORKSPACE_DIR}
                        RAILS_ENV=test /bin/bash --login -c "bundle exec rake db:migrate"
                    """
                }
            }
        }
      
        // stage('Run Lefthook Pre-Commit') {
        //     steps {
        //         script {
        //             sh """
        //                 echo '🔍 Запускаємо Lefthook...'
        //                 cd ${WORKSPACE_DIR}
        //                 /bin/bash --login -c "lefthook run pre-commit"
        //             """
        //         }
        //     }
        // }


        // stage('Verify Installation') {
        //     steps {
        //         script {
        //             sh """
        //                 echo '✅ Перевіряємо середовище:'
        //                 /bin/bash --login -c "ruby -v"
        //                 /bin/bash --login -c "bundler -v"
        //                 node -v
        //                 npm -v
        //             """
        //         }
        //     }
        // }
   
        
        // stage('Run Simple Test') {
        //     steps {
        //         script {
        //             sh """
        //                 echo '✅ Виконуємо тестову команду:'
        //                 echo 'Hello, Jenkins Agent!'
        //             """
        //         }
        //     }
        // }

        // stage('Run Unit & Integration Tests') {
        //     steps {
        //         script {
        //             sh """
        //                 echo '🧪 Запускаємо тести...'
        //                 cd ${WORKSPACE_DIR}
        //                 RAILS_ENV=test /bin/bash --login -c "bundle exec rspec"
        //             """
        //         }
        //     }
        // }

        // stage('Run Frontend Tests') {
        //     steps {
        //         script {
        //             sh """
        //                 echo '🧪 Запускаємо фронтенд тести...'
        //                 cd ${WORKSPACE_DIR}/frontend
        //                 npm run test
        //             """
        //         }
        //     }
        // }

        // stage('Run System (End-to-End) Tests') {
        //     steps {
        //         script {
        //             sh """
        //                 echo '🧪 Запускаємо системні тести...'
        //                 cd ${WORKSPACE_DIR}
        //                 RAILS_ENV=test /bin/bash --login -c "bundle exec rake spec:system"
        //             """
        //         }
        //     }
        // }

        // stage('Run Security & Lint Checks') {
        //     steps {
        //         script {
        //             sh """
        //                 echo '🔎 Виконуємо перевірку безпеки...'
        //                 cd ${WORKSPACE_DIR}
        //                 /bin/bash --login -c "bundle exec brakeman -A -z"

        //                 echo '🎨 Запускаємо RuboCop для перевірки стилю коду...'
        //                 /bin/bash --login -c "bundle exec rubocop"
        //             """
        //         }
        //     }
        // }
      
        // stage('Check Environment') {
        //     steps {
        //         script {
        //             sh """
        //                 echo '🖥️ Перевіряємо середовище на агенті:'
        //                 uname -a
        //                 whoami
        //                 pwd
        //             """
        //         }
        //     }
        // }
    } // ❗ Закриваємо єдиний блок `stages`
} // ❗ Закриваємо `pipeline`
