pipeline {
    agent { label 'agent-build' } 

    environment {
        REPO = "git@github.com:37Lucky37/openproject_repo.git"
        BRANCH = "develop"
        CREDENTIALS_ID = "jenkins-openproject-cred"
        WORKSPACE_DIR = "${env.HOME}/openproject"
        RELEASE_BRANCH_PREFIX = "release"
    }

    stages {
        stage('Prepare Workspace') {
            steps {
                script {
                    sh '''
                        echo "🛠 Очищаємо робочу директорію..."
                        rm -rf ${WORKSPACE_DIR}
                        mkdir -p ${WORKSPACE_DIR}
                    '''
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
                        extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: WORKSPACE_DIR]]
                    ])
                }
            }
        }

        stage('Create Release Branch') {
            steps {
                script {
                    sh '''
                        echo "🔀 Створюємо нову релізну гілку..."
                        cd ${WORKSPACE_DIR}

                        # Отримуємо останній тег або встановлюємо дефолтний
                        LAST_TAG=$(git fetch --tags && git tag --sort=-v:refname | head -n 1)
                        if [ -z "$LAST_TAG" ]; then
                            LAST_TAG="1.0.0"
                        fi
                        echo "Останній тег: $LAST_TAG"

                        # Перевіряємо правильність формату тегу (X.Y.Z)
                        if echo "$LAST_TAG" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
                            MAJOR=$(echo "$LAST_TAG" | cut -d. -f1)
                            MINOR=$(echo "$LAST_TAG" | cut -d. -f2)
                            PATCH=$(echo "$LAST_TAG" | cut -d. -f3)
                        else
                            echo "❌ Помилка: Некоректний формат тегу: $LAST_TAG"
                            exit 1
                        fi

                        # Інкрементуємо PATCH-версію (1.0.0 → 1.0.1)
                        NEW_PATCH=$((PATCH + 1))
                        NEW_TAG="$MAJOR.$MINOR.$NEW_PATCH"
                        echo "Новий тег: $NEW_TAG"

                        # Створюємо нову гілку релізу
                        RELEASE_BRANCH="${RELEASE_BRANCH_PREFIX}-v$NEW_TAG"
                        echo "Створюємо гілку: $RELEASE_BRANCH"

                        git checkout -b "$RELEASE_BRANCH"
                        git push origin "$RELEASE_BRANCH"

                        # Створюємо новий тег і пушимо його
                        git tag "$NEW_TAG"
                        git push origin "$NEW_TAG"

                        echo "✅ Гілка $RELEASE_BRANCH і тег $NEW_TAG успішно створені!"
                    '''
                }
            }
        }
    }
}
