pipeline {
    agent any

    environment {
        IMAGE = '192.168.10.23:5000/portal-b'
        GITOPS_REPO = 'https://github.com/skyworknav/ton-devops.git'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Determine Environment and Tag') {
            steps {
                script {
                    env.SHORT_SHA = sh(
                        script: 'git rev-parse --short=7 HEAD',
                        returnStdout: true
                    ).trim()

                    if (env.TAG_NAME) {
                        // Production release
                        env.DEPLOY_ENV = 'production'
                        env.IMAGE_TAG = env.TAG_NAME.replaceFirst(/^v/, '')
                        env.GITOPS_BRANCH = 'production'

                        echo "Production release: ${env.IMAGE_TAG}"
                    } else {
                        // Normal branch build = staging
                        env.DEPLOY_ENV = 'staging'
                        env.IMAGE_TAG = "staging-${env.SHORT_SHA}"
                        env.GITOPS_BRANCH = 'staging'

                        echo "Staging build: ${env.IMAGE_TAG}"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build \
                      -t ${IMAGE}:${IMAGE_TAG} \
                      .
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                sh '''
                    docker push ${IMAGE}:${IMAGE_TAG}
                '''
            }
        }

        stage('Update GitOps Repository') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-pat',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD'
                    )
                ]) {
                    sh '''
                        rm -rf gitops

                        git clone \
                          --branch ${GITOPS_BRANCH} \
                          https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/skyworknav/ton-devops.git \
                          gitops

                        cd gitops

                        sed -i \
                          "s|image: 192.168.10.23:5000/portal-b:.*|image: 192.168.10.23:5000/portal-b:${IMAGE_TAG}|" \
                          k8s/deployment.yaml

                        sed -i \
                          "/- name: APP_VERSION/{n;s/value: .*/value: \"${IMAGE_TAG}\"/;}" \
                          k8s/deployment.yaml

                        echo "Updated deployment:"
                        grep -nE 'image:|APP_VERSION|value:' k8s/deployment.yaml

                        git config user.name "Jenkins CI"
                        git config user.email "jenkins@localhost"

                        git add k8s/deployment.yaml

                        git commit \
                          -m "Deploy portal-b ${IMAGE_TAG} to ${DEPLOY_ENV}" \
                          || echo "No changes to commit"

                        git push origin ${GITOPS_BRANCH}
                    '''
                }
            }
        }
    }
}