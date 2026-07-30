<#
.SYNOPSIS
    Converts AD group scope from Domain Local to Global or Universal.
.DESCRIPTION
    Loops through groups matching a naming filter under a given OU and switches their scope. Domain Local groups cannot convert straight to Global - they must pass through Universal first.
.NOTES
    Author: Nout Geens
    Version: 1.0
#>

#Declaration
    $GroupLocation = "OU=Printing,OU=Local-Groups,DC=contoso,DC=local"
    $Groups = Get-ADGroup -SearchBase $GroupLocation -Filter {name -like "contoso-PRT-*"}

#Loop it
foreach($Group in $Groups){
    Set-ADGroup $Groupt -GroupScope Universal
    Set-ADGroup $Groupt -GroupScope Global
    }
