#Export-DataGroupUsers
# V1.0 
# Creator: Nout

#region Declaratie
$Searchbase = "Users-Sharepoint"
$File = "C:\temp\SharepointRechten.csv"
$Exclude = "*Owner*"

#Stars everywhere
$SearchbaseWildcard =  "*" + $Searchbase + "*"

#Get the Groups
$Groups = Get-ADGroup -Filter { (name -like $SearchbaseWildcard) -and ( name -notlike $Exclude)}

#Foreach Group
foreach($Group in $Groups){
    #Converting the Group to non-IT readable
    $GroupName = $Group.Name
    $GroupName = $GroupName.Replace(($Searchbase+"-"),"")
    $GroupName = $GroupName.Replace("RW","Schrijf Rechten")
    $GroupName = $GroupName.Replace("RO","Lees Rechten") 
    $GroupName = $GroupName.Replace("-"," - ")
    
    #Putting it in the file (Appends)
    $GroupName | Add-Content -Path $File

    #Getting the users
    $Users = Get-ADGroupMember -Identity $Group | Select-Object SamAccountName,Name -ExpandProperty SamAccountName

    #foreach User
    foreach($User in $Users){
        #Check if they are enabled
        if(Get-ADUser -Identity $User -Properties Enabled | Select-Object Enabled -ExpandProperty Enabled){
        #Create an indent, add the username, write to file (Appends)
        "    - "+$User.Name | Add-Content -Path $File
        }
    }
    
}