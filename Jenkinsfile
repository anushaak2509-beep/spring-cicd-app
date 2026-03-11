pipeline {
    agent any

    environment {
        APP_NAME       = 'webapp'
        WAR_FILE       = 'target\\webapp.war'
        TOMCAT_WEBAPPS = 'C:\\Tomcat10\\webapps'
    }

    tools {
        maven 'Maven3'
        jdk   'JDK17'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Code Info') {
            steps {
                echo '========== Build Environment Info =========='
                bat 'java -version'
                bat 'mvnw.bat -version'
            }
        }

        stage('Clean') {
            steps {
                bat 'mvnw.bat clean'
            }
        }

        stage('Build') {
            steps {
                bat 'mvnw.bat compile'
            }
        }

        stage('Test') {
            steps {
                bat 'mvnw.bat test'
            }
            post {
                always {
                    junit allowEmptyResults: true,
                          testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Package') {
            steps {
                bat 'mvnw.bat package -DskipTests'
                bat 'dir target\\*.war'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.war',
                                     fingerprint: true
                }
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                bat """
                    if exist "${TOMCAT_WEBAPPS}\\${APP_NAME}" (
                        rmdir /s /q "${TOMCAT_WEBAPPS}\\${APP_NAME}"
                    )
                    if exist "${TOMCAT_WEBAPPS}\\${APP_NAME}.war" (
                        del /f "${TOMCAT_WEBAPPS}\\${APP_NAME}.war"
                    )
                    copy "${WAR_FILE}" "${TOMCAT_WEBAPPS}\\${APP_NAME}.war"
                """
            }
        }

        stage('Health Check') {
            steps {
                bat 'curl -s -o nul -w "%%{http_code}" http://localhost:8085/webapp/'
            }
        }
    }

    post {
        success {
            echo 'PIPELINE SUCCESS! App deployed successfully.'
        }
        failure {
            echo 'PIPELINE FAILED! Check logs.'
        }
        always {
            cleanWs()
        }
    }
}