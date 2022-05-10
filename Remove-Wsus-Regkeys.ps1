Clear

$Check = ""

Write-host -f DarkYellow "Use Wsus?:" (Get-ItemPropertyValue -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer")
Write-host -f DarkYellow "Wsus Name:" (Get-ItemPropertyValue -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name "WUServer")
Write-host -f DarkYellow "Wsus Status Server Name:" (Get-ItemPropertyValue -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name "WUStatusServer")

$Check = Read-Host -Prompt "Do you want to reset these values? (y/n)"

if($Check -eq "y"){
    #Remove wsus usage
        $Location ="HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate\AU"

        $KeyName = "UseWUServer"
        $Type = "Reg_DWORD"
        $Value = 0



        reg add $Location /t $Type /v $KeyName /d $Value /f

    #Remove wsus value
        $Location = "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate"

        $KeyName = "WUServer"
        $Type = "Reg_SZ"
        $Value = " "

        reg add $Location /t $Type /v $KeyName /d $Value /f

    #Remove wsus  Status Server value
        $Location = "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate"

        $KeyName = "WUStatusServer"
        $Type = "Reg_SZ"
        $Value = " "

        reg add $Location /t $Type /v $KeyName /d $Value /f

    Write-host -f Green "Use Wsus?:" (Get-ItemPropertyValue -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer")
    Write-host -f Green "Wsus Name:" (Get-ItemPropertyValue -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name "WUServer")
    Write-host -f Green "Wsus Status Server Name:" (Get-ItemPropertyValue -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name "WUStatusServer")
}else{
    Write-host "Canceled"
}