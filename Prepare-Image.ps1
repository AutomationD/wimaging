. '.\inc\Config.ps1'
. '.\inc\Params.ps1'
. '.\inc\Functions.ps1'
 
 
# Main Program

# StartVM $os

PrepareImage $os


# if ($lastexitcode -eq 0) {
#   StopVM $os  
# }