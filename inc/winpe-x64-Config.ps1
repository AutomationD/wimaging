# Operation system
# Available options:
#############################
# server-2008r2
# win7x64
# win81x64
# windows-pe-x64
# TODO: server-2012
# TODO: server-2012r2
#############################
$os = "windows-pe-x64"

# Edition
# Available options:
#############################
# OS: server-2008r2
# standard
# enterprise
# datacenter
# OS: win7x64
# homebasic
# omepremium
# professional
# ultimate
#############################
$edition = "professional"

# If managing a boot image ($true or $false)
$boot = $true

# Directory that will be used to mount wim files for processing. Default is $mount_dir = $script_path +"\" + $os + "\mount"
#$mount_dir = ""

# Directory that will be used to output captured wims (and further processing). Uses images\$os\captured by default
#$captured_wims_dir = ""
 
# Directory where windows distributions reside. Must be a directory that is served from a network share. 
#$install_root = ""

# Path to drivers directory, default .\install\drivers
#$drivers_dir = ""

# DISM Location, default 'dism.exe'
#$dism = ""

# Imagex Location
$imagex = "C:\Program Files (x86)\Windows Kits\8.1\Assessment and Deployment Kit\Deployment Tools\amd64\DISM\imagex.exe"

# Windows ADK (default:c:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit)
$windows_adk_path="C:\Program Files (x86)\Windows Kits\8.1\Assessment and Deployment Kit"

# WSUS Offline location. Must point to root that contains subfolders for distributions
$wsus_offline_dir = "C:\deploy\wsusoffline\client"

# Sytem Reserved Partition Mount Letter. Used when mounting VHD
$system_reserved_mount="R"

# Sytem Reserved Partition Mount Letter. Used when mounting VHD
$c_drive_mount="M"

# Hyper-V root location. Directory where your VM subdirectories are located
$hyperv_root="e:\vm"

# Suffix for the name for hyper-v machine that you keep for imaging
$hyperv_img_suffix="-img"

# Virtual Box Manage Utility
$vbox_manage="c:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
