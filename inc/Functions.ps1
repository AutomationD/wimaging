# functions
Import-Module BitsTransfer


function GetUpdates([string]$updates_dir) {
	# Invoke-Expression "& 'cinst' wuinstall -force"
	# Invoke-Expression "& 'wuinstall' /download_to $updates_dir /targetgroup /bypass_wsus /criteria 'IsInstalled=1' /disable_ie_firstruncustomize /autoaccepteula /product 'Windows Server 2008R2'"
	# Invoke-Expression "& 'wuinstall' /download_to $updates_dir /bypass_wsus /isdownloaded 0 /autoaccepteula /product 'Windows Server 2008 R2'"
}

function ExtractUpdates([string]$updates_dir) {
# 	for /R %wsusoffline%\client\w60-x64\ %%i in (*.exe) do %%i /x:%wsusoffline%\client\w60-x64\glb\exe\
# mv %wsusoffline%\client\w60-x64\glb\exe\*.cab %wsusoffline%\client\w60-x64\glb\
# for /R %wsusoffline%\client\w60-x64\ %%i in (*.msu) do expand  %%i -F:* %wsusoffline%\client\w60-x64\glb\msu\
# mv %wsusoffline%\client\w60-x64\glb\msu\*.cab %wsusoffline%\client\w60-x64\glb\
	$updatepackages = Get-ChildItem $updates_dir | where {$_.extension -eq ".exe"}
	$updates_dir_exe = "$updates_dir\exe"
	New-Item -ErrorAction Ignore -ItemType directory -Path $updates_dir_exe
	foreach ($updatepackage in $updatepackages) {
		$package_path = Join-Path $updates_dir $updatepackage.name

		Write-Host "Extracting .cab from $package_path to $updates_dir_exe"
		Invoke-Expression "& '$package_path' /x:$updates_dir_exe"
	}
	Move-Item $(Join-path $updates_dir_exe "\*.cab") $updates_dir -force

	$updatepackages = Get-ChildItem $updates_dir | where {$_.extension -eq ".msu"}
	$updates_dir_msu = "$updates_dir\msu"
	New-Item -ErrorAction Ignore -ItemType directory -Path $updates_dir_msu
	foreach ($updatepackage in $updatepackages) {
		$package_path = Join-Path $updates_dir $updatepackage.name

		
		Write-Host "Extracting .cab from $package_path to $updates_dir"
		Invoke-Expression "& 'expand' $package_path -f:* $updates_dir_msu"
	}
	Move-Item $(Join-path $updates_dir_msu "\*.cab") $updates_dir -force
}


function GetPackageNameFromFileName([string]$packageFileName){
	if ($packageFileName -match 'KB\w*') {
	    return $matches[0].toUpper()
	} else {
		return $([System.IO.Path]::GetFileNameWithoutExtension($packageFileName).toUpper())
	}
}



function GetPackageInfo([string]$packageName, [string]$fileName ) {    
    $packageInfo = @{}    
    $shell = new-object -com shell.application
    $zip = $shell.NameSpace($fileName)
    $dstTmpDir = Join-Path $(Join-Path $(Join-Path $env:TMP "wimaging") "cab") $packageName
    echo $dstTmpDir
    
    if (Test-Path $dstTmpDir) {
      # Remove-Item $dstTmpDir -Recurse -Force
    }

    foreach ($item in $zip.items()) {
      New-Item -Path "$dstTmpDir" -Type directory -ErrorAction SilentlyContinue | Out-Null
      if (!(Test-Path $(Join-Path $dstTmpDir $item.name))) {
      	if ($item.name -contains "update.mum") {        
        	$shell.NameSpace($dstTmpDir).CopyHere($item)
        }
      }
    }

    $updateMumFile = Join-Path $dstTmpDir "update.mum"
    if (Test-Path $updateMumFile) {    
      $xdoc = new-object System.Xml.XmlDocument
      Write-Host "${packageName}: Loading info"
      # $file = resolve-path($updateMumFile)
      # $xdoc.load($file)      
      #[xml] $xdoc = get-content ".\sample.xml"
      $xdoc = [xml] (get-content $updateMumFile)      
      $packageInfo.assemblyIdentityName = $xdoc.assembly.assemblyIdentity.name
      $packageInfo.assemblyIdentityVersion = $xdoc.assembly.assemblyIdentity.version
      $packageInfo.assemblyIdentityprocessorArchitecture = $xdoc.assembly.assemblyIdentity.processorArchitecture
      $packageInfo.assemblyIdentitypublicKeyToken = $xdoc.assembly.assemblyIdentity.publicKeyToken      

    } else {
      Write-Host "${packageName}: No update.mum detected" -foregroundcolor magenta
    	$packageInfo = $null
    }
    
    return $packageInfo
}

function InstallPackages([string]$updates_dir) {	
	$updates_dir = $updates_dir.toLower()
	
	$packages = @()
	Write-Host "Installing updates from $updates_dir."
	
	#Write-Host "Using dism Add-Package method on $updates_dir"
	#Invoke-Expression "& '$dism' /image:$mount_dir /Add-Package /PackagePath:$updates_dir"

	# TODO: Add xml parsing to remove bad kbs
	# Disabled until xml will be valid. Until then use windows system image manager - add Packages
	# CreateServicingUnattendXML $packages "${install}\unattend.xml"
	
	
	# $updatepackages = Get-ChildItem $updates_dir | where {$_.extension -eq ".msu" -or $_.extension -eq ".cab" }
	$updatepackages = Get-ChildItem $updates_dir | where {$_.extension -eq ".cab" -or $_.extension -eq ".msu" }
	for($i=0; $i -le $updatepackages.Count -1; $i++) {
		$packageFileName = $updatepackages[$i].name
		
		
		if ((				
			($packageFileName -notlike "*winpe-setup*") -and
			($packageFileName -notlike "*KB2506143*") -and
			($packageFileName -notlike "*KB2604521*") -and
			($packageFileName -notlike "*KB2819745*") -and
			($packageFileName -notlike "*KB2496898*") -and
			($packageFileName -notlike "*KB2533552*") -and
			($packageFileName -notlike "*KB2604521*") -and
			($packageFileName -notlike "*KB976932*") -and			
			($packageFileName -notlike "*KB3008923*") -and	
			($packageFileName -notlike "*KB3003057*") -and
			($packageFileName -notlike "*KB2726535*")
			
		) -and (
			($packageFileName -notlike "*KB2726535*")
		)) 


		 {

			$packageName = GetPackageNameFromFileName($packageFileName)
			$packagePath = "$updates_dir\$packageFileName"

			$packages += $packagePath
			
		} else {
			Write-Host "${packageName}: Skipping (excluded)"
		}
	}	
	
	$packageFilteredDir = "${updates_dir}\filtered"	
	if (!(Test-Path "$packageFilteredDir")) {
		New-Item -Path "$packageFilteredDir" -Type directory -ErrorAction SilentlyContinue | Out-Null	
	}

	Write-Host "Copying Filtered Updates"
	foreach ($package in $packages) {
		#Copy-File $package "$packageFilteredDir\"
		Invoke-Expression "& '$dism' /image:$mount_dir /Add-Package /PackagePath:$package"
	}
	
 	#Write-Host "Installing packages from $packageFilteredDir to $mount_dir"
	#Invoke-Expression "& '$dism' /image:$mount_dir /Add-Package /PackagePath:$packageFilteredDir"

	####
	# Write-Host "Using unattend.xml method to provide a list of packages with dependencies (probably doesn't work)"
	# Invoke-Expression "& '$dism' /image:$mount_dir /Apply-Unattend:${install}\unattend.xml"
	####
	#Add packages to the WIM	
	return $lastexitcode
}


function SafeUnmountWim ([string]$mount_dir) {
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
}

function Copy-File([string]$src, [string]$dst) {
	Start-BitsTransfer -Source $src -Destination $dst -Description "Copying ${src} to ${dst}" -DisplayName "File Copy"
}

function UnmountWim([string]$mount_dir, [string]$commit_yn = "y") {
	
	if ($commit_yn -ne $null) {
		$answer = $commit_yn
	} else {
		while("y","n" -notcontains $answer) {
			$answer = Read-Host "Commit? (y/n)"
		}
	}
	
	switch ($answer) {
	
	    "n" {
				Write-Host "Unmounting $mount_dir - discarding changes." -foregroundcolor magenta
				Invoke-Expression "& '$dism' /unmount-wim /mountdir:$mount_dir /discard"
			}
	    "y" {
				Write-Host "Unmounting $mount_dir - commiting changes." -foregroundcolor green
				Invoke-Expression "& '$dism' /unmount-wim /mountdir:$mount_dir /commit"
				
			}
	}
	Invoke-Expression "& '$dism' /cleanup-wim"
	
	if ($lastexitcode -ne 0) {
		Write-Error "Error ${lastexitcode}"
		exit $lastexitcode
	}
	Write-Host "Wim is not pushed yet"
}


function MountWim([string]$wim_file, [string]$mount_dir, [string]$wim_image_name) {
	#Command to mount the WIM
	Write-Host "Mounting ${wim_file} to ${mount_dir}, Image: ${wim_image_name}. Boot image: ${boot}" -foregroundcolor "Magenta"
	Invoke-Expression “& ‘$dism’ /mount-wim /wimfile:$wim_file /mountdir:$mount_dir /name:‘$wim_image_name’”	
	if ($lastexitcode -ne 0) {
		Write-Host "Error. Trying to Unmount current (no commit)" -foregroundcolor "Yellow"
		UnmountWim $mount_dir "n"
		#Write-Error "Error ${lastexitcode}"
		#exit $lastexitcode
		
	}
}

function GetWimInfo([string]$wim_file) {
	# Get Information using imagex	
	Invoke-Expression “& ‘$imagex’ /info $wim_file”	
	if ($lastexitcode -ne 0) {
		Write-Error "Error ${lastexitcode}"
		exit $lastexitcode
	}
}

function AddDrivers([string]$drivers_dir, [string]$mount_dir) {
	
	#Command to mount the WIM
	Write-Host "Adding Drivers" -foregroundcolor "yellow"
	Write-Host "${drivers_dir} -> ${mount_dir}"
	Invoke-Expression "& '$dism' /Image:$mount_dir /Add-Driver /Driver:$drivers_dir /Recurse"
	
}

function AddFeatures([string]$mount_dir) {
	if ($os -like "*-pe-*") {
		Write-Error "No features in PE version. To add PE Features use AddUpdates"
		

	} else {
		Write-Host "Installing .net 3.5"
		Invoke-Expression "& '$dism' /image:$mount_dir /Enable-Feature /FeatureName:NetFx3 /all"
	}
}


function AddUpdates([string]$updates_dir, [string]$mount_dir, [string]$wim_image_name) {
	Write-Host "Adding Updates" -foregroundcolor "yellow"
	
	if ($boot -eq $false) {
		#Array to hold package locations
		$package_path = @()
		
		if (Test-Path -PathType Container $sources\sources\sxs) {
			Write-Host "Installing .Net 3.5 from $sources"
			Invoke-Expression "& '$dism' /image:$mount_dir /Enable-Feature /FeatureName:NetFx3 /all /source:$sources\sources\sxs"
		}

		InstallPackages($updates_dir)
	} else {
		Write-Host "Processing the following packages:"
		
		<#
		Write-Host "WinPE-Scripting.cab"		
		$package_path += "/PackagePath:'${update_dir}\WinPE-Scripting.cab'"
		
		Write-Host "Adding WinPE-Setup.cab"
		$package_path += "/PackagePath:'${update_dir}\WinPE-Setup.cab'"
		
		Write-Host "WinPE-Setup-Client.cab"
		$package_path += "/PackagePath:'${update_dir}\WinPE-Setup-Client.cab'"
		
		Write-Host "WinPE-WMI.cab"
		$package_path += "/PackagePath:'${update_dir}\WinPE-WMI.cab'"
		
		Write-Host "WinPE-NetFX4.cab"
		$package_path += "/PackagePath:'${update_dir}\WinPE-NetFX4.cab'"		
		
		Write-Host "WinPE-PowerShell3.cab"
		$package_path += "/PackagePath:'${update_dir}\WinPE-PowerShell3.cab'"		 
		
		Write-Host "WinPE-DismCmdlets.cab"		
		$package_path += "/PackagePath:'${update_dir}\WinPE-DismCmdlets.cab'"
		
		Write-Host "WinPE-StorageWMI.cab"
		$package_path += "/PackagePath:'${update_dir}\WinPE-StorageWMI.cab'"		
		
		# Language-Specific Packages
		#$updatepackages = Get-ChildItem "$windows_adk_path\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us" | where{$_.extension -eq ".msu" -or $_.extension -eq ".cab" }
		#For($i=0; $i -le $updatepackages.Count -1; $i++)
		#{
		#	$package = $updatepackages[$i].name
		#	$package_path += "/PackagePath:'$windows_adk_path\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\$package'"			
		#}
		
		Write-Host "Adding PE Packages"
		Invoke-Expression "& '$dism' /image:$mount_dir /Add-Package $package_path"
		#>
		InstallPackages($updates_dir)
	}
}

function AddTools([string]$tools_dir, [string]$mount_dir) {
	Write-Host "Adding Tools" -foregroundcolor "yellow"	
	if ( $(Get-ChildItem $mount_dir | Measure-Object).count -ne 0) {
		Write-Host "Copying Tools from ${tools_dir} to ${mount_dir}"
		Copy-Item $($tools_dir+"\*") $mount_dir -Recurse -Force
	} else {
		Write-Error "${mount_dir} is empty. Didnt' mount properly?"
	}
	if ($lastexitcode -ne 0) {
		$msg = $Error[0].Exception.Message
		Write-Error "Error $msg"

		exit $lastexitcode
	}

	if (Get-Item  "${mount_dir}\Windows\Panther\Unattend.xml" -ea SilentlyContinue) {
			Write-Host "Removing unattend.xml from C:\Windows\Panther"
			Remove-Item "${mount_dir}\Windows\panther\unaddend.xml"
		}
		
		if ($lastexitcode -ne 0) {
			$msg = $Error[0].Exception.Message
			Write-Error "Error $msg"

			exit $lastexitcode
		}
	
	if ($boot -eq $true) {
		if (Get-Item  "${mount_dir}\setup.exe" -ea SilentlyContinue) {
			Write-Host "Renaming setup.exe to setupx.exe, so the setup doesn't start without required parameters"
			Rename-Item   "${mount_dir}\setup.exe"  "${mount_dir}\setupx.exe"
		}
		
		if ($lastexitcode -ne 0) {
			$msg = $Error[0].Exception.Message
			Write-Error "Error $msg"

			exit $lastexitcode
		}
	}
}

function PushWim([string]$wim_file) {		
	Write-Host "Pushing $wim_file to $wim_file_install" -foregroundcolor "green"
	Copy-Item $wim_file $wim_file_install -Force -Recurse
}

function GetCapturedWim([string]$captured_wim,[string]$wim_file) {
	Write-Host "Copying ${captured_wim} to $wim_file"
	Copy-Item $captured_wim $wim_file -force	
}

function GetFeatures([string]$mount_dir) {	
	Invoke-Expression "& ‘$dism’ /Image:$mount_dir /Get-Features /Format:Table"
	Invoke-Expression "& ‘$dism’ /Image:$mount_dir /Get-Packages /Format:Table"
}

function MountUnmountWim([string]$wim_file, [string]$mount_dir, [string]$wim_image_name) {
	
	MountWim $wim_file $mount_dir $wim_image_name
	Write-Host "Press any key to continue ..."
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	UnmountWim $mount_dir
}


function MountUnmountVHD([string]$vhd_file, [string]$c_drive_mount, [string]$system_reserved_mount) {	
	MountVHD $vhd_file $c_drive_mount $system_reserved_mount
	Write-Host "Make sure to reopen the other powershell console!"
	Write-Host "Press any key to continue ..."
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	UnmountVHD $vhd_file
}


function CaptureWim([string]$mount_disk, [string]$captured_wim, [string]$wim_image_name) {		
	Write-Host "Capturing to ${captured_wim}. Image name: ${wim_image_name}" -foregroundcolor magenta
	Invoke-Expression "& '$imagex' /capture ${mount_disk}: ${captured_wim} '${wim_image_name}'"	
	if ($lastexitcode -eq 0) {
		Write-Host "Capturing successful" -foregroundcolor green
	}
}

function DeleteWimImage([string]$wim_file, [string]$wim_image_name) {
	Write-Host "Deleting ${wim_image_name} from ${wim_file}"
	Invoke-Expression "& '$imagex' /delete '${wim_file}' '${wim_image_name}' ''"
	if ($lastexitcode -eq 0) {
		Write-Host "Deleting successful" -foregroundcolor green
	}
}

function AppendWim([string]$captured_wim, [string]$wim_file, [string]$wim_image_name) {
	Write-Host "Adding ${mount_dir}: to ${wim_file}"
	Invoke-Expression "& '$imagex' /append ${mount_dir} '${wim_file}' '${wim_image_name}' '${wim_image_name}'"
}

function BackupWorkWim([string]$wim_file) {
	$wim_file_backup = "${wim_file}_$(Get-Date -format "MMddyyyyhhmm")"
	Write-Host "Backing up ${wim_file} to ${wim_file_backup}"  
	Copy-File $wim_file $wim_file_backup
}


# Since captured wims file names have dates, it is not really used
function BackupCapturedWim([string]$captured_wim) {
	$captured_wim_file_backup = "${captured_wim}_$(Get-Date -format "MMddyyyyhhmm")"
	Write-Host "Backing up ${captured_wim} to ${captured_wim_file_backup}"  
	Copy-File $captured_wim $captured_wim_file_backup
}

function SaveWim([string]$wim_file_install) {	
	$file_name = $(Get-ChildItem $wim_file_install).Name
	$wim_file_install_save = "${save_dir}\${file_name}_save_$(Get-Date -format "MMddyyyyhhmm")"
	Write-Host "Saving current wim in install directory as working one. (${wim_file_install} -> ${wim_file_install_save})"
	#Copy-Item $wim_file_install $wim_file_install_save
	Copy-File $wim_file_install $wim_file_install_save
	# cmd /c copy /z $wim_file_install $wim_file_install_save
}

function RevertWorkWim([string]$wim_file, [string]$init_yn)
{		
	if ("y","n" -contains $init_yn) {
		$answer = $init_yn
	} else {
		while("y","n" -notcontains $answer) {
			$answer = Read-Host "This is useful when you want to reset your working wim file to your latest release version.`nRevert ${wim_file} to ${wim_file_install}? (y/n)"
		}
	}
	
	switch ($answer) {	
	    "n" {
				Write-Host "Cancelling"
				exit 1
			}
	    "y" {
				Write-Host "Reverting ${wim_file_install} to ${wim_file}."
				Write-Host "This copies back your released wim file."
				Copy-Item $wim_file_install $wim_file -force	
				
			}
	}	
}

function InitInstallSources([string]$init_yn) {	
	if ("y","n" -contains $init_yn) {
		$answer = $init_yn
	} else {
		while("y","n" -notcontains $answer)
		{
			$answer = Read-Host "This will overwrite everything in ${install}.`nReally? (y/n)"
		}
	}
	
	switch ($answer) {	
	    "n" {
				Write-Host "Cancelling"
				exit 1
			}
	    "y" {
				Write-Host "Initializing ${sources} to ${install}"
				Copy-Item $(Join-Path $sources "\*") $install -Force -Recurse
				Write-Host "Install directory for ${os} has been refreshed. Make sure to push latest images to it." -foreground "green"				
			}
	}

	# TODO: Mount boot.wim and copy pxeboot.n12 to install/$os/pxeboot.0
}

function InitPxeBoot() {

}

function InitWorkWim([string]$init_yn) {
	if ("y","n" -contains $init_yn) {
		$answer = $init_yn
	} else {
		while("y","n" -notcontains $answer)
		{
			$answer = Read-Host "This will overwrite ${wim_file} with the original ${wim_type}.wim.`nDo you really want this? (y/n)"
		}
	}
	
	switch ($answer) {	
	    "n" {
				Write-Host "Cancelling"
				exit 1
			}
	    "y" {
				if (!(Test-Path "${script_path}\images\${os}\work")) {
					New-Item -Path "${script_path}\images\${os}\work" -Type directory -ErrorAction SilentlyContinue | Out-Null	
				} else {
					Write-Host "Found ${script_path}\images\${os}\work. Moving on."
				}
				
				Write-Host "Initializing ${wim_file} from ${sources_wim_file}"
				Copy-File $sources_wim_file $wim_file -Force
				if ($lastexitcode -ne 0) {
					Write-Host "Something went wrong, maybe not clean unmount?"
					UnmountWim($mount_dir, $commit_yn = "n")
					InitWorkWim
				} else {
					Write-Host "Current working wim file has been refreshed. Make sure to push latest images to it." -foreground "green"
				}
				
			}
	}
	
	
	
	## TODO: copy winpe.wim to boot.wim
}

function GetWimBoot {
	GetZipFileContents 'http://git.ipxe.org/releases/wimboot/wimboot-latest.zip' $install @('wimboot') @('src')
}

function GetZipFileContents ([string]$url, [string]$dst_dir, [array]$includes, [array]$excludes) {
  
  $filename = $url.Substring($url.LastIndexOf("/") + 1)
  $tmp_filename=$(Join-Path $env:TEMP $filename)  
  $tmp_dst_dir = Join-Path $(split-path $tmp_filename -parent) $([io.fileinfo] $tmp_filename | % basename)
  
  New-Item -Path "$tmp_dst_dir" -Type directory -ErrorAction SilentlyContinue | Out-Null
  New-Item -Path "$dst_dir" -Type directory -ErrorAction SilentlyContinue | Out-Null
	
	Invoke-WebRequest $url -OutFile $tmp_filename
  
  
  $shell = new-object -com shell.application
  $zip = $shell.NameSpace($tmp_filename)
  
  GetZipFileItemsRecursive $zip.items()
}

function GetZipFileItemsRecursive { 
  Param([object]$items) 
 
  foreach($item In $items) { 
    if ($item.GetFolder -ne $Null) {
      if ($excludes.count -gt 0) {
        foreach($exclude in $excludes) {
          $strItem = [string]$item.Name 
          if ($strItem -ne "$exclude"){
            GetZipFileItemsRecursive $item.GetFolder.items()
          }
        }
      }
    } 


    if ($includes.count -gt 0) {
      foreach($include in $includes) {             
        $strItem = [string]$item.Name 
        if ($strItem -eq "$include") {
          if ((Test-Path ($dst_dir + "\" + $strItem)) -eq $false) { 
            Write-Host "Copied file : $strItem from zip-file: $tmp_filename to $dst_dir" 
            $shell.NameSpace($dst_dir).CopyHere($item) 
          } 
          else { 
            Write-Host "File: $strItem already exists in destination folder" 
          } 
        }
      }
    } else {        
        $shell.Namespace($dst_dir).copyhere($item)
    }

  } 
}




function MountVHD([string]$vhd_file, [string]$c_drive_mount, [string]$system_reserved_mount) {
	Write-Host "Mounting ${vhd_file} to ${c_drive_mount}" -foregroundcolor "magenta"
  if (get-item $vhd_file) {
#     $command = @"
# select vdisk file='${vhd_file}'
# attach vdisk
# select partition 1
# assign letter=${system_reserved_mount}
# select partition 2
# assign letter=${c_drive_mount}
# "@
$commands = @(
	"select vdisk file='${vhd_file}'",
	"attach vdisk",
	"select partition 1",
	"assign letter=${system_reserved_mount}",
	"select partition 2",
	"assign letter=${c_drive_mount}",
	"rescan"
	)


# $command = @"
# select vdisk file='${vhd_file}'
# 	attach vdisk
# 	select partition 1
# 	assign letter=${system_reserved_mount}
# 	select partition 2
# 	assign letter=${c_drive_mount}	
# "@
      Write-Host "Checking ${system_reserved_mount}"
      #if (($(Test-Path -Path "${system_reserved_mount}:") -eq $true))
      if (Get-PSDrive $system_reserved_mount -ea SilentlyContinue) {     
         Write-Error "Disk letter ${system_reserved_mount} is already in use. Please choose another one" -foregroundcolor red
         exit 1
      } else {
      		Write-Host "${system_reserved_mount} is available" -foregroundcolor green
          Write-Host "Testing if ${c_drive_mount} is already used"
          if (Get-PSDrive $c_drive_mount -ea SilentlyContinue) {         
            Write-Error "Disk letter ${c_drive_mount} is already in use. Please choose another one" -foregroundcolor red
            exit 1
          } else {
          	Write-Host "${c_drive_mount} is available" -foregroundcolor green		    		
            Write-Host "Mounting ${vhd_file}."            
            # ExecuteDiskPart $commands


      # Workaround for ps disk bug      
            # $old = Get-WmiObject win32_logicaldisk
            ExecuteDiskPart $commands | Out-Null
      #       $new = Get-WmiObject win32_logicaldisk
      #       $disk=(Compare-Object $old $new).InputObject
						# New-PSDrive -Name ($disk.Name)[0] -PSProvider FileSystem -Root "M"
						# dir $disk.name

      #       Write-Host "---"
      #       Compare-Object $old $new
      #       Write-Host "---"
            $t = 0 
            while (!(Get-PSDrive $c_drive_mount -ea SilentlyContinue)) {
            	start-sleep -s 1
            	$t +=1
            	if ($t -eq 3) {break}
            }
          }
        }
		Write-Host "C:\ of the mounted image is available at ${c_drive_mount}." -foregroundcolor "green"
    } else {
        exit 1
    }
}



function UnmountVHD([string]$vhd_file) {
    $command = 
@"
select vdisk file='${vhd_file}'
detach vdisk
rescan
"@

$commands = @(
	"select vdisk file='${vhd_file}'",
	"detach vdisk",
	"rescan"
	)

    Write-Host "Unmounting $vhd_file from ${c_drive_mount}."
    ExecuteDiskPart $commands
}

function ExecuteDiskPart ([string[]]$Commands)
{
	$tempFile=[System.IO.Path]::GetTempFileName()
	$output=[System.IO.Path]::GetTempFileName()
	$Commands | Out-File $tempFile -Encoding ascii
	$p= Start-Process "DiskPart.exe" -ArgumentList "/s $tempFile" -PassThru -Wait -NoNewWindow -RedirectStandardOutput $output
	Write-Debug ((gc $output) -join "`n")
	del $tempFile -Force | Out-Null
	del $output -Force | Out-Null
	$DiskPartExitCode=$p.ExitCode
	Write-Debug "DiskPart Exit Code: $DiskPartExitCode"

	return ($DiskPartExitCode -eq 0)
}


function CreateServicingUnattendXML {
    param ($packages, [string]$filePath    
)
    
    

    # Create The Document
    $XmlWriter = New-Object System.XMl.XmlTextWriter($filePath,([Text.Encoding]::Utf8))
 
    # Set The Formatting
    $xmlWriter.Formatting = "Indented"
    $xmlWriter.Indentation = "4"
 
    # Write the XML Decleration
    $xmlWriter.WriteStartDocument()
 
    # Set the XSL
    # $XSLPropText = "type='text/xsl' href='style.xsl'"
    # $xmlWriter.WriteProcessingInstruction("xml-stylesheet", $XSLPropText)    
 
    # Write Root Element
    $xmlWriter.WriteStartElement("unattend")
    $xmlWriter.WriteAttributeString("xmlns","urn:schemas-microsoft-com:unattend")
    
    # Write the Document
    $xmlWriter.WriteStartElement("servicing")

    
		foreach ($key in @($packages.keys)) {
		  $packageName = $packages[$key].name
		  $packagePath = $packages[$key].path
		  $packageInfo = $(GetPackageInfo $packageName $packagePath)

		  if ($packageInfo -eq $null) {
		  	continue
		  }

		  $packages[$key].assemblyIdentityName = $packageInfo.assemblyIdentityName
		  $packages[$key].assemblyIdentityVersion = $packageInfo.assemblyIdentityVersion
		  $packages[$key].assemblyIdentityprocessorArchitecture = $packageInfo.assemblyIdentityprocessorArchitecture
		  $packages[$key].assemblyIdentitypublicKeyToken = $packageInfo.assemblyIdentitypublicKeyToken  
		


    
      $packageKey = $key
      $packageName = $packages[$key].name
      $packagePath = $packages[$key].path
      $assemblyIdentityName = $packages[$key].assemblyIdentityName
      $assemblyIdentityVersion = $packages[$key].assemblyIdentityVersion
      $assemblyIdentityprocessorArchitecture = $packages[$key].assemblyIdentityprocessorArchitecture
      $assemblyIdentitypublicKeyToken = $packages[$key].assemblyIdentitypublicKeyToken


      if ($assemblyIdentityVersion -ne $null) {

	       # $packageName = $packages.IndexOf($package)
	      $xmlWriter.WriteStartElement("package")
		      $xmlWriter.WriteAttributeString("action","install")
		      # $xmlWriter.WriteElement("s")
		      
	      	$xmlWriter.WriteStartElement("assemblyIdentity")
			      $xmlWriter.WriteAttributeString("name","${assemblyIdentityName}")
			      $xmlWriter.WriteAttributeString("version","${assemblyIdentityVersion}")
			      $xmlWriter.WriteAttributeString("processorArchitecture","${assemblyIdentityprocessorArchitecture}")
			      $xmlWriter.WriteAttributeString("publicKeyToken","${assemblyIdentitypublicKeyToken}")
			      $xmlWriter.WriteAttributeString("language","neutral")
		      $xmlWriter.WriteEndElement()

		      $xmlWriter.WriteStartElement("source")
		      	$xmlWriter.WriteAttributeString("location",$packagePath)	      
	      	$xmlWriter.WriteEndElement()
      	$xmlWriter.WriteEndElement()
      }
    }

    $xmlWriter.WriteEndElement() # <-- Closing servicing
 
    # Write Close Tag for Root Element
    $xmlWriter.WriteEndElement() # <-- Closing RootElement
 
    # End the XML Document
    $xmlWriter.WriteEndDocument()
 
    # Finish The Document
    $xmlWriter.Finalize
    $xmlWriter.Flush()
    $xmlWriter.Close()
}


function StartVM ([string]$os) {
	Invoke-Expression "& '$vbox_manage' startvm ${os}" | out-null
	if ($lastexitcode -ne 0) {
		Write-Host "Error starting ${os}: ${lastexitcode}" -foregroundcolor red
		exit $lastexitcode
	}
}

function StopVM ([string]$os) {
	### if #$vbox_manage list runningvms|...
	# [diagnostics.process]::start("$vbox_manage","controlvm ${os} acpipowerbutton").WaitForExit()
	

	Invoke-Expression "& '$vbox_manage' controlvm ${os} acpipowerbutton" | out-null

	if ($lastexitcode -ne 0) {
		Write-Host "Can't stop gracefully, attempting hard power off"
		# [diagnostics.process]::start("$vbox_manage","controlvm ${os} poweroff").WaitForExit()
		Invoke-Expression "& '$vbox_manage' controlvm ${os} poweroff" | out-null
		if ($lastexitcode -ne 0) {
			Write-Host "Error stopping ${os}: ${lastexitcode}" -foregroundcolor red
			# exit $lastexitcode
		}		
	}
}

function PrepareImage([string]$os) {
	Write-Host "Please run c:\wimaging\image\10_start.cmd"
	# Invoke-Expression "& '$vbox_manage' guestcontrol ${os} exec --image 'c:\wimaging\image\10_start' --username ${username} --password ${password} --wait-exit --wait-stdout" | out-null	 
}

function CreateVM([string]$os) {

# 	VBoxManage createvm --name "io" --register
# VBoxManage modifyvm "io" --memory 512 --acpi on --boot1 dvd
# VBoxManage modifyvm "io" --nic1 bridged --bridgeadapter1 eth0
# VBoxManage modifyvm "io" --macaddress1 XXXXXXXXXXXX
# VBoxManage modifyvm "io" --ostype Debian

# VBoxManage createhd --filename ./io.vdi --size 10000
# VBoxManage storagectl "io" --name "IDE Controller" --add ide

# VBoxManage storageattach "io" --storagectl "IDE Controller"  \
#     --port 0 --device 0 --type hdd --medium ./io.vdi

# VBoxManage storageattach "io" --storagectl "IDE Controller" \
#     --port 1 --device 0 --type dvddrive --medium debian-6.0.2.1-i386-CD-1.iso
}

