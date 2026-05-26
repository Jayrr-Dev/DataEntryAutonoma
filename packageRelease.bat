@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0packageRelease.ps1"
if errorlevel 1 exit /b 1
