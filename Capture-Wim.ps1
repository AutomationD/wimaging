. '.\inc\Config.ps1'
. '.\inc\Params.ps1'
. '.\inc\Functions.ps1'
if ($boot) {
	Write-Error "Capturing boot image is not supported. Please switch to install image"
	exit 1
}

# StopVM $os

MountVHD $vhd_file $c_drive_mount $system_reserved_mount

# Back up current captured wim, so we can capture to a new one
# BackupCapturedWim $captured_wim

# Capture mounted system disk to a new wim
CaptureWim $c_drive_mount $captured_wim $wim_image_name


# Unmount VHD file
UnmountVHD $vhd_file

# Save current work file, in case there is anything valuable
# (Maybe should be commented out)
BackupWorkWim $wim_file

# Get fresh wim file from the sources
RevertWorkWim $wim_file

# Mount captured wim - we will append it to the work wim
MountWim $captured_wim $mount_dir $wim_image_name

# Delete existing image from wim file
DeleteWimImage $wim_file $wim_image_name

# Add captured image to a fresh one, so we can have one main wim for all required editions eventually
AppendWim $captured_wim $wim_file $wim_image_name

# # Unmount mount wim
# UnmountWim $mount_dir

# Now we have our work wim having captured images. 
# This is useful if you want to keep standard wim structure (indexes), and update only one or two images