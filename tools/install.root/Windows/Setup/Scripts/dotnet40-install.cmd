@echo off
call config.cmd
echo Installing .net 4.0
start /w %dotnetsetupexe% /q /norestart /repair /log %logfile%