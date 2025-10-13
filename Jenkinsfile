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
                    snykInstallation: 'snyk',    // Nome configurado em "Global Tool Configuration"
                    targetFile: 'package.json',
                    severity: 'medium'
                )
            }
        }
        stage('Build') {
            steps {
                echo 'Build concluído'
            }
        }
    }
}
