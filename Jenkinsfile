pipeline {
    agent {
        docker {
            image 'node:18-alpine'  // imagem leve do Node.js
            args '-u root:root'     // rodar como root para instalar o Snyk
        }
    }
    stages {
        stage('Preparation') {
            steps {
                git 'https://github.com/sretriples/setups.git'
            }
        }
        stage('Install dependencies') {
            steps {
                sh 'npm install'
            }
        }
        stage('Install Snyk CLI') {
            steps {
                sh 'npm install -g snyk'
            }
        }
        stage('Scan with Snyk') {
            environment {
                SNYK_TOKEN = credentials('snyk')  // seu token no Jenkins
            }
            steps {
                sh '''
                    snyk auth $SNYK_TOKEN
                    snyk test --severity-threshold=medium
                '''
            }
        }
        stage('Build') {
            steps {
                echo 'Aqui você pode rodar seu build (se tiver)'
            }
        }
    }
}
