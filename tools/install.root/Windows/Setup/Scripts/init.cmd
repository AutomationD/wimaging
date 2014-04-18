@echo off
cd %WINDIR%\Setup\Scripts
call config.cmd
echo Turning off build mode
wget --output-document=NUL --no-check-certificate http://%foremanserver%/unattended/built	
echo "Deleting onBoot task"
schtasks /delete /f /tn "InitialConfigAfter"
	

