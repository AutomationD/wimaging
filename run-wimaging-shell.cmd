@echo off

cd /d %~dp0
powershell -ExecutionPolicy remotesigned -NoExit .\Show-Menu.ps1