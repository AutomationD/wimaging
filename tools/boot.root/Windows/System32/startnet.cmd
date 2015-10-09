@echo off
:: this script is called automatically by winPE.
:: See also: https://technet.microsoft.com/en-us/library/hh825191.aspx
set wimagingRoot=x:\wimaging
cd /d %wimagingRoot%\deploy
call 10_init.cmd
