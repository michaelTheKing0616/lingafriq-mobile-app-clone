@ECHO OFF
SETLOCAL

SET APP_HOME=%~dp0
SET DEFAULT_JVM_OPTS=
SET CLASSPATH=%APP_HOME%\gradle\wrapper\gradle-wrapper.jar

IF NOT DEFINED JAVA_HOME (
    SET JAVA_EXE=java
) ELSE (
    SET JAVA_EXE=%JAVA_HOME%\bin\java.exe
)

"%JAVA_EXE%" %DEFAULT_JVM_OPTS% -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*

ENDLOCAL
