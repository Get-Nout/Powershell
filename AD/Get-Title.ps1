<#
.SYNOPSIS
    Lists the distinct job titles used within an AD group.
.DESCRIPTION
    Retrieves every member of a given AD group and returns the unique set of "title" attribute values.
.NOTES
    Author: Nout Geens
    Version: 1.1
#>

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
