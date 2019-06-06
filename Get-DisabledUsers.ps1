#List all the disabled users in ad, and check if they have mailboxes.
#v3.1
#Creator: Nout Geens

#Imports
Import-Module ActiveDirectory

#region Connect to Exchange (needed to get the shared mailboxes)
#Declaratie
	$server = "Exchange Server"
    $domain = "nout.local"
#Connectie
	$serveruri = "http://" + $server + "." + $domain +"/powershell/" #FQDN
	$exchangeSession = New-PSSession `
		-ConfigurationName Microsoft.Exchange `
		-ConnectionUri $serveruri `
		-Authentication Kerberos

	Import-PSSession $exchangeSession
#endregion

#Get the Users
    Write-host "-------------------------------"
    Write-Host "Getting the users, Please wait..."
	$DisabledUsers = Get-ADUser -Filter * -Properties * | Where-Object Enabled -eq $false |Sort-Object Name

#Reset Previous Values
    Write-Host "Resetting old values..."
    $IsShared ="";$User="";$SharedU=@();$NonSharedU=@();$PlainUsers=@();$Users = @(); $Companies = @()

#Get what we need
    $Users = $DisabledUsers | Select-Object SamAccountName, Name, whenChanged,Company


#Loop the users for: Mailboxes, Company
    Write-Host "Checking for Mailboxes & Companies..."
    foreach($User in $Users){

        #Does the mailbox Exist
        if(Get-mailbox -Identity $User.SamAccountName -ErrorAction SilentlyContinue){
            $IsShared = Get-Mailbox -Identity $User.SamAccountName | Select-Object IsShared -ExpandProperty IsShared

            if($IsShared){ #User has a shared mailbox               
                Write-Host -ForegroundColor Green -BackgroundColor Black $User.Name "is a shared Mailbox"
                $SharedU = $SharedU + $User

            }else{ #User has a regular mailbox                
                Write-Host -ForegroundColor Green -BackgroundColor Black $User.Name "has a non-shared Mailbox."
                $NonSharedU = $NonSharedU + $User
            }
                
        }else{ #User has no mailbox
            Write-Host -ForegroundColor Red -BackgroundColor Black $User.Name "Has no Mailbox"
            $PlainUsers = $PlainUsers + $User
        }

        #Check for the company
                if($user.Company){
            $Companies += $user.Company
        }else{
            $Companies += "Without A Company"
        }
    }


#Write the stats
    Write-Host "------------------------------------------"
    Write-host "There are " -NoNewline; Write-Host -ForegroundColor Yellow $DisabledUsers.Count -NoNewline; Write-Host " disabled users in your ActiveDirectory."
    Write-Host "> "-NoNewline; Write-Host -ForegroundColor Yellow $PlainUsers.count -NoNewline; Write-Host " do not have a mailbox"
    Write-Host "> "-NoNewline; Write-Host -ForegroundColor Yellow ($SharedU.count + $NonSharedU.Count) -NoNewline; Write-Host " have mailboxes"
    Write-Host " -> "-NoNewline; Write-Host -ForegroundColor Yellow $SharedU.count -NoNewline; Write-Host " are shared mailboxes"
    Write-Host " -> "-NoNewline; Write-Host -ForegroundColor Yellow $NonSharedU.count -NoNewline; Write-Host " are non shared mailboxes"

    $Companies | Group-Object |Select-Object Count, Name | Sort-Object Count -Descending |Format-Table

    Write-Host "------------------------------------------"