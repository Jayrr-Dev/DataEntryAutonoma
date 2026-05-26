@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0runInstallWizard.ps1"
if errorlevel 1 pause
