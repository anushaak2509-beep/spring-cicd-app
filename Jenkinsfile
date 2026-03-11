pipeline {
    agent any

    // ─── CONFIGURE THESE VARIABLES ───────────────────────────────────────────
    environment {
        APP_NAME        = 'webapp'
        WAR_FILE        = 'target/webapp.war'
        TOMCAT_URL      = 'http://localhost:8085'
        TOMCAT_WEBAPPS  = '/opt/tomcat/webapps'   // ← Change to your Tomcat path
        TOMCAT_BIN      = '/opt/tomcat/bin'        // ← Change to your Tomcat bin path
        JAVA_HOME       = '/usr/lib/jvm/java-17-openjdk-amd64' // ← Change if needed
    }
    // ─────────────────────────────────────────────────────────────────────────

    tools {
        maven 'Maven-3.9'   // Must match the name in Jenkins → Global Tool Configuration
        jdk   'JDK-17'      // Must match the name in Jenkins → Global Tool Configuration
    }

    stages {

        stage('📥 Checkout') {
            steps {
                echo '========== Checking out source code from GitHub =========='
                checkout scm
                echo "Branch: ${env.GIT_BRANCH}"
                echo "Commit: ${env.GIT_COMMIT}"
            }
        }

        stage('🔍 Code Info') {
            steps {
                echo '========== Build Environment Info =========='
                sh 'java -version'
                sh 'mvn -version'
                sh 'echo "Workspace: $WORKSPACE"'
            }
        }

        stage('🧹 Clean') {
            steps {
                echo '========== Cleaning previous build =========='
                sh 'mvn clean'
            }
        }

        stage('🔨 Build') {
            steps {
                echo '========== Building the Spring Boot WAR =========='
                sh 'mvn compile'
            }
        }

        stage('🧪 Test') {
            steps {
                echo '========== Running Unit Tests =========='
                sh 'mvn test'
            }
            post {
                always {
                    // Publish JUnit test results in Jenkins
                    junit allowEmptyResults: true,
                          testResults: '**/target/surefire-reports/*.xml'
                }
                failure {
                    echo '❌ Tests FAILED — Deployment will not proceed!'
                }
            }
        }

        stage('📦 Package') {
            steps {
                echo '========== Packaging WAR file =========='
                sh 'mvn package -DskipTests'
                sh 'ls -lh target/*.war'
            }
            post {
                success {
                    // Archive the WAR artifact in Jenkins
                    archiveArtifacts artifacts: 'target/*.war',
                                     fingerprint: true,
                                     allowEmptyArchive: false
                }
            }
        }

        stage('🛑 Stop Tomcat') {
            steps {
                echo '========== Stopping Tomcat =========='
                script {
                    // Gracefully stop Tomcat (ignore error if already stopped)
                    sh """
                        if [ -f ${TOMCAT_BIN}/shutdown.sh ]; then
                            ${TOMCAT_BIN}/shutdown.sh || true
                            sleep 5
                        fi
                    """
                }
            }
        }

        stage('🚀 Deploy to Tomcat') {
            steps {
                echo '========== Deploying WAR to Tomcat =========='
                script {
                    sh """
                        # Remove old deployment
                        rm -rf ${TOMCAT_WEBAPPS}/${APP_NAME}
                        rm -f  ${TOMCAT_WEBAPPS}/${APP_NAME}.war

                        # Copy new WAR
                        cp ${WAR_FILE} ${TOMCAT_WEBAPPS}/${APP_NAME}.war

                        echo "✅ WAR copied to Tomcat webapps"
                        ls -lh ${TOMCAT_WEBAPPS}/
                    """
                }
            }
        }

        stage('▶️ Start Tomcat') {
            steps {
                echo '========== Starting Tomcat =========='
                sh """
                    ${TOMCAT_BIN}/startup.sh
                    sleep 15
                """
            }
        }

        stage('✅ Health Check') {
            steps {
                echo '========== Verifying Deployment =========='
                script {
                    retry(5) {
                        sleep(time: 5, unit: 'SECONDS')
                        def response = sh(
                            script: "curl -s -o /dev/null -w '%{http_code}' ${TOMCAT_URL}/${APP_NAME}/",
                            returnStdout: true
                        ).trim()

                        if (response == '200') {
                            echo "✅ App is UP! HTTP Status: ${response}"
                            echo "🌐 URL: ${TOMCAT_URL}/${APP_NAME}/"
                        } else {
                            error("❌ Health check failed. HTTP Status: ${response}")
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo """
            ╔══════════════════════════════════════════╗
            ║  ✅ PIPELINE SUCCESS                     ║
            ║  App deployed to Tomcat on port 8085     ║
            ║  URL: http://localhost:8085/webapp/      ║
            ╚══════════════════════════════════════════╝
            """
        }
        failure {
            echo """
            ╔══════════════════════════════════════════╗
            ║  ❌ PIPELINE FAILED                      ║
            ║  Check the logs above for details        ║
            ╚══════════════════════════════════════════╝
            """
        }
        always {
            echo "Pipeline finished at: ${new Date()}"
            cleanWs()   // Clean Jenkins workspace after build
        }
    }
}
