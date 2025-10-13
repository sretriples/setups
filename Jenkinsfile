pipeline {
    agent {
        docker {
            image 'node:18-alpine'
            args '-u root:root'
        }
    }
    environment {
        SNYK_TOKEN = credentials('snyk') // usa o ID da credencial que você configurou
    }
    stages {
        stage('Preparation') {
            steps {
                git branch: 'main', url: 'https://github.com/sretriples/setups.git'
            }
        }
        stage('Install dependencies') {
            steps {
                sh 'npm install'
                sh 'npm install -g snyk'
            }
        }
        stage('Snyk Scan') {
            steps {
                sh 'snyk test --severity-threshold=medium --file=package.json --org=delsoncjunior --project-name=Bananada'
            }
        }
        stage('Build') {
            steps {
                echo 'Build finalizado com sucesso!'
            }
        }
    }
}
