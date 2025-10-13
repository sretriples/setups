pipeline {
    agent any
    tools {
        maven 'MAVEN'
    }
    stages {
        stage('Build Maven') {
            steps {
                checkout scm
                sh 'mvn install'
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t sretriples/setups .'
            }
        }
        stage('Scan') {
            steps {
                snykSecurity severity: 'critical', snykInstallation: 'snyk', snykTokenId: 'snyk'
                script {
                    def variable = sh (
                        script: 'snyk container test sretriples/setups --severity-threshold=critical',
                        returnStatus: true
                    )
                    echo "error code = ${variable}"
                    if (variable != 0) {
                        echo "Alert for vulnerability found"
                    }
                }
            }
        }
    }
}
