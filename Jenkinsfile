pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/sretriples/setups.git'
            }
        }

        stage('Install dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('Snyk Scan') {
            steps {
                snykSecurity(
                    organisation: 'delsoncjunior',
                    projectName: 'Bananada',
                    snykInstallation: 'snyk',
                    snykTokenId: 'snyk',
                    targetFile: 'package.json',
                    severity: 'medium'
                )
            }
        }

        stage('Build') {
            steps {
                echo "Build concluído com sucesso!"
            }
        }
    }
}
