pipeline {
    agent { label 'agent-build' } // Виконання на агенті
  
    triggers {
        githubPush()  // Тригер для GitHub push
    }
  
    environment {
        REPO = "git@github.com:37Lucky37/openproject_repo.git"
        BRANCH = "develop"
        CREDENTIALS_ID = "jenkins-openproject-cred" // ID SSH-ключа з Jenkins Credentials
        WORKSPACE_DIR = "${HOME}/openproject" // Директорія для стягування репозиторію
        NODE_VERSION = "20.18.3"
        RUBY_VERSION = "3.4.1"
        BUNDLER_VERSION = "2.6.3"
        RBENV_ROOT = "${HOME}/.rbenv"
        DB_TEST_NAME = "openproject_test_db"
        DB_TEST_USER = "openproject_test_user"
        DB_TEST_PASS = "testpassword"
        RELEASE_BRANCH_PREFIX = "release"
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

        // stage('Install PostgreSQL for Tests') {
        //     steps {
        //         script {
        //             sh """
        //                 echo '📦 Встановлюємо PostgreSQL...'
        //                 sudo apt update
        //                 sudo apt install -y postgresql postgresql-contrib
        //                 sudo systemctl start postgresql
        //                 sudo systemctl enable postgresql
        //             """
        //         }
        //     }
        // }
      
        // stage('Prepare Workspace') {
        //     steps {
        //         script {
        //             sh """
        //                 echo '🛠️ Очищаємо робочу директорію...'
        //                 rm -rf ${WORKSPACE_DIR}
        //                 mkdir -p ${WORKSPACE_DIR}
        //             """
        //         }
        //     }
        // }

        // stage('Clone Repository') {
        //     steps {
        //         script {
        //             checkout([$class: 'GitSCM',
        //                 branches: [[name: "*/${BRANCH}"]],
        //                 userRemoteConfigs: [[
        //                     url: REPO,
        //                     credentialsId: CREDENTIALS_ID
        //                 ]],
        //                 extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: "${WORKSPACE_DIR}"]]
        //             ])
        //         }
        //     }
        // }
      
//         stage('Setup Test Database') {
//             steps {
//                 script {
//                     sh '''
//                         echo "🔍 Перевіряємо чи існує користувач ${DB_TEST_USER}..."
//                         USER_EXISTS=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${DB_TEST_USER}';")
//                         if [ -z "$USER_EXISTS" ]; then
//                             echo "✅ Створюємо користувача..."
//                             sudo -u postgres psql -c "CREATE ROLE ${DB_TEST_USER} WITH SUPERUSER LOGIN PASSWORD '${DB_TEST_PASS}';"
//                         else
//                             echo "⚠️ Користувач вже існує. Пропускаємо."
//                         fi

//                         echo "🔍 Перевіряємо чи існує база даних ${DB_TEST_NAME}..."
//                         DB_EXISTS=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_TEST_NAME}';")
//                         if [ -z "$DB_EXISTS" ]; then
//                             echo "✅ Створюємо базу даних..."
//                             sudo -u postgres psql -c "CREATE DATABASE ${DB_TEST_NAME} OWNER ${DB_TEST_USER} ENCODING 'UTF8';"
//                         else
//                             echo "⚠️ База даних вже існує. Пропускаємо."
//                         fi
//                     '''
//                 }
//             }
//         }

//         stage('Install pgcrypto Extension') {
//             steps {
//                 script {
//                     sh """
//                         echo '🔍 Встановлюємо pgcrypto, якщо його немає...'
//                         sudo -u postgres psql -d ${DB_TEST_NAME} -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;"
//                     """
//                 }
//             }
//         }

//         stage('Setup Local Database Configuration') {
//             steps {
//                 script {
//                     sh """
//                         echo '🛠 Створюємо config/database.yml для тестів...'
//                         cd ${WORKSPACE_DIR}/config
//                         cat > database.yml <<EOL
// test:
//   adapter: postgresql
//   encoding: unicode
//   database: ${DB_TEST_NAME}
//   pool: 5
//   username: ${DB_TEST_USER}
//   password: ${DB_TEST_PASS}
//   host: localhost
//   port: 5432
// EOL
//                     """
//                 }
//             }
//         }

//         stage('Install Node.js') {
//             steps {
//                 script {
//                     sh """
//                         echo '⬇️ Встановлюємо Node.js ${NODE_VERSION}...'
//                         curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
//                         sudo apt install -y nodejs
//                         node -v
//                         npm -v
//                     """
//                 }
//             }
//         }

//         stage('Install Gem Dependencies') {
//             steps {
//                 script {
//                     sh """
//                         echo '📦 Встановлюємо Gem залежності...'
//                         cd ${WORKSPACE_DIR}
//                         /bin/bash --login -c "bundle install"
//                     """
//                 }
//             }
//         }

//         stage('Install npm Dependencies') {
//             steps {
//                 script {
//                     sh """
//                         echo '📦 Встановлюємо npm залежності...'
//                         cd ${WORKSPACE_DIR}
//                         if [ -f package.json ]; then
//                             npm install
//                         else
//                             echo '⚠️ package.json не знайдено. Пропускаємо встановлення.'
//                         fi
//                     """
//                 }
//             }
//         }

//         stage('Run Database Migrations') {
//             steps {
//                 script {
//                     sh """
//                         echo '📂 Запускаємо міграції для тестової БД...'
//                         cd ${WORKSPACE_DIR}
//                         RAILS_ENV=test /bin/bash --login -c "bundle exec rake db:migrate"
//                     """
//                 }
//             }
//         }
      
//         stage('Run Lefthook Pre-Commit') {
//             steps {
//                 script {
//                     sh """
//                         echo '🔍 Запускаємо Lefthook...'
//                         cd ${WORKSPACE_DIR}
//                         /bin/bash --login -c "lefthook run pre-commit"
//                     """
//                 }
//             }
//         }


//         stage('Verify Installation') {
//             steps {
//                 script {
//                     sh """
//                         echo '✅ Перевіряємо середовище:'
//                         /bin/bash --login -c "ruby -v"
//                         /bin/bash --login -c "bundler -v"
//                         node -v
//                         npm -v
//                     """
//                 }
//             }
//         }
   
        
//         stage('Run Simple Test') {
//             steps {
//                 script {
//                     sh """
//                         echo '✅ Виконуємо тестову команду:'
//                         echo 'Hello, Jenkins Agent!'
//                     """
//                 }
//             }
//         }

//         stage('Run Security & Lint Checks') {
//             steps {
//                 script {
//                     sh """
//                         echo '🔎 Виконуємо перевірку безпеки...'
//                         cd ${WORKSPACE_DIR}

//                         echo '🚀 Запускаємо Brakeman (не зупиняємо збірку при помилках)...'
//                         /bin/bash --login -c "bundle exec brakeman -A -z || true"

//                         echo '🎨 Запускаємо RuboCop для перевірки стилю коду...'
//                         /bin/bash --login -c "bundle exec rubocop || true"
//                     """
//                 }
//             }
//         }

//         stage('Run Unit & Integration Tests') {
//             steps {
//                 script {
//                     sh """
//                         echo '🧪 Запускаємо тести...'
//                         cd ${WORKSPACE_DIR}
//                         RAILS_ENV=test /bin/bash --login -c "bundle exec rspec spec/controllers/admin_controller_spec.rb --format documentation"
//                     """
//                 }
//             }
//         }

        stage('Create Release Branch') {
            when {
                expression { return currentBuild.result == null || currentBuild.result == 'SUCCESS' } // Запускаємо лише якщо тести пройшли успішно
            }
            steps {
                script {
                    sh """
                        echo '🔀 Створюємо гілку релізу...'
                        cd ${WORKSPACE_DIR}

                        # Стягуємо останні зміни з Git
                        git fetch origin ${BRANCH}
                        git checkout ${BRANCH}
                        git pull origin ${BRANCH}

                        # Отримуємо хеш поточного коміту
                        COMMIT_HASH=\$(git rev-parse HEAD)
                        echo "Поточний коміт: \$COMMIT_HASH"

                        # Створюємо унікальну гілку релізу
                        RELEASE_BRANCH="${RELEASE_BRANCH_PREFIX}-\$(date +%Y-%m-%d_%H-%M)"
                        echo "Нова гілка релізу: \$RELEASE_BRANCH"

                        # Переключаємося на нову гілку та пушимо її
                        git checkout -b \$RELEASE_BRANCH \$COMMIT_HASH
                        git push origin \$RELEASE_BRANCH

                        echo "✅ Гілка \$RELEASE_BRANCH створена та запушена!"
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
