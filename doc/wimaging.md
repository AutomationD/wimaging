# Getting started with wimaging
Since some testing and trial / error are involved, there is no fast track (yet). So read on!

### Tasks break down
- Set up your utility host
- Configure wimaging and copy required drivers and files
- Create the WIM images
- Sync installation folder to file server

## Wimaging project overview
Relevant folders only. All steps are covered below; just so you know your way around:

- `./foreman` - contains foreman templates
- `./images` - scratch dir for mounting images and commit stuff. Used by the scripts
- `./inc` - config files are located here. These files need to be changed
- `./install` - the final installation files. These will need to be synced to your file server later on
- `./sources` - copy installation source media here
- `./tools` - files and utilities witch are injected to the WIM files are located here

## I. Setup your "Technician Computer"
Plan on with operating systems / images you want to serve. For a list of possible
choices see `./inc/Config.ps1.sample`.
If your OS is not listed, it is quite easy do add new ones, see further below.

Gather tools, drivers and installation medias for them and continue setting up utility host

### Tasks

- Use a recent x64 windows version to play nicely with powershell. Bear in mind, i686 (is anyone still using 32bit operatingsystems?) cannot boot a x64 Windows image.
- Download and install [WAIK](http://www.microsoft.com/en-us/download/details.aspx?id=30652). You really only need the Windows PE wim; though the other tools might assist if you need to add new OSes or need to create a custom `unattend.xml`
- Download / clone this repository to a convenient location like `C:/wimaging`
- Copy contents of your windows DVD / ISO to `./sources/<osname_see_Config.ps1>/`. Also see `./install/directory.template`. If you want to keep the minimal files just copy: `sources/*.wim`; `boot/*`
- Replace `souces/boot.wim` with the winpe.wim from WAIK. Do this or each source OS.
- Use [WSUS Offline](http://download.wsusoffline.net/) to download Windows updates for your OS'es locally. For simplicity also copy it next to the wimaging directory; eg. `C:/wsusoffline`.

## II. Configure wimaging
### Config.ps1
For each OS, you'll need a Config.ps1. Since most of the variables do not change, edit `./inc/Config.ps1.sample` to your needs:
- __$os__: Very important to use provided options, as the directory structure uses that pattern.
- __$edition__: _standard_ / _enterprise_ / _datacenter_ / _Windows 8.1 Pro_. This seems only to be of importance if the WIM contains more than one image. If unsure; run `./Get-Wiminfo.ps1` later on
- __$boot__=_$false_. Use _$true_ if servicing both boot.wim and install.wim; so set it to __true__!
- __$wsus_offline_dir__: directory where locally downloaded windows updates reside (for ex.: ```$wsus_offline_dir = "c:/wsusoffline/client"```)

The VHD / VM part is important for Windows 7 / Windows 2008R2 and below since updates cannot be added offline:
- $system_reserved_mount: Letter for mounting a "System reserved" partition of your vhd (pick any drive letter that is not used)
- $c_drive_mount: Letter for mounting "C: Drive" partition of your vhd (pick any drive letter that is not used)

Now, copy `./inc/Config.ps1.sample` to `./inc/<osname>-Config.ps1`, eg `./inc/win81x64-Config.ps1`.
The prefix does not matter, make sure the file name ends with `-Config.ps1`.

### Tools
Copy `./tools/boot.root/wimaging/_config.cmd.sample` to `./tools/boot.root/wimaging/_config.cmd`.
Edit the line `foremanHost=<foreman_hostiname_or_ip>` to point to a resolvable location.
Since this is used to test networking the WinPE stage, any pingable IP will do here; though your foreman installation makes most sense.

### Adding extras, drivers and boot files
1. Create a copy of `./install/directory.template` in `./install/`. Name it after the OS name found in `Config.ps1`.
2. Repeat for each os
3. Copy drivers and extras to the respective folders. The folder structure below `drivers/` does not matter, all drivers present will be added recursively.
4. The `extra/` folder is optional. The structure in there is up to you. If you just want to sick with the provided template, download the puppet version you need and rename it `puppet.msi`.
5. Copy boot files from `./sources/<os>/boot/*` do `boot/`. These will later be download by foreman-proxy.

## III. Prepare `install.wim` and `boot.wim`
Start `./run-wimaging-shell.cmd`. From the menu, select the configuration for the session.
To show the menu again, run `./Show-Menu.ps1`.

1. Run `./Init-WorkWim.ps1`. This will copy required files from your `./sources` directory.
2. Run `./Update-All.ps1`. That will inject drivers, tools and additional Windows PE Features.
3. Run `./Push-Wim.ps1` to copy the prepared WIM files to the install path.

Alternatively, you can run each step separately with the respective commands. The most important are:
- `Add-Drivers.ps1`
- `Add-Tools.ps1`
- `Add-Updates.ps1`

## IV. Sync `./install` folder to your file server.
__Notes___: The file server must share these files via `http://` and/or `ftp://`. Test if this share is accessible. If you like, you can use the same host; for instance by stalling IIS (not covered).

## V. Configure Foreman
Head on to [configuring Foreman](foreman.md) section.


# Advanced wimaging
## Adding a new OS to wimaging:
- Create `./sources/<osname>/`
- Change `./inc/Params.ps1`: Add new os handler to ```# Directory where the updates are located``` section. Make sure to verify WIM image names / indexes eg, `Windows Server 2012 R2 SERVERENTERPRISE`.
- Run `./Get-WimInfo.ps1` to show details of the install images

## Special case: Windows 6.1 and below
In case you are working with 2008 R2 - the process is a little bit different (because we can't inject certain updates to windows server 2008 image.
### Install Windows in VirtualBox and sysprep it
- Install virtualbox ```choco install virtualbox```
- Download Windows VLK iso for Windows Server Enterprise 2008 R2 with SP1 (Make sure you download MAK, if you don't have a KMS server)
- Mount the distribution iso (using Daemon Tools, for example) and copy contents to /images/server-2008r2/install/, unmount the iso from Daemon Tools
- Create a virtual machine in VirtualBox. Create a disk with a specific name: <os>.<edition>, use vhd format. For example server-2008r2.enterprise.vhd
- Install OS using iso on the VM (Point your virtual DVD to the iso you downloaded, Don't worry about partitioning right now - everything will be wiped)
- Shutdown the VM, add tools using Add-Tools.ps1
- Start the VM back and run in it c:/wimaging/image/10_start.cmd - this will install updates and sysprep your box. It will shut it down is well.
