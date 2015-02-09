. '.\inc\Config.ps1'
. '.\inc\Params.ps1'
. '.\inc\Functions.ps1' 
 
# Main Program
MountWim $wim_file $mount_dir $wim_image_name
AddTools $tools_dir $mount_dir


# Commit only on successful update
if ($lastexitcode -ne 0)
{
	Write-Host "Errors found, NOT committing any changes"
	UnmountWim $mount_dir "n"
	Write-Error "Wim was as not pushed"
}
else
{
	Write-Host "No errors found, committing changes"
	UnmountWim $mount_dir
}

