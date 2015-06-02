. '.\inc\Config.ps1'
. '.\inc\Params.ps1'
. '.\inc\Functions.ps1' 
 
# Main Program


if ($os -like "windows-pe-*")
{
	MountWim $wim_file $mount_dir $wim_image_name
	GetFeatures($mount_dir)
	UnmountWim $mount_dir 'n'
}
else
{
	if ($boot) {
		MountWim $wim_file $mount_dir $wim_image_name_pe
		GetFeatures($mount_dir)		
		UnmountWim $mount_dir 'n'
		
		MountWim $wim_file $mount_dir $wim_image_name_setup
		GetFeatures($mount_dir)
		UnmountWim $mount_dir 'n'
	} else {
		MountWim $wim_file $mount_dir $wim_image_name
		GetFeatures($mount_dir)
		UnmountWim $mount_dir 'n'
	}
}
GetWimInfo $wim_file

