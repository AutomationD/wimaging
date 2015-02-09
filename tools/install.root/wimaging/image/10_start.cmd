@echo off
cd /d %~dp0

call ..\_config.cmd
echo Starting preparation process. 
echo This is intened to be run on a bare Windows, to get it ready to be an image

echo Saving image date
echo Imaged %mydate%_%mytime% > %wimagingRoot%\imageDate.txt

echo Connecting to a network share
cmdkey /add:%deploymentShare% /user:%netUser% /pass:%netPassword%


:: call %imageRoot%\20_dotnet40Install.cmd
echo Installing Windows Updates.
call %imageRoot%\30_installUpdates.cmd

:: Disabled for multi-step updates
::echo After your system is done with updates run sysprep
::call %imageRoot%\99_sysprepRearm.cmd

