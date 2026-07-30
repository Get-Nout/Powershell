$Letter = (Read-Host "Provide the disk letter you want to monitor (like D)")+":"
$Disk = Get-WmiObject Win32_LogicalDisk | Where-Object DeviceID -eq $Letter

while($Disk.FreeSpace -gt 0){
    $Disk = Get-WmiObject Win32_LogicalDisk | Where-Object DeviceID -eq $letter
    $PercentComplete = (100/$Disk.Size)*$Disk.FreeSpace
    $Status = "Drive $Letter is  currently at" + ([math]::Round($PercentComplete,2)) +"%, "+ ([math]::Round($Disk.FreeSpace /[Math]::Pow(1024, 3),2)) +"GB Free space Remaining. [CTRL-C] To Exit"
    Write-Progress -PercentComplete $PercentComplete -Activity "Checking Disksize" -Status $Status
    Sleep -Seconds 1
}
