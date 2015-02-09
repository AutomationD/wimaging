. '.\inc\Config.ps1'
. '.\inc\Params.ps1'
. '.\inc\Functions.ps1' 
 
# Main Program

MountUnmountVHD $vhd_file $c_drive_mount $system_reserved_mount

