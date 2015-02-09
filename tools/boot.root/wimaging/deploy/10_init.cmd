@echo off
call ..\_config.cmd

ping -n 5 127.0.0.1 >nul
echo Loading WinPE...
wpeinit

echo Starting networking...
:testagain
ipconfig /renew
ping -n 1 %deploymentShare% > NUL
if %errorlevel% == 0 goto pingok
REM wait 3 sec. and try it again
ping -n 3 127.0.0.1 >nul
goto testagain
:pingok
for /f "delims=[] tokens=2" %%a in ('ping -4 %deploymentShare% -n 1 ^| findstr "["') do (set thisip=%%a)
echo Ping to %deploymentShare% OK! Your IP address: %thisip%


echo Downloading Setup Script
%deployRoot%\wget.vbs http://%foremanHost%/unattended/script %deployRoot%\peSetup.cmd
call %deployRoot%\peSetup.cmd