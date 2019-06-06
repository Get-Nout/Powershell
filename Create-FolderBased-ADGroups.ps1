#Create AD Groups based on a file structure
#Version 1.3
#Creators: Nout Geens
<#Changelog
    V1.1 Cleaned up Code
    V1.2 Changed Var names
    V1.3 Added FC groups
    V1.4 Added NTFS Additions
#>
#Imports
Import-Module activeDirectory

#Declaration
$Pre = "Cust-Share-"
$ParentFolder = "P:\DUMP\NTFSTest"
$OUPath = "OU=_temp-users,DC=nout,DC=LOCAL"
$Depth = 2

#Get the folders
$Folders = Get-ChildItem -Path $ParentFolder -Recurse -Depth $Depth

#Generate the folder names
foreach ($Folder in $Folders){
    $FullName = $Pre + $Folder
    $FCName = $FullName +"-FC"
    $RWName = $FullName +"-RW"
    $ROName = $FullName +"-RO"
    
    #region Loop every folder to Create the groups
    #Full Control groups
    Try{    Get-ADGroup $FCName| Out-Null
            Write-Host -ForegroundColor Yellow $FCName "Already Exists"}
    Catch{  
            New-ADGroup -Name $FCName -GroupCategory Security -GroupScope DomainLocal -Path $OUPath -ErrorAction SilentlyContinue
            Write-Host -ForegroundColor Green "Created AD Group:" $FCName}

    #Read-Write Groups
    Try{    Get-ADGroup $RWName| Out-Null
            Write-Host -ForegroundColor Yellow $RWName "Already Exists"}
    Catch{  
            New-ADGroup -Name $RWName -GroupCategory Security -GroupScope DomainLocal -Path $OUPath -ErrorAction SilentlyContinue
            Write-Host -ForegroundColor Green "Created AD Group:" $RWName}

    #Read groups
    Try{    Get-ADGroup $ROName | Out-Null
            Write-Host -ForegroundColor Yellow $ROName "Already Exists"}
    Catch{  
            New-ADGroup -Name $ROName -GroupCategory Security -GroupScope DomainLocal -Path $OUPath -ErrorAction SilentlyContinue
            Write-Host -ForegroundColor Green "Created AD Group:" $ROName}
    #endregion
    #>

    #Add The Groups to NTFS (making sure they exist)
    $FCGroup = Get-ADGroup -Filter { Name -like $FCName}
    $RWGroup = Get-ADGroup -Filter { Name -like $RWName}
    $ROGroup = Get-ADGroup -Filter { Name -like $ROName}

    #Get the ACL
    $ACL = Get-Acl $Folder.FullName
    $FCRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList ($FCGroup.Name,'FullControl','ContainerInherit,ObjectInherit','None','Allow')
    $RWRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList ($RWGroup.Name,'Modify','ContainerInherit,ObjectInherit','None','Allow')
    $RORule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList ($ROGroup.Name,'ListDirectory','ContainerInherit,ObjectInherit','None','Allow')
    
    #Add the rules to the ACL
    $ACL.SetAccessRuleProtection($false,$false)
    $ACL.AddAccessRule($FCRule)
    $ACL.AddAccessRule($RWRule)
    $ACL.AddAccessRule($RORule)

    $Path = $Folder | Select-Object FullName -ExpandProperty FullName
    $ACL | Set-ACL $Path

}