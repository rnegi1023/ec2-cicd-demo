pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
        timeout(time: 15, unit: 'MINUTES')
    }

    parameters {
        choice(
            name: 'DEPLOY_TARGET',
            choices: ['NGINX', 'TOMCAT'],
            description: 'Select application to build and deploy'
        )
    }

    environment {
        APP_HOST = '172.31.19.91'
        APP_USER = 'deploy'
        SSH_CREDENTIAL_ID = 'app-server-ssh'
    }

    stages {
        stage('Checkout') {
            steps {
                deleteDir()
                checkout scm
            }
        }

        stage('Validate Tools') {
            steps {
                sh '''
                    set -eu
                    command -v ssh
                    command -v scp
                    command -v curl
                '''

                script {
                    if (params.DEPLOY_TARGET == 'TOMCAT') {
                        sh '''
                            set -eu
                            command -v mvn
                            java -version
                            mvn --version
                        '''
                    } else {
                        sh '''
                            set -eu
                            command -v rsync
                            test -s nginx-site/index.html
                        '''
                    }
                }
            }
        }

        stage('Build and Test WAR') {
            when {
                expression {
                    params.DEPLOY_TARGET == 'TOMCAT'
                }
            }

            steps {
                dir('tomcat-app') {
                    sh '''
                        set -eu
                        mvn -B clean verify
                        test -s target/myapp.war
                    '''
                }

                archiveArtifacts(
                    artifacts: 'tomcat-app/target/myapp.war',
                    fingerprint: true
                )
            }
        }

        stage('Package Website') {
            when {
                expression {
                    params.DEPLOY_TARGET == 'NGINX'
                }
            }

            steps {
                sh '''
                    set -eu
                    test -s nginx-site/index.html
                    tar -czf nginx-site.tar.gz -C nginx-site .
                '''

                archiveArtifacts(
                    artifacts: 'nginx-site.tar.gz',
                    fingerprint: true
                )
            }
        }

        stage('Check SSH Connection') {
            steps {
                sshagent(credentials: [env.SSH_CREDENTIAL_ID]) {
                    sh '''
                        set -eu

                        ssh \
                          -o BatchMode=yes \
                          -o StrictHostKeyChecking=yes \
                          -o ConnectTimeout=10 \
                          "$APP_USER@$APP_HOST" \
                          'echo "SSH connection successful"; whoami'
                    '''
                }
            }
        }

        stage('Deploy WAR to Tomcat') {
            when {
                expression {
                    params.DEPLOY_TARGET == 'TOMCAT'
                }
            }

            steps {
                sshagent(credentials: [env.SSH_CREDENTIAL_ID]) {
                    sh '''
                        set -eu

                        # पहले temporary नाम से transfer करें।
                        scp \
                          -o BatchMode=yes \
                          -o StrictHostKeyChecking=yes \
                          -o ConnectTimeout=10 \
                          tomcat-app/target/myapp.war \
                          "$APP_USER@$APP_HOST:/home/deploy/uploads/myapp.war.tmp"

                        ssh \
                          -o BatchMode=yes \
                          -o StrictHostKeyChecking=yes \
                          -o ConnectTimeout=10 \
                          "$APP_USER@$APP_HOST" \
                          'mv /home/deploy/uploads/myapp.war.tmp /home/deploy/uploads/myapp.war &&
                           sudo -n /usr/local/bin/deploy-tomcat'
                    '''
                }
            }
        }

        stage('Deploy Website to Nginx') {
            when {
                expression {
                    params.DEPLOY_TARGET == 'NGINX'
                }
            }

            steps {
                sshagent(credentials: [env.SSH_CREDENTIAL_ID]) {
                    sh '''
                        set -eu

                        rsync \
                          -rv \
                          --delete \
                          --safe-links \
                          --chmod=D755,F644 \
                          -e "ssh -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=10" \
                          nginx-site/ \
                          "$APP_USER@$APP_HOST:/var/www/myapp/"
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    def appUrl = params.DEPLOY_TARGET == 'TOMCAT'
                        ? "http://${env.APP_HOST}:8080/myapp/"
                        : "http://${env.APP_HOST}/"

                    withEnv(["APP_URL=${appUrl}"]) {
                        sh '''
                            set -eu

                            curl \
                              --fail \
                              --silent \
                              --show-error \
                              --connect-timeout 5 \
                              --max-time 15 \
                              "$APP_URL" \
                              -o deployed-page.html
                        '''

                        script {
                            if (params.DEPLOY_TARGET == 'TOMCAT') {
                                sh """
                                    grep -Fq \
                                      'Tomcat deployment successful!' \
                                      deployed-page.html
                                """
                            } else {
                                sh """
                                    grep -Fq \
                                      'Nginx deployment successful!' \
                                      deployed-page.html
                                """
                            }
                        }
                    }

                    echo "Deployment verified: ${appUrl}"
                }
            }
        }
    }

    post {
        success {
            echo 'Build and deployment completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check the failed stage and Console Output.'
        }

        always {
            echo "Selected target: ${params.DEPLOY_TARGET}"
        }
    }
}
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
        timeout(time: 15, unit: 'MINUTES')
    }

    parameters {
        choice(
            name: 'DEPLOY_TARGET',
            choices: ['NGINX', 'TOMCAT'],
            description: 'Select application to build and deploy'
        )
    }

    environment {
        APP_HOST = '172.31.19.91'
        APP_USER = 'deploy'
        SSH_CREDENTIAL_ID = 'app-server-ssh'
    }

    stages {
        stage('Checkout') {
            steps {
                deleteDir()
                checkout scm
            }
        }

        stage('Validate Tools') {
            steps {
                sh '''
                    set -eu
                    command -v ssh
                    command -v scp
                    command -v curl
                '''

                script {
                    if (params.DEPLOY_TARGET == 'TOMCAT') {
                        sh '''
                            set -eu
                            command -v mvn
                            java -version
                            mvn --version
                        '''
                    } else {
                        sh '''
                            set -eu
                            command -v rsync
                            test -s nginx-site/index.html
                        '''
                    }
                }
            }
        }

        stage('Build and Test WAR') {
            when {
                expression {
                    params.DEPLOY_TARGET == 'TOMCAT'
                }
            }

            steps {
                dir('tomcat-app') {
                    sh '''
                        set -eu
                        mvn -B clean verify
                        test -s target/myapp.war
                    '''
                }

                archiveArtifacts(
                    artifacts: 'tomcat-app/target/myapp.war',
                    fingerprint: true
                )
            }
        }

        stage('Package Website') {
            when {
                expression {
                    params.DEPLOY_TARGET == 'NGINX'
                }
            }

            steps {
                sh '''
                    set -eu
                    test -s nginx-site/index.html
                    tar -czf nginx-site.tar.gz -C nginx-site .
                '''

                archiveArtifacts(
                    artifacts: 'nginx-site.tar.gz',
                    fingerprint: true
                )
            }
        }

        stage('Check SSH Connection') {
            steps {
                sshagent(credentials: [env.SSH_CREDENTIAL_ID]) {
                    sh '''
                        set -eu

                        ssh \
                          -o BatchMode=yes \
                          -o StrictHostKeyChecking=yes \
                          -o ConnectTimeout=10 \
                          "$APP_USER@$APP_HOST" \
                          'echo "SSH connection successful"; whoami'
                    '''
                }
            }
        }

        stage('Deploy WAR to Tomcat') {
            when {
                expression {
                    params.DEPLOY_TARGET == 'TOMCAT'
                }
            }

            steps {
                sshagent(credentials: [env.SSH_CREDENTIAL_ID]) {
                    sh '''
                        set -eu

                        # पहले temporary नाम से transfer करें।
                        scp \
                          -o BatchMode=yes \
                          -o StrictHostKeyChecking=yes \
                          -o ConnectTimeout=10 \
                          tomcat-app/target/myapp.war \
                          "$APP_USER@$APP_HOST:/home/deploy/uploads/myapp.war.tmp"

                        ssh \
                          -o BatchMode=yes \
                          -o StrictHostKeyChecking=yes \
                          -o ConnectTimeout=10 \
                          "$APP_USER@$APP_HOST" \
                          'mv /home/deploy/uploads/myapp.war.tmp /home/deploy/uploads/myapp.war &&
                           sudo -n /usr/local/bin/deploy-tomcat'
                    '''
                }
            }
        }

        stage('Deploy Website to Nginx') {
            when {
                expression {
                    params.DEPLOY_TARGET == 'NGINX'
                }
            }

            steps {
                sshagent(credentials: [env.SSH_CREDENTIAL_ID]) {
                    sh '''
                        set -eu

                        rsync \
                          -rv \
                          --delete \
                          --safe-links \
                          --chmod=D755,F644 \
                          -e "ssh -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=10" \
                          nginx-site/ \
                          "$APP_USER@$APP_HOST:/var/www/myapp/"
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    def appUrl = params.DEPLOY_TARGET == 'TOMCAT'
                        ? "http://${env.APP_HOST}:8080/myapp/"
                        : "http://${env.APP_HOST}/"

                    withEnv(["APP_URL=${appUrl}"]) {
                        sh '''
                            set -eu

                            curl \
                              --fail \
                              --silent \
                              --show-error \
                              --connect-timeout 5 \
                              --max-time 15 \
                              "$APP_URL" \
                              -o deployed-page.html
                        '''

                        script {
                            if (params.DEPLOY_TARGET == 'TOMCAT') {
                                sh """
                                    grep -Fq \
                                      'Tomcat deployment successful!' \
                                      deployed-page.html
                                """
                            } else {
                                sh """
                                    grep -Fq \
                                      'Nginx deployment successful!' \
                                      deployed-page.html
                                """
                            }
                        }
                    }

                    echo "Deployment verified: ${appUrl}"
                }
            }
        }
    }

    post {
        success {
            echo 'Build and deployment completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check the failed stage and Console Output.'
        }

        always {
            echo "Selected target: ${params.DEPLOY_TARGET}"
        }
    }
}