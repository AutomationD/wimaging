. '.\inc\Config.ps1'
. '.\inc\Params.ps1'
. '.\inc\Functions.ps1'
 
# Main Program

# Add Drivers

if ($os -like "windows-pe-*")
{
	# If working on 1-imaged boot.wim (winpe)	
	MountWim $wim_file $mount_dir $wim_image_name
	AddDrivers $drivers_dir $mount_dir	
	AddUpdates $update_dir $mount_dir	
	AddTools $tools_dir $mount_dir	
	# No Unmount
}
else
{
	if ($boot) {
		# If working on 2-imaged boot.wim
		Write-Host "This will update both images, including boot and install. It will atempt to go through the following:"
		
		while("y","n" -notcontains $answer)
		{
			$answer = Read-Host "AddDrivers, Add Updates, AddTools.`nContinue? (y/n)"
		}
		
		if ($answer -eq "n")
		{
			Write-Host "Cancelled."
			exit 1
		}
		
		Write-Host "Working on the boot image" -foregroundcolor "green"	
		
		#$boot = $true
		#. '.\inc\Params.ps1'
		#. '.\inc\Functions.ps1'
		
		
		MountWim $wim_file $mount_dir $wim_image_name_pe
		AddDrivers $drivers_dir $mount_dir
		UnmountWim $mount_dir
		
		MountWim $wim_file $mount_dir $wim_image_name_setup
		AddDrivers $drivers_dir $mount_dir
		AddTools $tools_dir $mount_dir
		
		# This will add additional PE packages
		AddUpdates $updates_dir $mount_dir
		UnmountWim $mount_dir
		
		
		#Write-Host "Working on the install image" -foregroundcolor "green"	
		#$boot = $false
		#. '.\inc\Params.ps1'
		#. '.\inc\Functions.ps1'
		
		
		#MountWim $wim_file $mount_dir $wim_image_name
		#AddDrivers $drivers_dir $mount_dir
		#AddUpdates $update_dir $mount_dir
		#AddTools $tools_dir $mount_dir
		# No Unmount intentionally here
	} else {
		Write-Host "This will update the image. We will attempt to go through the following:"
		
		while("y","n" -notcontains $answer)
		{
			$answer = Read-Host "AddTools, AddUpdates. `nContinue? (y/n)"
		}
		
		if ($answer -eq "n")
		{
			Write-Host "Cancelled."
			exit 1
		}
		
				
		MountWim $wim_file $mount_dir $wim_image_name
		AddTools $wim_file $mount_dir $wim_image_name
		Write-Host "Not adding any drivers. They should be injected into boot.wim as well as accessible via CIFS at \\wimagingHost\\install\drivers"
		#AddDrivers $drivers_dir $mount_dir
		AddUpdates $updates_dir $mount_dir
	}
}

# Add Updates


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
	#PushWim $wim_file
	
}



