######################################################### 
# Name: Search-GPOsForString.ps1 
# Author: Tony Murray 
# Editor: Nout Geens (modified it to be more readable in larger AD structures)
# Version: 1.2
# Date: 25-06-2020
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
        Try{
            $GPO | Add-member -NotePropertyName "PathN" -NotePropertyValue ($report.Substring($report.IndexOf("<SOMPath>")+9,$report.IndexOf("</SOMPath>") - $report.IndexOf("<SOMPath>") -9)) -Force -ErrorAction SilentlyContinue
        }Catch{  Write-host "Error in path of the GPO show below"}
        write-host -ForegroundColor "Green" "Match found in: $($GPO.DisplayName) at " $Gpo.PathN 

        $FoundSomething = $true
    }
} 
#Check if we found something
if(!$FoundSomething){ Write-Host -ForegroundColor Red "No matches found."}
