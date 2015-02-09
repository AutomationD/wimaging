. '.\inc\Config.ps1'
. '.\inc\Params.ps1'
. '.\inc\Functions.ps1'
 
 
# Main Program

#StopVM $os

# MountVHD $vhd_file $c_drive_mount $system_reserved_mount
Write-Host "Please mount your VHD on ${c_drive_mount}"

AddTools $tools_dir "${c_drive_mount}:\"
Write-Host "Please unmount your VHD"
# UnmountVHD $vhd_file

# if ($lastexitcode -eq 0) {
#   StartVM $os  
# }