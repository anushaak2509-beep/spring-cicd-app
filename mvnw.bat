@echo off
set JAVA_HOME=C:\PROGRA~1\Java\jdk-17
set PATH=%JAVA_HOME%\bin;C:\apache-maven-3.9.12\bin;%PATH%
call C:\apache-maven-3.9.12\bin\mvn.cmd %*
