@echo off
call config.cmd
echo "Installing Chocolatey"
cmd /c powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))"

echo "Setting Chocolatey environment variables"
cmd /c "SETX /M PATH %PATH%;%systemdrive%\chocolatey\bin"