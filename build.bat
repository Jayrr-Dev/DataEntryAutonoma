@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0compile.ps1"
if errorlevel 1 exit /b 1
