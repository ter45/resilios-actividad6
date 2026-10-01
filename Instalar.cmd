@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0script\windows\docker.ps1" -Action Install
set "result=%errorlevel%"
echo.
pause
exit /b %result%
