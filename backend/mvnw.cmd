@REM ----------------------------------------------------------------------------
@REM Maven Wrapper startup script (minimal Windows version)
@REM ----------------------------------------------------------------------------
@echo off
setlocal

set BASE_DIR=%~dp0
set WRAPPER_DIR=%BASE_DIR%.mvn\wrapper
set WRAPPER_JAR=%WRAPPER_DIR%\maven-wrapper.jar
set WRAPPER_PROPERTIES=%WRAPPER_DIR%\maven-wrapper.properties

if not exist "%WRAPPER_JAR%" (
    for /F "tokens=2 delims==" %%A in ('findstr /B "wrapperUrl=" "%WRAPPER_PROPERTIES%"') do set WRAPPER_URL=%%A
    echo Downloading Maven wrapper from %WRAPPER_URL% ...
    powershell -Command "Invoke-WebRequest -Uri '%WRAPPER_URL%' -OutFile '%WRAPPER_JAR%'"
)

if defined JAVA_HOME (
    set "JAVA_EXE=%JAVA_HOME%\bin\java.exe"
) else (
    set "JAVA_EXE=java"
)

"%JAVA_EXE%" -classpath "%WRAPPER_JAR%" -Dmaven.multiModuleProjectDirectory="%BASE_DIR%" org.apache.maven.wrapper.MavenWrapperMain %*
endlocal
