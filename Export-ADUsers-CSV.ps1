#Export-ADUsers-CSV
#v1.0
#Creator: Nout Geens

function Export-ADUsers-CSV{

    Param(
        [Parameter()]
        [String]$Group,
        [Parameter()]
        [String]$OU,
        [Parameter()]
        [String]$File = "C:\temp\ADUsers.csv",
        [Parameter()]
        [int32]$Count = 0
        )
        
#Get the members
    if(-not $Group){
    if(-not $OU){
        Write-host -BackgroundColor Black -ForegroundColor Red "Fill in Group or OU"
        pause
        Break
    }else{$Members = Get-ADUser -Filter * -SearchBase $OU}
    }else{$Members = Get-ADGroupMember $Group -Recursive}

#Hmm Wraps
    $Wrapper = "CName" + "," + "Name" + "," + "Creation Date" + "," + "Enabled" 

    #Write to file (Overwrites)
    $Wrapper | Set-Content $File

#Do things for everyone
foreach($Member in $Members){
    if( (Get-ADUser -Identity $Member | Select-Object Enabled -ExpandProperty Enabled) -eq $true){ #Added Enabled > non default property
        $FullUser = Get-ADUser -Identity $Member -Properties WhenCreated                           #Added WhenCreated > non default property
        $CN = ($FullUser | Select-Object DistinguishedName -ExpandProperty DistinguishedName ) `
            -replace (",","\") `
            -replace ("OU=","") `            -replace ("CN=","") `
            -replace ("DC=","") `
            -replace ("\\local",".local")

        #Extract the needed values
        $Name = $FullUser | Select-Object Name -ExpandProperty Name 
        $CreationDate = $FullUser | Select-Object WhenCreated -ExpandProperty WhenCreated
        $Enabled = $FullUser | Select-Object enabled -ExpandProperty enabled
        
        #Create the Strings
        $Row = $CN + "," + $Name + "," + $CreationDate + "," + $Enabled

        #Write to file (appends)
        $Row | Add-Content $File

        #Count
        $Count = $Count + 1
    } }

#Write the count a letter
    Write-host -BackgroundColor Cyan -ForegroundColor Black "Current ADUser Count:" $Count
    Write-Host -BackgroundColor Black -ForegroundColor Green "Ding, your Microwave Meal is ready, Pickup at: " $File "!"
}