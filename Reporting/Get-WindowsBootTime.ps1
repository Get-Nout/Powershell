Function Get-WindowsBootTime{
    Param(
        [String]$ComputerName = $env:COMPUTERNAME

        )

    if($ComputerName -eq $env:COMPUTERNAME){
        $BootTimeWmic = (wmic os get lastbootuptime)[2]
    }else{
        $BootTimeWmic = Invoke-Command -ComputerName $ComputerName -Scriptblock{(wmic os get lastbootuptime)[2]}
    }

$BootTimeYear = $BootTimeWmic.Substring(0,4) 
$BootTimeMonth = $BootTimeWmic.Substring(4,2)
$BootTimeDay = $BootTimeWmic.Substring(6,2)
$BootTimeHour = $BootTimeWmic.Substring(8,2)
$BootTimeMin = $BootTimeWmic.Substring(10,2)
Get-date -Year $BootTimeYear -Month $BootTimeMonth -Day $BootTimeDay -Hour $BootTimeHour -Minute $BootTimeMin

}