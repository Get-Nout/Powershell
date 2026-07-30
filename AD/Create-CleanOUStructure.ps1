<#
.SYNOPSIS
    Builds a standard OU sub-structure under a given AD Organizational Unit.
.DESCRIPTION
    Creates a fixed set of sub-OUs (Computers, Global-Groups, Local-Groups, Data, Printing, App, Servers, TS, Service-Accounts, Users, Mailbox, Disabled) under a target OU, nesting some under others per a lookup table.
.NOTES
    Author: Nout Geens
    Version: 1.2
    When adding new sub-OUs, update both $SubOUs and the Switch block.
#>

#Declaration
    $OUName =""
 
 #Generate the Dname 
    $OU_DName = Get-ADOrganizationalUnit -Filter { name -like $OUName } | Select-Object DistinguishedName -ExpandProperty DistinguishedName 
    $SubOUs = "Computers","Global-Groups","Local-Groups","Data","Printing","App","Servers","TS","Service-Accounts","Users","Mailbox","Disabled"

#Create The OUs
foreach ($SubOU in $SubOUs){
$Path =""
    #Create the subfolders, Add the Higher OU to this list when adding new ones
    Switch ($SubOU)
    {
        "Data"            {$Path = "OU=Local-Groups,"}
        "Printing"        {$Path = "OU=Local-Groups,"}
        "App"             {$Path = "OU=Local-Groups,"}
        "TS"              {$Path = "OU=Servers,"}
        "Mailbox"         {$Path = "OU=Users,"}
        "Disabled"        {$Path = "OU=Users,"}
        "Suppliers"    {$Path = "OU=Users,"}
    }
        $Path =  $Path + $OU_DName
        New-ADOrganizationalUnit -Name $SubOU -Path $Path
        Write-Host -ForegroundColor Green "Created Ou:"$SubOU "under [" $Path "]"
}
