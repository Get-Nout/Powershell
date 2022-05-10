Function Get-SMBShareWMI{
param (
        [String]$Server #SMB Host
     )
    #This also works for powershell v2!
    #Creator: Nout Geens

    #Checking the shares and converting it to powershell
    $Shares = Invoke-Command -ComputerName $Server -Scriptblock { Get-WmiObject -Class Win32_Share }
    foreach($Share in $Shares){
        $Share | Add-Member -NotePropertyName "Server" -NotePropertyValue $Server
        $_
    }
    $Shares | Select-Object Name,Path,Description,Server | Sort-Object Name 
}


