@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0runUninstallWizard.ps1"
if errorlevel 1 pause
