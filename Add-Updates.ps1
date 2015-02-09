. '.\inc\Config.ps1'
. '.\inc\Params.ps1'
. '.\inc\Functions.ps1'
 
# Main Program
MountWim $wim_file $mount_dir $wim_image_name
AddUpdates $updates_dir $mount_dir

# Write-Host "We need a second round for those updates that had dependencies"
# AddUpdates $updates_dir $mount_dir

if ($lastexitcode -ne 0)
{
	
	UnmountWim $mount_dir "n"
}
else
{
	UnmountWim $mount_dir
}

