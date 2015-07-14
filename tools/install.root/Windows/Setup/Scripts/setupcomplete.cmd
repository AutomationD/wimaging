@echo off

:: Find the OS drive letter
for /f "tokens=1 delims=\" %%D in ("%WINDIR%") do SET OSDrive=%%D

set wimagingRoot=%OSDrive%\wimaging
call %wimagingRoot%\deploy\10_init.cmd
