# Get Every user with a logon script - Based AD Group
# V1.1
# Creator: Nout Geens

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