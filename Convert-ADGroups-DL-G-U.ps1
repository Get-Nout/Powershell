#Script to Switch groups from Domain local to global or universal
#Creator: Nout Geens
#Version: v1.0
<#Notes
    Straight to Global does not work, you need to pass Universal first
#>

#Declaration
    $GroupLocation = "OU=Printing,OU=Local-Groups,DC=nout,DC=local"
    $Groups = Get-ADGroup -SearchBase $GroupLocation -Filter {name -like "nout-PRT-*"}

#Loop it
foreach($Groupt in $Groupstemp){
    Set-ADGroup $Groupt -GroupScope Universal
    Set-ADGroup $Groupt -GroupScope Global
    }