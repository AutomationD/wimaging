Create minimal updated install.wim image from scratch:
--------------------
The Idea creation of the image from scratch is that you can adapt your process to any new windows iso that you might have, which gives you flexibility with updating your image set.

# Prerequisites:
- Windows Server with Hyper-V

# Flow
- Clone the wimaging repo
- Configure wimaging
- Create boot.wim with injected storage / network drivers and foreman toolset
- Install Windows on the Hyper-V vm and sysprep it
- Create updated minimal install.wim with injected foreman toolset

# Configure wimaging
## Config.ps1
Rename .\inc\Config.ps1.sample .\inc\Config.ps1 and set some parameters before doing maintenance of your image
- $os: server-2008r2 for now. Very important to use provided options, as the directory structure uses that pattern 
- $edition: standard / enterprise / datacenter
- $boot: use if servicing boot.wim
- $wsus_offline_dir: directory where locally downloaded windows updates reside.
- $system_reserved_mount: Letter for mounting a "System reserved" partition of your vhd (pick any drive letter that is not used)
- $c_drive_mount: Letter for mounting "C: Drive" partition of your vhd (pick any drive letter that is not used)
- $hyperv_root: directory where hyper-v vms subfolders reside
- $hyperv_img_suffix="-img": a suffix, that vm name has in addition to $os ("server-2008r2-img")

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
- Run .\Add-Drivers.ps1

# Install Windows on the Hyper-V vm and sysprep it
- Download Windows VLK iso for Windows Server Enterprise 2008 R2 with SP1 (Make sure you download MAK, if you don't have a KMS server)
- Mount the iso (using Daemon Tools, for example) and copy contents to \images\server-2008r2\install\, unmount the iso from Daemon Tools
- Create a virtual machine on hyper-v with a specific name server-2008r2-img in the vm directory on one of the drives (c:\vm, d:\vm etc)
- Install OS using iso on the VM (Point your virtual DVD to the iso you downloaded, Don't worry about partitioning right now - everything will be wiped)
- Copy scripts from .\tools\install.root\ to \\server\c$
- Log in to the box via Hyper-V, enable remote desktop, disable firewall
- You can also log in using RDP, if you don't like Hyper-V console
- Copy scripts from .\tools\install.root\ to \\server\c$
- Install .net 4.0 (c:\Windows\Setup\Scripts\dotnet40-install.cmd) - Chocolatey doesn't work without it and you can't integrate it
- Install Chocolatey (c:\Windows\Setup\Scripts\chocolatey-install.cmd) - Will allow us to install everything else
- Install Windows Updates (c:\Windows\Setup\Scripts\updates-install.cmd) - Will install updates and restart your server as needed to finish all updates.
- Run Sysprep (c:\Windows\System32\sysprep\sysprep_skiprearm.cmd or c:\Windows\System32\sysprep\sysprep_rearm.cmd for not rearming) - Server will shut down.

# Create updated minimal install.wim with injected foreman toolset
It is very easy to image windows when it's on Hyper-V. Just because of native support of vhd files!
- Shut down your VM (should be shut down after your sysprep)
- Run .\CaptureWim.ps1. By default it will initialize (create) original install.wim in a .\images\<os>\work directory and merge the captured image into it.
- Run .\Update-WimTools.ps1 to add the contents of .\tools\install.root. Feel free to add your tools that you would like to be in your image.
- Run .\Push-WimInstall.ps1. It will push your working copy of install.wim to your install location (by default - .\install\<os>\sources\install.wim
- Share .\install folder via CIFS / SMB