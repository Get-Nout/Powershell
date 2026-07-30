#Get Event logs since Yesterday
#v0.5
#Creator:Nout

#Declaration
$Servers = "SRVNOUT001"
$Logname = "DFS*"
#Yesterdaaaaayy
$Yesterday = (get-date).AddDays(-1).ToString("yyy/MM/dd")

#foreach server
Foreach($Server in $Servers) {
    Write-Host "-------------"$Server "------------- "
    #Get the log
    $Errors = Get-EventLog -ComputerName $Server -After $Yesterday -logname $Logname -EntryType Error
    
    #Show howmanny of them where present
    Write-Host ($Errors | measure | Select-Object Count -ExpandProperty Count) "Errors Found Since $Yesterday"
    $Errors
}
