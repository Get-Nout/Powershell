#Setup Clean Onsite AD
#v1.2
#Creator: Nout 
#Note: Adding Folders shold be done both in $SubOus as in the Switch command

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
        "Leveranciers"    {$Path = "OU=Users,"}
    }
        $Path =  $Path + $OU_DName
        New-ADOrganizationalUnit -Name $SubOU -Path $Path
        Write-Host -ForegroundColor Green "Created Ou:"$SubOU "under [" $Path "]"
}
