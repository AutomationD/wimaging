:: This is a first file that we run after Windows is ready for a script stage
cd /d %~dp0
call %wimagingRoot%\_config.cmd

echo Adding credentials for %deployment%
cmdkey /add:%deployment% /user:%username% /pass:%password%

echo Downloading 20_finish.cmd
cscript.exe //NoLogo %deployRoot%\wget.vbs http://%foremanserver%/unattended/finish %deployRoot%\finish_unix.cmd

echo Converting unix eol to windows in 20_finish.cmd
cscript.exe //NoLogo %deployRoot%\unix2dos.vbs < %deployRoot%\finish_unix.cmd > %deployRoot%\20_finish.cmd

del /f %deployRoot%\finish_unix.cmd


echo Wait 15 sec before running task
ping -n 15 127.0.0.1 >nul

call %deployRoot%\20_finish.cmd | tee %logfile%

exit