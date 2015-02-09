. '.\inc\Config.ps1'
. '.\inc\Params.ps1'
. '.\inc\Functions.ps1' 
 
 Write-Host "$os $wim_image_name"
# Main Program
if ($boot -eq $true) {
	if ($os -like "*-pe-*") {		
		MountUnmountWim $wim_file $mount_dir $wim_image_name
	} else {
		MountUnmountWim $wim_file $mount_dir $wim_image_name_pe
		MountUnmountWim $wim_file $mount_dir $wim_image_name_setup
	}	
} else {	
	MountUnmountWim $wim_file $mount_dir $wim_image_name
}