pipeline {
    agent {
        docker {
            image 'node:18-alpine'
            args '-u root:root'
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
                SNYK_TOKEN = credentials('snyk')
            }
            steps {
                sh '''
                    snyk auth $SNYK_TOKEN
                    snyk test --severity-threshold=medium
                
            }
        }
        stage('Build') {
            steps {
                echo 'Rodando app Hello World para validar'
                sh '''
                    node index.js &
                    PID=$!
                    sleep 5
                    kill $PID
                    echo "App rodou por 5 segundos e foi finalizado."
                
            }
        }
    }
}


