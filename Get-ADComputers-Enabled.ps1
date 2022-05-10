#Get Every AD Computer
    $Computers = Get-ADComputer -filter * -Properties Created,LastBadPasswordAttempt,LastLogonDate,Modified,OperatingSystem | `
                 Select-Object Name,SamAccountName,Enabled,OperatingSystem,Created,Modified,LastLogonDate,LastBadPasswordAttempt,SID,ObjectGUID,DistinguishedName

#Split it into Enabled & Disabled
    $Enabled = $Computers | Where-Object Enabled -EQ $True
    $Disabled = $Computers | Where-Object Enabled -EQ $False

    #Select those who didn't logon one Month
    $1MonthAgo = (Get-Date).AddMonths(-1)
    $1MonthNoLogon = $Enabled | Where-Object LastLogondate -LT $1MonthAgo

    #Select those who didn't logon one Year
    $1YearAgo = (Get-Date).AddYears(-1)
    $1YearNoLogon = $Enabled | Where-Object LastLogondate -LT $1YearAgo

#List it out
    Write-host "---------------------------------------"
    Write-host "Total AD Computers:"$Computers.Count "(`$Computers)"
    Write-Host "    Enabled AD Computers:"($Enabled).count "(`$Enabled)"
    Write-Host "    - Didn't logon for one month:"($1MonthNoLogon).count "(`$1MonthNoLogon)"
    Write-Host -f r "    - Didn't logon for one year:"($1YearNoLogon).count "(`$1YearNoLogon)"
    Write-Host "    Disabled AD Computers:"($Disabled).count "(`$Disabled)"
    Write-host "---------------------------------------"
