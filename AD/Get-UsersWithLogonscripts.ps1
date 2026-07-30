<#
.SYNOPSIS
    Counts AD users in a group that have a logon script configured.
.DESCRIPTION
    Checks every member of a given AD group for a configured logon script path and reports how many enabled vs. disabled users have one set.
.NOTES
    Author: Nout Geens
    Version: 1.1
#>

#Declaration
$Groupname ="Domain Users"

#Filling in the blanks
$Group = Get-ADGroup -Filter{name -eq $Groupname } |Select-Object name -ExpandProperty name
$Users = Get-ADGroupMember $Group | Select-Object name, SamAccountName

#Reseting values to be sure
$Batcount = 0
$BatcountDisabled = 0
$Users = @()

#foreach user
foreach($User in $Users){
    #Check if they have a logon script
    if(Get-ADUser -Identity $User -properties scriptpath | Select-Object scriptpath -ExpandProperty scriptpath){
        #Check if they are enabled
        if(Get-ADUser -Identity $User | Select-Object Enabled -ExpandProperty Enabled){
            #Enabled + Logonscript
            Write-Host -ForegroundColor Yellow $User.name"has a logon script"    
            $Batcount ++
        }else{            
            #Disabled + Logonscript
            Write-Host -ForegroundColor DarkYellow $User.name"has a logon script, But is disabled"    
            $BatcountDisabled ++
        }
    }
}

#Write your findings
Write-Host -ForegroundColor Gray "------------------------------------------- "
Write-Host -ForegroundColor Yellow "---- There are"$Batcount "Active Logonscripts ---- "
Write-Host -ForegroundColor Yellow "---- There are"$BatcountDisabled "Disabled User Logonscripts ---- "
Write-Host -ForegroundColor Gray "------------------------------------------- "