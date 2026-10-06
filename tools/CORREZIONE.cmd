@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0grade-exam.ps1" %*
set EXITCODE=%ERRORLEVEL%
echo.
if not "%EXAM_CI%"=="1" pause
exit /b %EXITCODE%
