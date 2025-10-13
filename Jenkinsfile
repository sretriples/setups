pipeline {
    agent {
        docker {
            // uso de imagem mais compatível (não “alpine” puro) pode ajudar
            image 'node:18'  
            args '-u root:root'
        }
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
            }
        }

        stage('Snyk Scan') {
            steps {
                snykSecurity(
                    organisation: 'delsoncjunior',
                    projectName: 'Bananada',
                    snykInstallation: 'snyk',   // nome da instalação Snyk configurada no Jenkins
                    snykTokenId: 'snyk',        // ID da credencial “Snyk API Token”
                    targetFile: 'package.json',
                    severity: 'medium'
                )
            }
        }

        stage('Build') {
            steps {
                echo "Build concluído (exemplo)"
            }
        }
    }
}
