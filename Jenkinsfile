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
                    snykInstallation: 'snyk', // Nome da instalação do plugin
                    snykTokenId: 'snyk', // ID da credencial que você criou
                    projectName: 'Bananada',
                    monitorProjectOnBuild: true,
                    failOnIssues: true
                )
            }
        }
    }
}
 
