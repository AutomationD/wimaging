# Set Current Working Directory
$script_path = Split-Path -parent $MyInvocation.MyCommand.Definition
$script_path = $(Split-Path $script_path -parent)
Set-Location $script_path

if ($imagex -eq $null)
{
    $imagex = $script_path+"\tools\boot.root\utils\imagex\imagex.exe"
}

# Mount Directory
if ($mount_dir -eq $null)
{
	$mount_dir = $script_path +"\images\" + $os + "\mount"
}

if(!(Test-Path -Path ($mount_dir)))
{
	md $mount_dir
}

if ($drivers_dir -eq $null)
{
	$drivers_dir = $script_path+"\os"
}

if ($dism -eq $null)
{
	$dism = 'dism.exe'
}

# Checking if we are working on boot.wim or install.wim
if ($boot -ne $true)
{
	$tools_dir = $script_path +"\tools\install.root"
	if ($os -eq "server-2008r2")
	{		
		# Location of install.wim within windows installation "dvd" root. That's the file that the installer takes. Supposed to be exposed via a network share
        if ($wim_file_install_root -ne $nul)
		{
			$wim_file_install = $windows_install_root+"\server-2008r2x64.standard\sources\install.wim"
		}
		else
		{	
			$wim_file_install = $script_path+"\install\"+$os+"\sources\install.wim"
		}
		

        # Directory where the updates are located
		$update_dir = $wsus_offline_dir+"\w61-x64\glb"

        # Wim file that scripts process (AddTools, AddFeature, etc)
		$wim_file = $script_path + "\images\" + $os + "\work\install.wim"
        
        # VHD file for capturing images
        $vhd_file = $hyperv_root+"\"+$os+$hyperv_img_suffix+"\"+"Virtual Hard Disks\"+$os+$hyperv_img_suffix+".vhdx"
        $mount_disk = $c_drive_mount	
		
		if ($edition -eq "enterprise")
		{
			# Index of the actual image in the original install.wim
            $wim_index = 3
            
            # Image name in the original install.wim
			$wim_image_name = "Windows Server 2008 R2 SERVERENTERPRISE"
            
            # Filename for captured (from vhd) wim file
            if ($captured_wims_dir -ne $null)
            {
                $captured_wim = $captured_wims_dir+"\"+"install."+$os+"."+$edition+"."+$(Get-Date -format yyyMMddHHdd)+".wim"
            }
            else
            {
                $captured_wim = $script_path+"\"+"images"+"\"+$os+"\captured\"+$os+"."+$edition+".install."+$(Get-Date -format yyyMMddHHdd)+".wim"
            }
		}
		elseif ($edition -eq "standard")
		{
			$wim_index = 1
		}		
	}	
}
else
{
	$tools_dir = $script_path +"\tools\boot.root"
	if ($os -eq "server-2008r2")
	{		
		# Location of install.wim within windows installation "dvd" root. That's the file that the installer takes. Supposed to be exposed via a network share
        if ($wim_file_install_root -ne $nul)
		{
			$wim_file_install = $windows_install_root+"\server-2008r2x64.standard\sources\boot.wim"
		}
		else
		{	
			$wim_file_install = $script_path+"\install\"+$os+"\sources\boot.wim"
		}		

        # Wim file that scripts process (AddTools, AddFeature, etc)
		$wim_file = $script_path + "\images\" + $os + "\work\boot.wim"        
        
		$wim_image_name_pe = "Microsoft Windows PE (x64)"
		$wim_image_name_setup = "Microsoft Windows Setup (x64)"
		$wim_image_name = $wim_image_name_setup
				
	}	
}