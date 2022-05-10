#Get Outlook Profiles
#HelpfullLink: https://tinyurl.com/Get-OutlookProfile (scroll down)
#Version 1.2
#Creator: "jrv"
#Editor: Nout Geens
<#Changelog
22/10/2018    Added Comments, Made understandable, eddited it to be user based
25/10/2018    Used Different script to get the users, Created the loop foreach
#Momenteel Kapot
#> 

#Declaration
    $OfficeVersion = "15.0"
    $Computer = "CXALAMBO001"
    $ScriptLocation = "C:\Scripts\"
    $ScriptName = "Get-LoggedOnUser.ps1"
    $Exclusion = "Outlook Address Book|Outlook Data File"  
      
#Get the users
    $Script = $ScriptLocation + $ScriptName
    $Users = Invoke-Expression "$Script -computername $Computer" |Select-Object UserName -ExpandProperty UserName

#import modules
    Import-Module ActiveDirectory

#Get the users in perfect shape
    $TrueUsers  =@()
    foreach($User in $Users){   
        $TrueUsers += Get-ADUser -Identity $User | Select-Object Name,SID
    }

#Create a PSSession to the remote computer
    $Session = New-PSSession $Computer

#Go into FULL LOOPING MODE
foreach ($TrueUser in $TrueUsers){
    #Create Values 
        $Regkey = "HKU:\" + $TrueUser.SID + "\Software\Microsoft\Office\$OfficeVersion\Outlook\Profiles\*\9375CFF0413111d3B88A00104B2A6676\*"
            #the star represents the profile name.
            #9375C... is the location of the profiles,idk why

        Write-Host -for Yellow "Getting Outlook v$OfficeVersion Profiles of"$TrueUser.Name"on $Computer."

    #Throw the command    
        Invoke-Command -Session $Session -ScriptBlock{
            #To get variables into the session, we use $USING:

            #Create HKU (Only HKCU & HKLM Exist by default)
                if(Get-PSDrive -Name HKU -ErrorAction silentlyContinue){
                }else{
                    Write-Host "Creating Temporary Drive:"
                    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
                }

            #Getting the profiles
                #if the regkeys get saved as Plaintext (from v 16.0 and beyond)
                if($USING:OfficeVersion -ge 16.0){
                    Get-ItemProperty -Path $USING:Regkey | `                    Where{$_.'Account Name' -notmatch $USING:Exclusion} |`
	                Select @{n= 'ComputerName';e={$USING:Computer}},@{n= 'UserName';e={$USING:User}}, 'Account Name'
    
                #if they get saved as binary (before 16.0)
                }Else{
                    $BinaryAccountNames = Get-ItemProperty -Path $USING:Regkey | Select-Object "Account Name" -ExpandProperty "Account Name"
            
                    #List the Binary Names
                    foreach($BinaryAccountName in $BinaryAccountNames){
                        $Readable = @()
                        $chars = ""
                        $Charrr = ""

                        foreach($bin in $BinaryAccountName){
                            #Replace
                            if($bin -ne 0){ $Chars += [System.Text.Encoding]::ASCII.GetString($bin)}}
                            foreach($char in $chars){
                            $Charrr = $Charrr + $char
                            
                             $Readable = $charrr | out-string
                             $Readable = $Readable.Replace("Outlook-adresboek","")
                            Write-Host $Readable
                            }
                            }
                    }
        }
}