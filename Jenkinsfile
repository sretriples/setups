pipeline {
    agent {
        docker {
            image 'node:18-alpine'    // Container leve com Node.js
            args '-u root:root'       // Executar como root para evitar problemas de permissão
        }
    }
    environment {
        // SNYK_TOKEN é a credencial do Jenkins que armazena seu token do Snyk (tipo String Credential)
        SNYK_TOKEN = credentials('snyk')  
    }
    stages {
        stage('Preparation') {
            steps {
                // Clona o repositório, ajusta o branch se necessário
                git branch: 'main', url: 'https://github.com/sretriples/setups.git'
            }
        }
        stage('Install dependencies') {
            steps {
                // Instala as dependências Node.js do projeto
                sh 'npm install'
            }
        }
        stage('Snyk Scan') {
            steps {
                // Executa o scanner do plugin Snyk integrado
                snykSecurity(
                    organisation: 'delsoncjunior',
                    projectName: 'Bananada',
                    snykInstallation: 'snyk',
                    snykTokenId: '49f57c03-a496-44f0-a6dc-d2df5484784b',
                    targetFile: 'package.json',
                    severity: 'medium'
                )
            }
        }
        stage('Build') {
            steps {
                // Exemplo de build, substitua pelo seu processo real
                echo 'Executando build do projeto Node.js...'
                // sh 'npm run build'  // se tiver script build
            }
        }
    }
}
