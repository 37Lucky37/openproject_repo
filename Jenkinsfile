pipeline {
    agent { label 'agent-build' }

    environment {
        REPO = "git@github.com:37Lucky37/openproject_repo.git"
        CREDENTIALS_ID = "jenkins-openproject-cred"
        GITHUB_TOKEN_ID = "github-token"
        RELEASE_BRANCH_PREFIX = "release"
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    checkout([$class: 'GitSCM',
                        branches: [[name: "*/develop"]],
                        userRemoteConfigs: [[
                            url: REPO,
                            credentialsId: CREDENTIALS_ID
                        ]]
                    ])
                }
            }
        }

        stage('Create Release Branch & Tag') {
            steps {
                script {
                    sh """
                        echo '🏷 Отримуємо останній тег...'
                        cd ${WORKSPACE}

                        # Отримуємо останній тег або встановлюємо дефолтний
                        LAST_TAG=\$(git tag --sort=-v:refname | head -n 1 || echo "1.0.0")
                        echo "LAST_TAG: \$LAST_TAG"

                        # Перевіряємо формат тегу (без "v" попереду)
                        if [[ "\$LAST_TAG" =~ ^[0-9]+\\.[0-9]+\\.[0-9]+$ ]]; then
                            IFS=. read -r MAJOR MINOR PATCH <<< "\$LAST_TAG"
                        else
                            echo "Помилка: Некоректний формат тегу: \$LAST_TAG"
                            exit 1
                        fi

                        # Збільшуємо PATCH-версію
                        NEW_PATCH=\$((PATCH + 1))
                        NEW_TAG="\$MAJOR.\$MINOR.\$NEW_PATCH"
                        echo "Новий тег: \$NEW_TAG"

                        # Створюємо нову релізну гілку
                        RELEASE_BRANCH="${RELEASE_BRANCH_PREFIX}-\$NEW_TAG"
                        git checkout -b "\$RELEASE_BRANCH"
                        git push origin "\$RELEASE_BRANCH"

                        # Створюємо та пушимо новий тег
                        git tag "\$NEW_TAG"
                        git push origin "\$NEW_TAG"

                        # Зберігаємо тег у файл
                        echo "\$NEW_TAG" > new_tag.txt
                    """

                    stash includes: 'new_tag.txt', name: 'tag_file'
                }
            }
        }

        stage('Create GitHub Release') {
            steps {
                script {
                    unstash 'tag_file'
                    def newTag = readFile('new_tag.txt').trim()

                    withCredentials([string(credentialsId: GITHUB_TOKEN_ID, variable: 'GITHUB_TOKEN')]) {
                        sh """
                            curl -X POST -H "Authorization: token \$GITHUB_TOKEN" \
                                -H "Accept: application/vnd.github.v3+json" \
                                https://api.github.com/repos/37Lucky37/openproject_repo/releases \
                                -d '{
                                    "tag_name": "'"\$newTag"'",
                                    "name": "Release '"\$newTag"'",
                                    "body": "Автоматично створений реліз через Jenkins",
                                    "draft": false,
                                    "prerelease": false
                                }'
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "🎉 Успішно створено реліз!"
        }
        failure {
            echo "❌ Помилка у виконанні пайплайну"
        }
        always {
            cleanWs()
        }
    }
}
