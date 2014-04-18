@echo off
call config.cmd
echo Installing updates (no .net Framework 4.5)
cinst wuinstall
wuinstall /install /logfile_append c:\wuinstall.log /disable_ie_firstruncustomize /disableprompt /reboot_if_needed /autoaccepteula /rebootcycle 3 /nomatch ".*Framework 4.5.*"