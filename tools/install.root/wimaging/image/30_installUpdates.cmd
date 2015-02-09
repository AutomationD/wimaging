@echo off
call ..\_config.cmd

echo Enable Auto Update
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v AUOptions /t REG_DWORD /d 1 /f

echo Disable IESEC
REG ADD "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" /v IsInstalled /t REG_DWORD /d 00000000 /f

echo Install Windows Updates
Powershell.exe -executionpolicy remotesigned -File %imageRoot%\__downloadWuInstall.ps1
%utilsRoot%\wuinstall /install /logfile_append %logRoot%\wuInstall.log /disable_ie_firstruncustomize /reboot_if_needed /autoaccepteula /rebootcycle 5