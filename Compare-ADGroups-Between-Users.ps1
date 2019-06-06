#Compare ad groups between two users
#v1.1
#Creator: Nout Geens

#Imports
Import-Module ActiveDirectory

#Declaration
$User1 = "*User one*"
$User2 = "*User twoo*"

#Getting the users
$User1 = Get-ADUser -filter {name -like $User1}
$User2 = Get-ADUser -filter {name -like $User2}

#Get the groups
$User1Groups = Get-ADPrincipalGroupMembership -Identity $User1.samaccountname
$User2Groups = Get-ADPrincipalGroupMembership -Identity $User2.samaccountname

#Compare the groups
$Compare = Compare-Object -ReferenceObject $User1Groups -DifferenceObject $User2Groups -PassThru |Select-Object name, Sideindicator

#Make it human Readable
foreach($comparison in $Compare){
    $comparison.SideIndicator = $comparison.SideIndicator.replace("<=",$User1.name)
    $comparison.SideIndicator = $comparison.SideIndicator.replace("=>",$User2.name)   
}

#Show it
$Compare