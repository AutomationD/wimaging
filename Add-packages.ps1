. '.\inc\Config.ps1'
. '.\inc\Params.ps1'
. '.\inc\Functions.ps1'
 
# Main Program

MountWim $wim_file $mount_dir $wim_image_name

Add-WindowsPackage -PackagePath:"$windows_adk_packages_path\Winpe_OCS\WinPE-WMI.cab" -Path "$mount_dir" -IgnoreCheck
Add-WindowsPackage -PackagePath:"$windows_adk_packages_path\Winpe_OCS\en-us\WinPE-WMI_en-us.cab" -Path "$mount_dir" -IgnoreCheck
Add-WindowsPackage -PackagePath:"$windows_adk_packages_path\Winpe_OCS\WinPE-NetFx.cab" -Path "$mount_dir" -IgnoreCheck
Add-WindowsPackage -PackagePath:"$windows_adk_packages_path\Winpe_OCS\en-us\WinPE-NetFx_en-us.cab" -Path "$mount_dir" -IgnoreCheck
Add-WindowsPackage -PackagePath "$windows_adk_packages_path\Winpe_OCS\WinPE-Scripting.cab" -Path "$mount_dir" -IgnoreCheck
Add-WindowsPackage -PackagePath "$windows_adk_packages_path\Winpe_OCS\en-us\WinPE-Scripting_en-us.cab" -Path "$mount_dir" -IgnoreCheck
Add-WindowsPackage -PackagePath "$windows_adk_packages_path\Winpe_OCS\WinPE-PowerShell.cab" -Path "$mount_dir" -IgnoreCheck
Add-WindowsPackage -PackagePath "$windows_adk_packages_path\Winpe_OCS\en-us\WinPE-PowerShell_en-us.cab" -Path "$mount_dir" -IgnoreCheck
Add-WindowsPackage -PackagePath "$windows_adk_packages_path\Winpe_OCS\WinPE-DismCmdlets.cab" -Path "$mount_dir" -IgnoreCheck
Add-WindowsPackage -PackagePath "$windows_adk_packages_path\Winpe_OCS\en-us\WinPE-DismCmdlets_en-us.cab" -Path "$mount_dir" -IgnoreCheck
Add-WindowsPackage -PackagePath "$windows_adk_packages_path\Winpe_OCS\WinPE-EnhancedStorage.cab" -Path "$mount_dir" -IgnoreCheck
Add-WindowsPackage -PackagePath "$windows_adk_packages_path\Winpe_OCS\en-us\WinPE-EnhancedStorage_en-us.cab" -Path "$mount_dir" -IgnoreCheck
Add-WindowsPackage -PackagePath "$windows_adk_packages_path\Winpe_OCS\WinPE-StorageWMI.cab" -Path "$mount_dir" -IgnoreCheck
Add-WindowsPackage -PackagePath "$windows_adk_packages_path\Winpe_OCS\en-us\WinPE-StorageWMI_en-us.cab" -Path "$mount_dir" -IgnoreCheck

if ($lastexitcode -ne 0)
{	
	UnmountWim $mount_dir "n"
}
else
{
	UnmountWim $mount_dir
}
