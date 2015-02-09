. '.\inc\Config.ps1'
. '.\inc\Params.ps1'
. '.\inc\Functions.ps1' 
 
# Main Program
if ($os -like "windows-pe-*")
{
	MountWim $wim_file $mount_dir $wim_image_name
	AddDrivers $drivers_dir $mount_dir
	UnmountWim $mount_dir
}
else
{
	if ($boot) {
		MountWim $wim_file $mount_dir $wim_image_name_pe
		AddDrivers $drivers_dir $mount_dir
		UnmountWim $mount_dir
		
		MountWim $wim_file $mount_dir $wim_image_name_setup
		AddDrivers $drivers_dir $mount_dir
		UnmountWim $mount_dir
	} else {
		MountWim $wim_file $mount_dir $wim_image_name
		AddDrivers $drivers_dir $mount_dir
		UnmountWim $mount_dir
	}
}


