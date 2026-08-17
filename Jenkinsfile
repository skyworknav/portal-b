pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    SHORT_SHA=$(git rev-parse --short=7 HEAD)

                    docker build \
                      -t 192.168.10.23:5000/portal-b:${SHORT_SHA} \
                      .
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                sh '''
                    SHORT_SHA=$(git rev-parse --short=7 HEAD)

                    docker push \
                      192.168.10.23:5000/portal-b:${SHORT_SHA}
                '''
            }
        }
    }
}