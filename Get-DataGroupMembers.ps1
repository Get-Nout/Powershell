#Declaration
$GroupNameFilter = "users-sharepoint-*"
$CSVPath = "C:\temp\Sharepoint Users.csv"

#Imports 
Import-module ActiveDirectory

#Get the Groups
$SPGroups = Get-ADGroup -Filter * | Where-Object name -Like $GroupNameFilter | Select-Object *


$SPGroupsU = @()
foreach($SPGroup in $SPGroups){
    #Foreach group, check if it's RW, FC or RO
    if($SPGroup.Name -like "*RW"){
        $SPGroup | Add-Member -NotePropertyName "FolderAccessRights" -NotePropertyValue "Read Write" -Force        
    }Elseif($SPGroup.name -like "*FC"){
        $SPGroup | Add-Member -NotePropertyName "FolderAccessRights" -NotePropertyValue "Full Control" -Force
    }Else{
        $SPGroup | Add-Member -NotePropertyName "FolderAccessRights" -NotePropertyValue "Read Only" -Force
    }

    #Substring the name, Substring is based on length of GroupnameFilter (-17) and another -3 for the -RW
    $FolderName = $SPGroup.Name.Substring(17,$SPGroup.Name.length -20)
    $FolderName = $FolderName.Replace("-","/")
    $SPGroup | Add-Member -NotePropertyName "FolderName" -NotePropertyValue $FolderName -Force    

    #Get the members and add it to the object, Converted to string to export to csv
    $Members = (Get-ADGroupMember -Identity $SPGroup.Name -Recursive | Select-Object Name -ExpandProperty Name) -join ', '
    $SPGroups | Add-Member -NotePropertyName "Members" -NotePropertyValue $Members -Force

    #Add the new objects to the new array
    $SPGroupsU += $SPGroup | Select-Object *
}

#List out and convert to csv
$SPGroupsU |Select-Object Name, FolderName, FolderAccessRights,Members | Export-Csv $CSVPath -Force -NoClobber -NoTypeInformation -Delimiter ";"
$SPGroupsU |Select-Object Name, FolderName, FolderAccessRights,Members | ft -auto 
