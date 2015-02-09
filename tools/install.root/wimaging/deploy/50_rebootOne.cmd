@echo on
cd /d %~dp0
call ..\_config.cmd

echo Performing actions on reboot One

call %deployRoot%\90_foremanBuild.cmd
