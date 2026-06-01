@echo off
title Fazendo Tibia 860 - Servidor (tfs.exe; log se enableTfsConsoleLog)
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run-tfs-logged.ps1"
echo.
pause
