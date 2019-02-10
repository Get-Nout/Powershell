# Passwoord Reset based on text/csv File, Comma Seperated.
# Creator: Nout Geens
# Version: 1.0

# CSV Format : Name, Type, Password
# Name: "Nout Geens"
# Type: "User"
# Password: "SeCuére"

Import-Module ActiveDirectory

#Declaration
$File = "C:\Temp\PASS.csv"
$List = Import-Csv $File
$DeleteFile = "no" #This deletes the File when the script ends

#Looping
foreach($Item in $List){

    #Idiot Proofing, that includes me
    Write-Host -BackgroundColor Black -ForegroundColor Yellow "Resetting" $List.Count "Passwords, are you sure? [Y/N]"
    $Answer = Read-Host 

    #if you are REAALLLLYY sure
    if($Answer -eq "y" -or $Answer -eq "Y"){
        $Password = ConvertTo-SecureString $Item.Password -AsPlainText -Force
        $User = Get-ADUser -filter * | Where-Object Name -EQ $Item.Name
        Set-ADAccountPassword -Identity $User.SamAccountName -reset -NewPassword $Password
        Write-Host -BackgroundColor Black -ForegroundColor Green "Changed"$user.Name "'s Password"
    }
}

#Don't Leave plain text passwords
$List = ""
$Item = ""

if($DeleteFile -eq "yes"){Remove-Item $File}
else{ Write-Host -BackgroundColor Black -ForegroundColor Red "Manualy Delete the plaintext file please!"}

