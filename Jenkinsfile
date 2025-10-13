pipeline {
    agent any

    environment {
        SNYK_TOKEN = credentials('snyk')  // ID da credencial Jenkins com o token do Snyk
    }

    stages {
        stage('Scan Docker Image with Snyk') {
            steps {
                sh '''
                    echo "Autenticando no Snyk..."
                    snyk auth $SNYK_TOKEN

                    echo "Escaneando imagem Docker com Snyk..."
                    snyk container test maven:3.9.11-eclipse-temurin-21-alpine --file=Dockerfile || true
                '''
            }
        }

        stage('Run Maven (demo)') {
            agent { docker { image 'maven:3.9.11-eclipse-temurin-21-alpine' } }
            steps {
                sh 'mvn --version'
            }
        }
    }
}
