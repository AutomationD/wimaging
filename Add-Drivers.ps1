. '.\inc\Config.ps1'
. '.\inc\Params.ps1'
. '.\inc\Functions.ps1' 
 
# Main Program

if ($os -eq "windows-pe-x64")
{
	MountWim $wim_file $mount_dir $wim_image_name
	AddDrivers $wim_file $drivers_dir $mount_dir $wim_image_name
	UnmountWim $mount_dir
}
else
{
	MountWim $wim_file $mount_dir $wim_image_name_pe
	AddDrivers $wim_file $drivers_dir $mount_dir $wim_image_name_pe
	UnmountWim $mount_dir
	
	MountWim $wim_file $mount_dir $wim_image_name_setup
	AddDrivers $wim_file $drivers_dir $mount_dir $wim_image_name_setup
	UnmountWim $mount_dir
}


