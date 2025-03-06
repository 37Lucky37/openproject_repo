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
                        echo '🏷 Генеруємо новий релізний тег...'
                        cd ${WORKSPACE}
                        
                        # Отримуємо останній тег або встановлюємо дефолт
                        LAST_TAG=\$(git describe --tags --abbrev=0 2>/dev/null || echo "1.0.0")
                        IFS='.' read -r MAJOR MINOR PATCH <<< "\$LAST_TAG"
                        
                        # Інкрементуємо версію
                        NEW_PATCH=\$((PATCH + 1))
                        NEW_TAG="\$MAJOR.\$MINOR.\$NEW_PATCH"
                        echo "Новий тег: \$NEW_TAG"

                        # Створюємо релізну гілку
                        RELEASE_BRANCH="${RELEASE_BRANCH_PREFIX}-v\$NEW_TAG"
                        git checkout -b "\$RELEASE_BRANCH"
                        git push origin "\$RELEASE_BRANCH"

                        # Створюємо тег і пушимо його
                        git tag "\$NEW_TAG"
                        git push origin "\$NEW_TAG"

                        echo "✅ Гілка \$RELEASE_BRANCH і тег \$NEW_TAG створені!"
                    """
                }
            }
        }

        stage('Create GitHub Release') {
            steps {
                script {
                    withCredentials([string(credentialsId: GITHUB_TOKEN_ID, variable: 'GITHUB_TOKEN')]) {
                        sh """
                            curl -X POST -H "Authorization: token \$GITHUB_TOKEN" \
                                -H "Accept: application/vnd.github.v3+json" \
                                https://api.github.com/repos/37Lucky37/openproject_repo/releases \
                                -d '{
                                    "tag_name": "'"\$NEW_TAG"'",
                                    "name": "Release '"\$NEW_TAG"'",
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
}
