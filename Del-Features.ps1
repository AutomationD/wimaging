. '.\inc\Config.ps1'
. '.\inc\Params.ps1'
. '.\inc\Functions.ps1'
 
 
# Main Program
MountWim $wim_file $mount_dir $wim_image_name
DelFeatures $mount_dir $del_features

# Commit only on successful update
if ($lastexitcode -ne 0)
{
	Write-Host "Errors found, NOT committing any changes"
	UnmountWim $mount_dir "n"
}
else
{
	Write-Host "No errors found, committing changes"
	UnmountWim $mount_dir
	
}
