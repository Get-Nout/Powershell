#List all titels Based AD Group
# v1.1
# Creator: Nout

#Importing modules
Import-Module ActiveDirectory

#Declaration
$Group = "Users-Subgroup"

#Get the Users
$Users = Get-ADGroupMember $Group | Select-Object SamAccountName

#Clear the screen
clear

#foreach user
ForEach ($user in $Users){ 
    #Get the title, and add it to the list
    $Titles += @(Get-ADUser -identity $user.SamAccountName -Properties title |Select-Object title -ExpandProperty title)
}

#List the Titles
$Titles| Sort-Object -Unique
