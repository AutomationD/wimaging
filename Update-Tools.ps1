. '.\inc\Config.ps1'
. '.\inc\Params.ps1'
. '.\inc\Functions.ps1' 
 
# Main Program

# Add Drivers

if ($os -eq "windows-pe-x64")
{
	# If working on 1-imaged boot.wim (winpe)	
	MountWim $wim_file $mount_dir $wim_image_name
	
	AddTools $tools_dir $mount_dir	
	# No Unmount
}
else
{
	
	MountWim $wim_file $mount_dir $wim_image_name_setup	
	AddTools $tools_dir $mount_dir
	# No Unmount
}

# Add Updates

if ($lastexitcode -ne 0)
{
	
	UnmountWim $mount_dir "n"
	Write-Error "Wim was as not pushed"
}
else
{
	UnmountWim $mount_dir	
	PushWim $wim_file
}



