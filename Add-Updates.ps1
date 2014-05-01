. '.\inc\Config.ps1'
. '.\inc\Params.ps1'
. '.\inc\Functions.ps1' 
 
# Main Program
MountWim $wim_file $mount_dir $wim_image_name
AddUpdates $wim_file $update_dir $mount_dir $wim_image_name
if ($lastexitcode -ne 0)
{
	
	UnmountWim $mount_dir "n"
}
else
{
	UnmountWim $mount_dir
}
