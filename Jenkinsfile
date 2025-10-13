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
                    snykInstallation: 'snyk',      // Nome da instalação no Jenkins (Global Tool Configuration)
                    snykTokenId: 'snyk',           // ID da credencial (você já configurou como 'snyk')
                    targetFile: 'package.json',
                    severity: 'medium'
                )
            }
        }
        stage('Build') {
            steps {
                echo 'Build finalizado com sucesso!'
            }
        }
    }
}
