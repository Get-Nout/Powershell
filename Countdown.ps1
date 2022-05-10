$StartTime = "8:30:00"
$Endtime = "17:00:00"
$Freedom = $false

$EndOfDay = Get-date -Hour ($Endtime.Split(":"))[0] -Minute ($Endtime.Split(":"))[1] -Second ($Endtime.Split(":"))[2]
$StartOfDay = Get-date -Hour ($StartTime.Split(":"))[0] -Minute ($Endtime.Split(":"))[1] -Second ($Endtime.Split(":"))[2]
$Workday = New-TimeSpan -Start $StartOfDay -End $EndOfDay

While($Freedom -ne $True){
Clear
    $Now = Get-Date -Format HH:mm:ss
    $TimeRemaining = New-TimeSpan -Start $Now -End $Endtime

    $TimeDone = ($Workday - $TimeRemaining)
    $Procent = [Math]::Round(($Timedone.TotalHours /$Workday.TotalHours *100),0)
    if($TimeRemaining.TotalHours -le 0){
        $Freedom = $True
        Write-Progress -Activity "Working" -Status "Time's Up!"
    }else{
        Write-Progress -Activity "Working" -Status ("You still have some time left! " + $TimeRemaining.Hours + " hours, " + $TimeRemaining.Minutes  + " minutes and " + $TimeRemaining.Seconds + " seconds.")
    }

   Start-Sleep -Seconds 5
}

