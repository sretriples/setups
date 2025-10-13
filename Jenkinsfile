pipeline {
    agent any

    stages {
        stage('Hello World') {
            steps {
                echo 'Hello World!'
            }
        }

        stage('Snyk Security Scan') {
            steps {
                snykSecurity(
                    snykInstallation: 'snyk', // Nome da instalação configurada no Jenkins
                    projectName: 'Bananada', // Nome do projeto no Snyk
                    monitorProjectOnBuild: true, // Envia os resultados para o dashboard do Snyk
                    failOnIssues: true // Falha o build se houver vulnerabilidades
                )
            }
        }
    }
}
 
