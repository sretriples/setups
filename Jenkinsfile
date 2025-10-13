pipeline {
    agent any

    stages {
        stage('Hello World') {
            steps {
                echo 'Hello World from Jenkins!'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build -t hello-python .'
                }
            }
        }

        stage('Run Docker Container') {
            steps {
                script {
                    sh 'docker run --rm hello-python'
                }
            }
        }

        stage('Snyk Security Scan') {
            steps {
                snykSecurity(
                    snykInstallation: 'snyk',
                    snykTokenId: 'snyk',
                    projectName: 'Bananada',
                    monitorProjectOnBuild: true,
                    failOnIssues: true
                )
            }
        }
    }
}
 
