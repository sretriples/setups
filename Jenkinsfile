pipeline {
    agent {
        docker {
            image 'node:18-alpine'
            args '-u root:root'
        }
    }

    environment {
        SNYK_TOKEN = credentials('snyk') // ID da sua credencial do tipo "Secret text"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/sretriples/setups.git'
            }
        }

        stage('Install dependencies') {
            steps {
                sh 'npm install'
                sh 'npm install -g snyk' // instala Snyk CLI
            }
        }

        stage('Snyk Scan') {
            steps {
                sh 'snyk test --severity-threshold=medium'
            }
        }

        stage('Build') {
            steps {
                echo 'Build stage running...'
            }
        }
    }
}
