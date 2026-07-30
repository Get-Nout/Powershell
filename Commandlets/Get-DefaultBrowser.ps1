#Declaration
$Username = "nout"
$ComputerName = "localhost"

#Imports
Import-module ActiveDirectory

#Script
$SID = (Get-ADUser $Username | Select-Object SID -ExpandProperty SID).Value

#Create The Regkeys
$Regkeys = (
    "Registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.htm\UserChoice\",
    "Registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.html\UserChoice\",
    "Registry::HKEY_USERS\$SID\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice\",
    "Registry::HKEY_USERS\$SID\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice\" 
)

#Create and fill the object
$DefaultBrowser = New-Object -TypeName PSObject

    $DefaultBrowser | Add-Member -NotePropertyName "HTM Files" -NotePropertyValue (`
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {`
            Get-ItemProperty -Path $Using:Regkeys[0] | Select-Object ProgId -ExpandProperty ProgId}) #HTM

    $DefaultBrowser | Add-Member -NotePropertyName "HTML Files" -NotePropertyValue (`
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {`
            Get-ItemProperty -Path $Using:Regkeys[1] | Select-Object ProgId -ExpandProperty ProgId}) #HTML

    $DefaultBrowser | Add-Member -NotePropertyName "Https Links" -NotePropertyValue (`
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {`
            Get-ItemProperty -Path $Using:Regkeys[2] | Select-Object ProgId -ExpandProperty ProgId}) #HTTPS

    $DefaultBrowser | Add-Member -NotePropertyName "Http Links" -NotePropertyValue (`
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {`
            Get-ItemProperty -Path $Using:Regkeys[3] | Select-Object ProgId -ExpandProperty ProgId}) #HTTP

$DefaultBrowser
