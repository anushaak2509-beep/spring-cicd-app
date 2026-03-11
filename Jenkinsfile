pipeline {
    agent any

    // ─── CONFIGURE THESE VARIABLES ───────────────────────────────────────────
environment {
    APP_NAME       = 'webapp'
    WAR_FILE       = 'target\\webapp.war'
    TOMCAT_WEBAPPS = 'C:\\Tomcat10\\webapps'
    TOMCAT_BIN     = 'C:\\Tomcat10\\bin'
    JAVA_HOME      = 'C:\\PROGRA~1\\Java\\jdk-17'
    PATH           = "C:\\PROGRA~1\\Java\\jdk-17\\bin;C:\\apache-maven-3.9.12\\bin;${env.PATH}"
}    // ─────────────────────────────────────────────────────────────────────────

tools {
    maven 'Maven3'
    jdk   'JDK17'
}

    stages {

        stage('Checkout') {
            steps {
                echo '========== Checking out source code from GitHub =========='
                checkout scm
                echo "Branch: ${env.GIT_BRANCH}"
                echo "Commit: ${env.GIT_COMMIT}"
            }
        }

        stage('Code Info') {
            steps {
                echo '========== Build Environment Info =========='
                bat 'java -version'
                bat 'mvn -version'
            }
        }

        stage('Clean') {
            steps {
                echo '========== Cleaning previous build =========='
                bat 'mvn clean'
            }
        }

        stage('Build') {
            steps {
                echo '========== Building the Spring Boot WAR =========='
                bat 'mvn compile'
            }
        }

        stage('Test') {
            steps {
                echo '========== Running Unit Tests =========='
                bat 'mvn test'
            }
            post {
                always {
                    junit allowEmptyResults: true,
                          testResults: '**/target/surefire-reports/*.xml'
                }
                failure {
                    echo 'Tests FAILED - Deployment will not proceed!'
                }
            }
        }

        stage('Package') {
            steps {
                echo '========== Packaging WAR file =========='
                bat 'mvn package -DskipTests'
                bat 'dir target\\*.war'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.war',
                                     fingerprint: true,
                                     allowEmptyArchive: false
                }
            }
        }

        stage('Stop Tomcat') {
            steps {
                echo '========== Stopping Tomcat =========='
                bat """
                    if exist "${TOMCAT_BIN}\\shutdown.bat" (
                        call "${TOMCAT_BIN}\\shutdown.bat" || exit /b 0
                        timeout /t 5 /nobreak
                    )
                """
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                echo '========== Deploying WAR to Tomcat =========='
                bat """
                    if exist "${TOMCAT_WEBAPPS}\\${APP_NAME}" (
                        rmdir /s /q "${TOMCAT_WEBAPPS}\\${APP_NAME}"
                    )
                    if exist "${TOMCAT_WEBAPPS}\\${APP_NAME}.war" (
                        del /f "${TOMCAT_WEBAPPS}\\${APP_NAME}.war"
                    )
                    copy "${WAR_FILE}" "${TOMCAT_WEBAPPS}\\${APP_NAME}.war"
                    echo WAR deployed successfully!
                    dir "${TOMCAT_WEBAPPS}"
                """
            }
        }

        stage('Start Tomcat') {
            steps {
                echo '========== Starting Tomcat =========='
                bat """
                    start "" "${TOMCAT_BIN}\\startup.bat"
                    timeout /t 15 /nobreak
                """
            }
        }

        stage('Health Check') {
            steps {
                echo '========== Verifying Deployment =========='
                bat """
                    timeout /t 10 /nobreak
                    curl -s -o nul -w "%%{http_code}" http://localhost:8085/${APP_NAME}/
                """
            }
        }
    }

    post {
        success {
            echo '=========================================='
            echo '  PIPELINE SUCCESS!'
            echo '  App deployed to Tomcat on port 8085'
            echo '  URL: http://localhost:8085/webapp/'
            echo '=========================================='
        }
        failure {
            echo '=========================================='
            echo '  PIPELINE FAILED!'
            echo '  Check the logs above for details'
            echo '=========================================='
        }
        always {
            echo "Pipeline finished at: ${new Date()}"
            cleanWs()
        }
    }
}
