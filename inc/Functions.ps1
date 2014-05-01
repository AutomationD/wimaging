# Functions
Function UnmountWim([string]$mount_dir, [string]$commit_yn = "y")
{
	
	if ($commit_yn -ne $null)
	{
		$answer = $commit_yn
	}
	else
	{
		while("y","n" -notcontains $answer)
		{
			$answer = Read-Host "Commit? (y/n)"
		}
	}
	
	switch ($answer){
	
	    "n" {
				Write-Host "Unmounting $mount_dir - discarding changes."
				Invoke-Expression "& '$dism' /unmount-wim /mountdir:$mount_dir /discard"
			}
	    "y" {
				Write-Host "Unmounting $mount_dir - commiting changes."
				Invoke-Expression "& '$dism' /unmount-wim /mountdir:$mount_dir /commit"
				
			}
	}
	Invoke-Expression "& '$dism' /cleanup-wim"
	
	if ($lastexitcode -ne 0)
	{
		Write-Error "Error ${lastexitcode}"
		exit $lastexitcode
	}
}


Function MountWim([string]$wim_file, [string]$mount_dir, [string]$wim_image_name)
{
	#Command to mount the WIM
	Write-Host "Mounting $wim_file to $mount_dir, Image ${wim_image_name}"
	Invoke-Expression “& ‘$dism’ /mount-wim /wimfile:$wim_file /mountdir:$mount_dir /name:‘$wim_image_name’”	
	if ($lastexitcode -ne 0)
	{
		Write-Error "Error ${lastexitcode}"
		exit $lastexitcode
	}
}

Function GetWimInfo([string]$wim_file)
{
	# Get Information using imagex	
	Invoke-Expression “& ‘$imagex’ /info $wim_file”	
	if ($lastexitcode -ne 0)
	{
		Write-Error "Error ${lastexitcode}"
		exit $lastexitcode
	}
}

Function AddDrivers([string]$wim_file, [string]$drivers_dir, [string]$mount_dir, [string]$wim_image_name)
{
	
	#Command to mount the WIM
	Write-Host "Adding Drivers" -foregroundcolor "yellow"
	Invoke-Expression "& '$dism' /Image:$mount_dir /Add-Driver /Driver:$drivers_dir /Recurse"
	
}

Function AddFeatures([string]$wim_file, [string]$mount_dir, [string]$wim_image_name)
{
	
	#Command to mount the WIM	
	MountWim $wim_file $mount_dir $wim_image_name
	

	
	Write-Host "Installing .net 3.5"
	Invoke-Expression "& '$dism' /image:$mount_dir /Enable-Feature /FeatureName:NetFx3"
	UnmountWim $mount_dir
}


Function AddUpdates([string]$wim_file, [string]$update_dir, [string]$mount_dir, [string]$wim_image_name)
{
	
	Write-Host "Adding Updates" -foregroundcolor "yellow"
	if ($boot -eq $false)
	{
		#Array to hold package locations
		$package_path = @()		

		#Add every update package to the $packagepagh array
		$updatepackages = Get-ChildItem $update_dir | where{$_.extension -eq ".msu" -or $_.extension -eq ".cab" }
		For($i=0; $i -le $updatepackages.Count -1; $i++)
		{
			$package = $updatepackages[$i].name
			
			if (($package -notmatch "KB2506143") -and ($package -notmatch "KB2819745") -and ($package -notmatch "KB2496898") -and ($package -notmatch "KB2533552") -and ($package -notmatch "KB2604521") -and ($package -notmatch "KB2726535"))		
			{
				$package_path += "/PackagePath:$update_dir\$package"			
			}
			else
			{
				Write-Host "Skipping .net 4.0 dependant packages"
			}
			
		}

		#Add packages to the WIM	
		Invoke-Expression "& '$dism' /image:$mount_dir /Add-Package $package_path"
		
		Write-Host "Installing .net 3.5"
		Invoke-Expression "& '$dism' /image:$mount_dir /Enable-Feature /FeatureName:NetFx3"
		

		
	}
	else
	{
		$package_path = @()
		
		# Base Packages
		$updatepackages = Get-ChildItem "$windows_adk_path\Windows Preinstallation Environment\amd64\WinPE_OCs\" | where{$_.extension -eq ".msu" -or $_.extension -eq ".cab" }
			
		$package_path += "/PackagePath:'$windows_adk_path\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-Scripting.cab'"
		$package_path += "/PackagePath:'$windows_adk_path\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-Setup.cab'"
		$package_path += "/PackagePath:'$windows_adk_path\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-Setup-Client.cab'"
		$package_path += "/PackagePath:'$windows_adk_path\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-WMI.cab'"
		$package_path += "/PackagePath:'$windows_adk_path\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-NetFX4.cab'"		
		$package_path += "/PackagePath:'$windows_adk_path\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-PowerShell3.cab'"		 
		$package_path += "/PackagePath:'$windows_adk_path\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-DismCmdlets.cab'"
		$package_path += "/PackagePath:'$windows_adk_path\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-StorageWMI.cab'"		
		
		
		
			
		
		
		# Language-Specific Packages
		#$updatepackages = Get-ChildItem "$windows_adk_path\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us" | where{$_.extension -eq ".msu" -or $_.extension -eq ".cab" }
		#For($i=0; $i -le $updatepackages.Count -1; $i++)
		#{
		#	$package = $updatepackages[$i].name
		#	$package_path += "/PackagePath:'$windows_adk_path\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\$package'"			
		#}
		
		Write-Host "Adding PE Packages"
		Invoke-Expression "& '$dism' /image:$mount_dir /Add-Package $package_path"
		
		
	}
}

Function AddTools([string]$tools_dir, [string]$mount_dir)
{
	Write-Host "Adding Tools" -foregroundcolor "yellow"	
	if ( $(Get-ChildItem $mount_dir | Measure-Object).count -ne 0)
	{
		Write-Host "Copying Tools"
		Copy-Item $($tools_dir+"\*") $mount_dir -Recurse -Force
	}
	else
	{
		Write-Error "${mount_dir} is empty. Didnt' mount properly?"
	}
	if ($lastexitcode -ne 0)
	{
		Write-Error "Error ${lastexitcode}"
		exit $lastexitcode
	}
	
	if (Get-Item  "${mount_dir}\Windows\Panther\Unattend.xml" -ea SilentlyContinue)
		{
			Write-Host "Removing unattend.xml from C:\Windows\Panther"
			Remove-Item "${mount_dir}\Windows\panther\unaddend.xml"
		}
		
		if ($lastexitcode -ne 0)
		{
			Write-Error "Error ${lastexitcode}"
			exit $lastexitcode
		}
	
	if ($boot -eq $true)
	{
		if (Get-Item  "${mount_dir}\setup.exe" -ea SilentlyContinue)
		{
			Write-Host "Renaming setup.exe to setupx.exe, so the setup doesn't start without required parameters"
			Rename-Item   "${mount_dir}\setup.exe"  "${mount_dir}\setupx.exe"
		}
		
		if ($lastexitcode -ne 0)
		{
			Write-Error "Error ${lastexitcode}"
			exit $lastexitcode
		}
		
		
	}
}

Function PushWim([string]$wim_file)
{		
	Write-Host "Pushing $wim_file to $wim_file_install" -foregroundcolor "green"
	Copy-Item $wim_file $wim_file_install -force -recurse
}

Function GetCapturedWim([string]$captured_wim,[string]$wim_file)
{
	Write-Host "Copying ${captured_wim} to $wim_file"
	Copy-Item $captured_wim $wim_file -force	
}

Function GetFeatures([string]$wim_file, [string]$mount_dir, [int]$wim_image_name)
{
	
	MountWim $wim_file $mount_dir $wim_image_name
	
	Invoke-Expression "& ‘$dism’ /Image:$mount_dir /Get-Features /Format:Table"
	Invoke-Expression "& ‘$dism’ /Image:$mount_dir /Get-Packages /Format:Table"
	UnmountWim $mount_dir "n"
	
}
Function AttachDetach([string]$wim_file, [string]$mount_dir, [string]$wim_image_name)
{
	MountWim $wim_file $mount_dir $wim_image_name
	Write-Host "Press any key to continue ..."
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	UnmountWim $mount_dir
}


Function CaptureWim([string]$mount_disk, [string]$captured_wim, [string]$wim_image_name)
{		
	Write-Host "Capturing to ${wim_image_name}"
	Invoke-Expression "& '$imagex' /capture ${mount_disk}: ${captured_wim} '${wim_image_name}'"	
}

Function AppendWim([string]$mount_disk, [string]$captured_wim, [string]$wim_file, [string]$wim_image_name)
{	
	Write-Host "Deleting ${wim_image_name} from ${wim_file}"
	Invoke-Expression "& '$imagex' /delete '${wim_file}' '${wim_image_name}'"
	
	Write-Host "Appending ${mount_disk}: to ${wim_file}"
	Invoke-Expression "& '$imagex' /append ${mount_disk}: '${wim_file}' '${wim_image_name}' '${wim_image_name}'"
}

Function InitWorkWim([string]$wim_file, [string]$init_yn = 'y')
{	
	if ($init_yn -ne $null)
	{
		$answer = $init_yn
	}
	else
	{
		while("y","n" -notcontains $answer)
		{
			$answer = Read-Host "Commit? (y/n)"
		}
	}
	
	switch ($answer){
	
	    "n" {
				Write-Host "Cancelling"
				exit 1
			}
	    "y" {
				Write-Host "Initializing ${wim_file_install} to ${wim_file}"
				Copy-Item $wim_file_install $wim_file -force	
				
			}
	}
	
	## TODO: copy winpe.wim to boot.wim
}


Function MountVHD([string]$vhd_file, [string]$c_drive_mount, [string]$system_reserved_mount)
{		

    if (get-item $vhd_file)
    {
        $command = @"
select vdisk file='${vhd_file}'
attach vdisk
select partition 1
assign letter=${system_reserved_mount}
select partition 2
assign letter=${c_drive_mount}
"@

      Write-Host "Testing if ${system_reserved_mount} is already used"
      #if (($(Test-Path -Path "${system_reserved_mount}:") -eq $true))
      if (Get-PSDrive $system_reserved_mount -ea SilentlyContinue)
      {
     
         Write-Error "Disk letter ${system_reserved_mount} is already in use. Please choose another one"
         exit 1
      }
      else
      {
          Write-Host "Testing if ${c_drive_mount} is already used"
          if (Get-PSDrive $c_drive_mount -ea SilentlyContinue)
          {         
            Write-Error "Disk letter ${c_drive_mount} is already in use. Please choose another one"
            exit 1
          }
          else
          {
		    Write-Host "All drives are available."
            Write-Host "Mounting ${vhd_file}. Your system is located on ${c_drive_mount}."
            $command | diskpart
          }
        }
    }
    else
    {
        exit 1
    }
}


Function UnmountVHD([string]$vhd_file)
{
    $command = @"
select vdisk file='${vhd_file}'
detach vdisk
"@
    Write-Host "Unmounting $vhd_file from ${c_drive_mount}."
    $command | diskpart     
}




