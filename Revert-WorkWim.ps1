. '.\inc\Config.ps1'
. '.\inc\Params.ps1'
. '.\inc\Functions.ps1' 

# Main Program
BackupWorkWim $wim_file
RevertWorkWim $wim_file