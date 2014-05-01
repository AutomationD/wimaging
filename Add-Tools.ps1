. '.\inc\Config.ps1'
. '.\inc\Params.ps1'
. '.\inc\Functions.ps1' 

# Main Program
echo $wim_image_name
MountWim $wim_file $mount_dir $wim_image_name
AddTools $tools_dir $mount_dir
UnmountWim $mount_dir