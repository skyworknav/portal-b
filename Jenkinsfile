pipeline {
    agent any

    environment {
        REGISTRY = '192.168.10.23:5000'
        IMAGE = '192.168.10.23:5000/portal-b'
        GITOPS_REPO = 'https://github.com/skyworknav/ton-devops.git'
        GITOPS_BRANCH = 'production'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Set Image Tag') {
            steps {
                script {
                    env.SHORT_SHA = sh(
                        script: 'git rev-parse --short=7 HEAD',
                        returnStdout: true
                    ).trim()

                    echo "Image tag: ${env.SHORT_SHA}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build \
                      -t ${IMAGE}:${SHORT_SHA} \
                      .
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                sh '''
                    docker push ${IMAGE}:${SHORT_SHA}
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
                          "s|image: 192.168.10.23:5000/portal-b:.*|image: 192.168.10.23:5000/portal-b:${SHORT_SHA}|" \
                          k8s/deployment.yaml

                        sed -i \
                          "/- name: APP_VERSION/{n;s/value: .*/value: \"${SHORT_SHA}\"/;}" \
                          k8s/deployment.yaml

                        echo "Updated deployment:"
                        grep -nE 'image:|APP_VERSION|value:' k8s/deployment.yaml

                        git config user.name "Jenkins CI"
                        git config user.email "jenkins@localhost"

                        git add k8s/deployment.yaml

                        git commit \
                          -m "Deploy portal-b ${SHORT_SHA} to production" \
                          || echo "No changes to commit"

                        git push origin ${GITOPS_BRANCH}
                    '''
                }
            }
        }
    }
}