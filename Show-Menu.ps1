$cnt = 1
$xMenuChoice = -1
$configs = Get-Item .\inc\*-Config.ps1

Write-Host -ForegroundColor Cyan "WIMAGING SHELL"
Write-Host -ForegroundColor Green -BackgroundColor Black "  Select a configuration to use in for wimaging session:"

foreach ($file in $configs) {
  Write-Host -ForegroundColor Yellow -NoNewLine "	[$cnt] "
  Write-Host -ForegroundColor Cyan $configs[$cnt - 1].name
  $cnt++
}

Write-Host -ForegroundColor Yellow -NoNewLine "	[0] "
Write-Host -ForegroundColor Red "Exit menu"

do { $xMenuChoice = read-host "  Please enter an option 1 to" $configs.length } 
  until ($xMenuChoice -ge 0 -and $xMenuChoice -le $configs.length)

if ($xMenuChoice -eq 0) {
  Write-Host -ForegroundColor Red "Exiting"
  Write-Host
  break
}
else {
  Copy-Item -Force -Path $configs[$xMenuChoice -1] -Destination .\inc\Config.ps1 #-Confirm
  Write-Host
  if ($?) { Write-Host -ForegroundColor Green "Ready: Using" $configs[$xMenuChoice -1].name}
  else { Write-Host -ForegroundColor Red "Error: Operation canceled!" }
  Write-Host
}