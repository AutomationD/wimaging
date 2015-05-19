Create minimal updated install.wim image from scratch:
--------------------
The Idea creation of the image from scratch is that you can adapt your process to any new windows iso that you might have, which gives you flexibility with updating your image set.

# Prerequisites:
- Windows box with VirtualBox on it
- Windows Assessment and Deployment Kit: ```choco install windows-adk-all```


# QuickStart
- Clone the wimaging repo: ```git clone https://github.com/kireevco/wimaging.git```
- Copy contents of your windows DVD to ```./sources/server-<version>/```
- Configure wimaging (```./inc/Config.ps1```)
- Create boot.wim with injected storage / network drivers and foreman toolset
- Create install.wim with injected storage / network drivers and foreman toolset
- Configure http / CIFS share
- Configure Foreman
- Provision a Windows host


# Configure Wimaging
## Config.ps1
Rename ```.\inc\Config.ps1.sample``` ```.\inc\Config.ps1``` and set some parameters before doing maintenance of your image
- __$os__: server-2008r2 or windows-pe-x64 (x86) or server-2012r2. Very important to use provided options, as the directory structure uses that pattern. See examples in Config.ps1
- __$edition__: _standard_ / _enterprise_ / _datacenter_
- __$boot__=_$false_. Use _$true_ if servicing boot.wim
- __$wsus_offline_dir__: directory where locally downloaded windows updates reside (for ex.: ```$wsus_offline_dir = "c:\wsusoffline\client"```)
- $system_reserved_mount: Letter for mounting a "System reserved" partition of your vhd (pick any drive letter that is not used)
- $c_drive_mount: Letter for mounting "C: Drive" partition of your vhd (pick any drive letter that is not used)

## Config.cmd
File is used during actual installation and is copied into the image as a part of the minimal toolset
Rename ```.\tools\install.root\Windows\Setup\Scripts\config.cmd.sample``` to ```config.cmd``` and set parameters:
- logfile
- deployment
- username
- password
- foremanserver
- dotnetsetupexe: DotNet4.0 installer path

## Configure http / CIFS share
We will need to share "install" directory via Windows Network Share / CIFS and (```\\wimagingHost\\install```) and expose it via http. Let's create some aliases on a webserver for our http endpoints (required for __media__ concept in Foreman):
- Point [http://wimagingHost/install/server-2012r2x64.standard](http://wimagingHost/install/server-2012r2x64.standard) to ```.\install\server-2012r2```
- Point [http://wimagingHost/install/server-2012r2x64.enterprise](http://wimagingHost/install/server-2012r2x64.enterprise) to ```.\install\server-2012r2```
- Point [http://wimagingHost/install/server-2008r2x64.standard](http://wimagingHost/install/server-2008r2x64.standard) to ```.\install\server-2008r2```
- Point [http://wimagingHost/install/server-2008r2x64.enterprise](http://wimagingHost/install/server-2008r2x64.enterprise) to ```.\install\server-2008r2```


# Create boot.wim with injected storage / network drivers and toolset
- Copy your drivers to ```.\install\drivers\```
- Copy ```c:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\en-us\winpe.wim``` to ```.\images\wimdows-pe-x64\sources\boot.wim```
- Edit ```.\inc\Config.ps1```: ```$os = "windows-pe-x64"``` and ```$boot = $true```
- Edit ```.\tools\boot.root\Windows\System32\startnet.cmd.sample``` with your data and rename it to ```startnet.cmd```
- Run ```.\Update-All.ps1``` that will inject drivers, tools and additional Windows PE Features and push it to install directory.
Your boot.wim will be available via the nework share \\deployment.domain.com\win_install\windows-pe-x64\sources\boot.wim


# Create install.wim with injected storage / network drivers, updates and toolset
This will copy required files from your Windows ISO file.
```powershell
.\Init-FromSource.ps1
```
## Windows 2012(R2)
### Get windows updates locally
- Use [WSUS Offline](http://download.wsusoffline.net/) to save updates for Windows Server 2012 R2 Locally
- Make sure to edit .\inc\Config.ps1 to set ```$wsus_offline_dir = "c:\<path_to_wsusoffline>\client"```

### Inject required tools, updates, features and drivers
We will create a wim file for a specific wim index and work on it to add all required items.

```powershell
# Initializing a working .wim file
.\Init-WorkWim.ps1

# Adding required items
.\Update-All.ps1
```
Pusing our image to .\install\ directory, where it will be available to foreman
```powershell
.\Push-Wim.ps1
```
Initialize boot tools (wimboot, etc)
```powershell
.\Init-PxeTools.ps1
```

## Windows 2008 R2
In case you are working with 2008 R2 - the process is a little bit different (because we can't inject certain updates to windows server 2008 image.
### Install Windows in VirtualBox and sysprep it
- Install virtualbox ```choco install virtualbox```
- Download Windows VLK iso for Windows Server Enterprise 2008 R2 with SP1 (Make sure you download MAK, if you don't have a KMS server)
- Mount the distribution iso (using Daemon Tools, for example) and copy contents to \images\server-2008r2\install\, unmount the iso from Daemon Tools
- Create a virtual machine in VirtualBox. Create a disk with a specific name: <os>.<edition>, use vhd format. For example server-2008r2.enterprise.vhd
- Install OS using iso on the VM (Point your virtual DVD to the iso you downloaded, Don't worry about partitioning right now - everything will be wiped)
- Shutdown the VM, add tools using Add-Tools.ps1
- Start the VM back and run in it c:\wimaging\image\10_start.cmd - this will install updates and sysprep your box. It will shut it down is well.

### Create updated minimal install.wim with injected foreman toolset
It is very easy to image windows when it's in a VirtualBox. Just because of Windows native support of vhd files!
- Shut down your VM (should be shut down after your sysprep)
- Run ```.\CaptureWim.ps1```. By default it will initialize (create) original install.wim in a ```.\images\<os>\work``` directory and merge the captured image into it.
- Run ```.\Add-Tools.ps1``` to add the contents of ```.\tools\install.root```. Feel free to add your tools that you would like to be in your image.
- Run ```.\Push-WimInstall.ps1```. It will push your working copy of install.wim to your install location (by default - ```.\install\<os>\sources\install.wim```
Your install.wim will be available via the nework share ```\\deployment.domain.com\win_install\<os>\sources\install.wim```

# Configure Foreman
- Add [wimboot](http://git.ipxe.org/releases/wimboot/wimboot-latest.zip) bootloader to your ```/tftpd/boot/``` on your PXE server.
- Add installation media ([Example](#add-installation-media)) 
- Add OS (http://foremanHost/operatingsystems) ([Example](#windows-server-2012-r2-os-config))

# Adding a new OS to wimaging:
- Create ```./sources/server-<version>/```
- Change ```.\inc\Params.ps1: Add new os handler``` to ```# Directory where the updates are located``` section. Make sure to verify WIM image names / indexes (```Windows Server 2012 R2 SERVERENTERPRISE```. Run ```.\Get-WimInfo.ps1```)
- Follow the Flow

# Examples
_Here is an example configuration for __Windows Server 2012 R2 Standard___:



## Provisioning Template (Finish)
This templates will be triggered by __wimaging__ at the end of provisioning on the machine that we will be building.
[http://<formeanHost>/config_templates](http://<formeanHost>/config_templates) -> _New Template_

- __Provisioning Template__
    - __Name__: _Windows Finish_
    - __Template Editor__:
    ```
    ```
- __Type__
    - __Snippet__: no
    -  __Type__: finish
-  __Association__
    - __Applicable OS__: Windwows 2012 R2    - 

## Provisioning Template (PXELinux)
This template will allow us to boot into a ```wimboot``` bootloader that will load our ```boot.wim``.
[http://<formeanHost>/config_templates](http://<formeanHost>/config_templates) -> _New Template_

- __Provisioning Template__
    - __Name__: _Windows PXELinux_
    - __Template Editor__:
    ```
    ```
- __Type__
    - __Snippet__: no
    -  __Type__: PXELinux
-  __Association__
    - __Applicable OS__: Windwows 2012 R2

## Provisioning Template (unattend.xml)
This template will be used when we start our setup.
[http://<formeanHost>/config_templates](http://<formeanHost>/config_templates) -> _New Template_

- __Provisioning Template__
    - __Name__: _Windows unattend.xml_
    - __Template Editor__:
    ```
    <xml>...
    ```
- __Type__
    - __Snippet__: no
    -  __Type__: provision
-  __Association__
    - __Applicable OS__: Windwows 2012 R2

## Partition Table
This partition table will create Windows Server 2008 R2 and higher compatible partition (with a _system reserved_ volume). It has 1 drive C:\ that will exand automatically and take all space on your disk.
[http://<formeanHost>/ptabes](http://<formeanHost>/ptables) -> _New Operating System_
- __Name__: _Windows 2012 R2 - C:\ Entire Disk_
- __Layout__:
```
<DiskConfiguration>
<Disk wcm:action="add">
  <CreatePartitions>
      <CreatePartition wcm:action="add">
        <Type>Primary</Type>
        <Order>1</Order>
        <Size>100</Size>
      </CreatePartition>
      <CreatePartition wcm:action="add">
        <Type>Primary</Type>
        <Order>2</Order>
        <Extend>true</Extend>
      </CreatePartition>
  </CreatePartitions>
  <ModifyPartitions>
      <ModifyPartition wcm:action="add">
        <Active>true</Active>
        <Format>NTFS</Format>
        <Label>System</Label>
        <Order>1</Order>
        <PartitionID>1</PartitionID>
      </ModifyPartition>
      <ModifyPartition wcm:action="add">
        <Format>NTFS</Format>
        <Label>SYSTEM</Label>
        <Letter>C</Letter>
        <Order>2</Order>
        <PartitionID>2</PartitionID>
      </ModifyPartition>
  </ModifyPartitions>
  <DiskID>0</DiskID>
  <WillWipeDisk>true</WillWipeDisk>
</Disk>
<WillShowUI>OnError</WillShowUI>
</DiskConfiguration>
```
- __Os family__: _Windows_

## Installation Media
[http://foremanHost/media](http://foremanHost/media) -> _New Medium_
- __Medium__
    - __Name__: _Windows Server 2012 R2 Standard_
    - __Path__: [http://wimagingHost/install/server-2012r2/server-2012r2x64.standard](http://wimagingHost/install/server-2012r2/server-2012r2x64.standard)
    - __OS Family__: _Windows_

- __Locations__
    -  _<yourLocations>_ - keep empty if you don't use locations.

## Operating System
[http://<formeanHost>/operatingsystems](http://<formeanHost>/operatingsystems) -> _New Operating System_. You have to create OS first, and then reopen it to assign Partition Table, Installation Media, etc.
- __Operating System__
    - __Name__: _windows_
    - __Major__: _6_
    - __Minor__: _3_
    - __Description__: _Windows Server 2012 R2_
    - __OS Family__: _Windows_
    - __Root PW Hash__: _MD5_
    - __Architechtures__: _x64_

- __Partition Table__
    - _Windows 2012 R2 - C:\ Entire Disk_ (defined [here](partition-table))

- __Installation Media__
    - Windows Server 2012 R2 Enterprise (defined [here](#partition-table))
- __Templates__
    - __PXELinux__: _Windows PXELinux_ (defined [here](#partition-table))
    - __finish__: _Windows Finish_ (defined [here](#partition-table))
    
# Commands Information
- ```Init-InstallSources.ps1```: Copies ISO files to wimaging.
- ```Init-WorkWim.ps1```: Initializes work .wim file from sources
- ```Update-All.ps1```: Triggers full-cycle .wim process.
- ```Backup-WorkWim.ps1```: Backs up current .wim (in case you don't want to loose your changes).
- ```Push-WimBoot.ps1```: ?Pushes current work boot.wim to install dirrectory, which makes it available over network.
- ```Unmount-VHD.ps1```: Unmounts VHD
- ```Update-BootAll.ps1```
- ```Push-Wim.ps1```: Pushes current work .wim to install dirrectory, which makes it available over network.
- ```Revert-WorkWim.ps1```: Removes current work wim and copies one from install location.
- ```Save-InstallWim.ps1```: Saves install.wim in case you want to keep a good one.
- ```MountUnmount-VHD.ps1```: Mounts VHD -> Waits for user keystroke -> Unmounts VHD (Useful for debugging)
- ```MountUnmount-Wim.ps1```: Mounts WIM -> Waits for user keystroke -> Unmounts WIM (Useful for debugging)
- ```Prepare-Image.ps1```: 
- ```Get-WimInfo.ps1```: Query information about WIM (Images, etc)
- ```Init-PxeTools.ps1```:
- ```Init-Updates.ps1```:
- ```Add-Updates.ps1```: Adds updates to current work WIM.
- ```Capture-Wim.ps1```: Captures WIM from a mounted VHD.
- ```Add-Features.ps1```: Adds features to current work WIM.
- ```Add-Tools.ps1```: Adds tools to current work WIM.
- ```Add-ToolsVHD.ps1```: Adds tools to VHD.
- ```Add-Drivers.ps1```: Adds drivers to current work WIM.
- ```Unmount-Wim.ps1```: Unmount currently mounted WIM.
- ```Get-DismFeatures.ps1```
