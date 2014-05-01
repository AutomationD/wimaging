. '.\inc\Config.ps1'
. '.\inc\Params.ps1'
. '.\inc\Functions.ps1'
 
 
# Main Program
MountVHD $vhd_file $c_drive_mount $system_reserved_mount
#CaptureWim $c_drive_mount $captured_wim $wim_image_name
InitWorkWim $wim_file
AppendWim $c_drive_mount $captured_wim $wim_file $wim_image_name
UnmountVHD $vhd_file
#GetCapturedWim $captured_wim $wim_file