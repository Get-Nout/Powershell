######################################################### 
# Name: Search-GPOsForString.ps1 
# Author: Tony Murray 
# Editor: Nout Geens (modified it to be more readable in larger AD structures)
# Version: 1.1
# Date: 18/09/2018
# Comment: Simple search for GPOs within a domain that match a given string 
#########################################################

#Imports
Import-Module grouppolicy 

#Declaration
$String = Read-Host -Prompt "What string do you want to search for?" 
$CustomerName = Read-Host -Prompt "Provide the Customer Name"

# Set the domain to search for GPOs 
$DomainName = $env:USERDNSDOMAIN 
 
# Find GPOs in the current domain 
Write-Host "Finding all the GPOs in $DomainName" 
Write-Host "Limiting to Customer $CustomerName" 

$GPOs = Get-GPO -all -Domain $DomainName | Where-Object {$_.displayName -like "$CustomerName*" }

# Look through each GPO's XML for the string 
Write-Host "-----------------------------"
Write-Host "Starting search...." 

foreach ($GPO in $GPOs) { 
    $report = Get-GPOReport -Guid $GPO.Id -ReportType Xml 
    if ($report -match $string) { 
        write-host -ForegroundColor Green "Match found in: $($GPO.DisplayName)"
        $FoundSomething = $true
    }
} 
#Check if we found something
if(!$FoundSomething){ Write-Host -ForegroundColor Red "No matches where found."}
