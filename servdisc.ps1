# This script was initally written by q1x of github.
# I have modified it a bit by slimming down how many JSON objects are returned by the script.
# Powershell script to fetch a list of autostarted services via WMI and report back in a JSON
# formatted message that Zabbix will understand for Low Level Discovery purposes.
#


# First, fetch the list of auto started services
$colItems = Get-WmiObject Win32_Service | where-object { $_.StartMode -eq 'Auto' }

# Output the JSON header
write-host "{"
write-host " `"data`":["

# For each object in the list of services, print the output of the JSON message with the object properties that we are interessted in
foreach ($objItem in $colItems){
# Slims down serverside processing by converting state to an integer value of 1 or 0.
if ($objItem.State -eq "Running")
{$objItem.State = 1}
else
{$objItem.State = 0}
$line = "{`n`"{#SERVICESTATE}`" : `"" + $objItem.State + "`",`n`"{#SERVICENAME}`" : `"" + $objItem.Name + "`", `n},"
write-host $line

}

# Close the JSON message
write-host
write-host " ]"
write-host "}"
write-host
