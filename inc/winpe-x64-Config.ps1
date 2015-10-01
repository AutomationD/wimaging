# Operation system
# Available options:
#############################
# server-2008r2
# win7x64
# win81x64
# windows-pe-x64
# TODO: server-2012
# TODO: server-2012r2
#############################
$os = "windows-pe-x64"

# Edition
# Available options:
#############################
# OS: server-2008r2
# standard
# enterprise
# datacenter
# OS: win7x64
# homebasic
# omepremium
# professional
# ultimate
#############################
$edition = "professional"

# If managing a boot image ($true or $false)
$boot = $true

# Path to drivers directory, default .\install\drivers
$drivers_dir = ".\sources\${os}\drivers"
