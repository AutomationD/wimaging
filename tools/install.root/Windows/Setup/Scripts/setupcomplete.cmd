@echo off
call %windir%\Setup\Scripts\config.cmd

echo Adding credentials for %deployment%
cmdkey /add:%deployment% /user:%username% /pass:%password%

::echo Installing OpenSSH
::%WINDIR%\Setup\Utils\openssh_setup.exe

echo Installing wget
%WINDIR%\Setup\Utils\wget_setup.exe


echo Downloading finish.cmd
cscript.exe //NoLogo %WINDIR%\Setup\Scripts\wget.vbs http://%foremanserver%/unattended/finish c:\windows\setup\scripts\finish_unix.cmd

echo Converting unix eol to windows in finish.cmd
cscript.exe //NoLogo %WINDIR%\Setup\Scripts\unix2dos.vbs < %WINDIR%\Setup\Scripts\finish_unix.cmd > %WINDIR%\Setup\Scripts\finish.cmd

del /f %WINDIR%\Setup\Scripts\finish_unix.cmd


echo Wait 15 sec before running task
ping -n 15 127.0.0.1 >nul

call %WINDIR%\Setup\Scripts\finish.cmd | tee %logfile%


::start /wait %windir%\system32\shutdown.exe -r -t 60 -c "Windows will reboot in 60 secondes"

::cd %WINDIR%\Setup\Scripts
::call config.cmd

::disabled because of failure (probably needs extra network testing)
::logger.exe -p local0.debug -l %syslogserver% "Install: Start SetupComplete.cmd"::

::(call chocolatey-install.cmd) >> %logfile%




exit