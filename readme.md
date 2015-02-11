## Disclamer: Work in progress
This tool is a work-in-progress project. I'm using it in production, but it could have some reduntant code or functionality, although everything should work.
If you experience any issues (or nothing works at all) - feel free to submit a ticket or catch me on #theforeman on freenode.

Create minimal updated install.wim image from scratch:
--------------------
The Idea creation of the image from scratch is that you can adapt your process to any new windows iso that you might have, which gives you flexibility with updating your image set.

# Prerequisites:
- Windows box with VirtualBox on it
- [Windows Assessment and Deployment Kit (ADK) for Windows® 8](http://www.microsoft.com/en-us/download/details.aspx?id=30652)


# Additional actions for Windows Server 2008R2 and earlier
- Install VirtualBox
- Install Windows Server via iso (2008R2 and earlier)

# Flow
- 
- Clone the wimaging repo
- Share "install" directory via Windows Network Share / CIFS
- Configure wimaging (./inc/Config.ps1)
- Copy contents of your windows DVD to ./sources/server-<version>/
- Run .\Init-FromSource.ps1 - this will copy your Windows files to proper locations
- Create boot.wim with injected storage / network drivers and foreman toolset
- Install Windows in a VirtualBox vm and sysprep it
- Create updated minimal install.wim with injected foreman toolset

# Configure wimaging
## Config.ps1
Rename .\inc\Config.ps1.sample .\inc\Config.ps1 and set some parameters before doing maintenance of your image
- $os: server-2008r2 or windows-pe-x64 (x86). Very important to use provided options, as the directory structure uses that pattern.
- $edition: standard / enterprise / datacenter
- $boot=$false. Use $true if servicing boot.wim
- $wsus_offline_dir: directory where locally downloaded windows updates reside.
- $system_reserved_mount: Letter for mounting a "System reserved" partition of your vhd (pick any drive letter that is not used)
- $c_drive_mount: Letter for mounting "C: Drive" partition of your vhd (pick any drive letter that is not used)

## config.cmd
File is used during actual installation and is copied into the image as a part of the minimal toolset
Rename .\tools\install.root\Windows\Setup\Scripts\config.cmd.sample to config.cmd and set parameters:
- logfile
- deployment
- username
- password
- foremanserver
- dotnetsetupexe: DotNet4.0 installer path 

# Create boot.wim with injected storage / network drivers and toolset
- Copy your drivers to .\install\drivers\
- Copy c:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\en-us\winpe.wim to .\images\wimdows-pe-x64\sources\boot.wim
- Edit .\inc\Config.ps1: $os = "windows-pe-x64" and $boot = $true
- Edit .\tools\boot.root\Windows\System32\startnet.cmd.sample with your data and rename it to startnet.cmd
- Run .\Update-All.ps1 that will inject drivers, tools and additional Windows PE Features and push it to install directory.
Your boot.wim will be available via the nework share \\deployment.domain.com\win_install\windows-pe-x64\sources\boot.wim

# Install Windows in VirtualBox and sysprep it
- Download Windows VLK iso for Windows Server Enterprise 2008 R2 with SP1 (Make sure you download MAK, if you don't have a KMS server)
- Mount the distribution iso (using Daemon Tools, for example) and copy contents to \images\server-2008r2\install\, unmount the iso from Daemon Tools
- Create a virtual in VirtualBox. Create a disk with a specific name: <os>.<edition>, use vhd format. For example server-2008r2.enterprise.vhd
- Install OS using iso on the VM (Point your virtual DVD to the iso you downloaded, Don't worry about partitioning right now - everything will be wiped)
- Shutdown the VM, add tools using Add-Tools.ps1
- Start the VM back and run c:\wimaging\image\10_start.cmd - this will install updates and sysprep your box. It will shut it down is well.

# Create updated minimal install.wim with injected foreman toolset
It is very easy to image windows when it's in a VirtualBox. Just because of Windows native support of vhd files!
- Shut down your VM (should be shut down after your sysprep)
- Run .\CaptureWim.ps1. By default it will initialize (create) original install.wim in a .\images\<os>\work directory and merge the captured image into it.
- Run .\Add-Tools.ps1 to add the contents of .\tools\install.root. Feel free to add your tools that you would like to be in your image.
- Run .\Push-WimInstall.ps1. It will push your working copy of install.wim to your install location (by default - .\install\<os>\sources\install.wim
Your install.wim will be available via the nework share \\deployment.domain.com\win_install\<os>\sources\install.wim
