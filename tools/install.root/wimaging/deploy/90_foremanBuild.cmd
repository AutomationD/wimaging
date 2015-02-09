@echo on
cd /d %~dp0
call ..\_config.cmd
echo Turning off build mode
(%deployRoot%\wget.vbs http://%foremanHost%/unattended/built %logRoot%\foremanBuildDone )&& (echo Deleting onBoot task & schtasks /delete /f /tn "rebootOne" & rmdir %WINDIR%\Setup\ /s /q)