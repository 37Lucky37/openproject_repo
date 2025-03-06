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
        DB_TEST_NAME = "openproject_test_db"
        DB_TEST_USER = "openproject_test_user"
        DB_TEST_PASS = "testpassword"
        RELEASE_BRANCH_PREFIX = "release"
    }

    stages {  // ❗ Один блок stages
        

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
      

        stage('Create Release Branch') {
            steps {
                script {
                    sh """
                        echo '🔀 Створюємо нову релізну гілку...'
                        cd ${WORKSPACE_DIR}

                        # Отримуємо останній тег або встановлюємо дефолтний
                        LAST_TAG=\$(git fetch --tags && git tag --sort=-v:refname | head -n 1 || echo "1.0.0")
                        echo "Останній тег: \$LAST_TAG"

                        # Перевіряємо правильність формату тегу (X.Y.Z)
                        if [[ "\$LAST_TAG" =~ ^[0-9]+\\.[0-9]+\\.[0-9]+$ ]]; then
                            IFS=. read -r MAJOR MINOR PATCH <<< "\$LAST_TAG"
                        else
                            echo "❌ Помилка: Некоректний формат тегу: \$LAST_TAG"
                            exit 1
                        fi

                        # Інкрементуємо PATCH-версію (1.0.0 → 1.0.1)
                        NEW_PATCH=\$((PATCH + 1))
                        NEW_TAG="\$MAJOR.\$MINOR.\$NEW_PATCH"
                        echo "Новий тег: \$NEW_TAG"

                        # Створюємо нову гілку релізу
                        RELEASE_BRANCH="${RELEASE_BRANCH_PREFIX}-v\$NEW_TAG"
                        echo "Створюємо гілку: \$RELEASE_BRANCH"

                        git checkout -b "\$RELEASE_BRANCH"
                        git push origin "\$RELEASE_BRANCH"

                        # Створюємо новий тег і пушимо його
                        git tag "\$NEW_TAG"
                        git push origin "\$NEW_TAG"

                        echo "✅ Гілка \$RELEASE_BRANCH і тег \$NEW_TAG успішно створені!"
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
