#Script to get outlook profiles assigned to users
#Creator: Nout Geens
#Helpfull URL: https://social.technet.microsoft.com/Forums/en-US/87573e22-eac4-4a0c-8f41-1143ff5ec979/powershell-script-to-fetch-info-of-all-outlook-accounts-in-users-machine?forum=ITCG
#Version: 1.0
<#Changelog 
  v1.0     Basic Script Created

#>

#Declaration
    $Office16Key = "hkcu:\Software\Microsoft\Office\16.0\outlook"
    $Office15Key = "hkcu:\Software\Microsoft\Office\15.0\outlook"
    $ProfileKey = "\Profiles\*\9375CFF0413111d3B88A00104B2A6676\*"
    $ExportFile = "\\srvith013\techdata$\Scripts\DUMP\ProfileExport.csv"

    $GetLoggedOnUserScript = "\\srvith013\techdata$\Scripts\Commandlets\Get-OutlookProfile.ps1"
    
    $Computer = "CXAITH105"

#import modules
    Import-Module ActiveDirectory

#Create the PSSession
    $Creds = Get-Credential
    $Session = New-PSSession -ComputerName $Computer -Credential $Creds
    
#Get the users
    
   $Users = Invoke-Command -Session $Session -ScriptBlock {hostname}  

#Check wich version of office is used, and create the propper Reg link
    if(Test-path $Office15Key){
        #Outlook 2014 & less
        $RegLink = $Office15Key + $ProfileKey
    }elseif(Test-Path $Office16Key){
        #Outlook 2016 or 365
        $RegLink = $Office16Key + $ProfileKey
    }else{
        Write-Host "No Outlook found"
    }

#Get the Regkey of the current user
    Get-ItemProperty -Path $RegLink | `
        Where-Object "Account Name" -NotLike "*Outlook Address Book*" | 
        Select-Object "Account Name"

###
#tests

$SID = Get-ADUser -Identity $User | Select-Object SID -ExpandProperty SID

