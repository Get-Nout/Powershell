#Get the logged-on Admins who tell others to logoff
#Creator: Nout Geens
#Version: 1.2
<#Changelog
    1.0 Created
    1.1 Changed inefficient code
    1.2 Added Write-Progress
#>

#Obtaining the full Serverlist from AD
    Write-Host "Obtaining the full Serverlist from AD"
$Servers = Get-ADComputer -filter * -Properties OperatingSystem, CanonicalName, Enabled | `
        Where-Object {(($_.OperatingSystem -Like "*2019*" -or $_.OperatingSystem -Like "*2016*" -or $_.OperatingSystem -Like "*2012*"-or $_.OperatingSystem -Like "*2008*" -or $_.OperatingSystem -Like "*2003*") `
                    -and ($_.name -notlike "*clb*") `
                    -and ($_.name -notlike "foc*") `
                    -and ($_.Enabled -eq $true) `
                    -and ($_.CanonicalName -notlike "*Cleanup*"))} | `
        Select-Object * | `
        Sort-Object Name

#Cleaning up old values
    $Reachable = @(); $UnReachable = @();$AdminList =@()

#Getting external commands
    . \\ithost.local\ithost$\techdata\Scripts\Commandlets\Get-LoggedOnUser.ps1
     
#Looping it all
foreach($Server in $Servers){
    #Notify the admin
    $Status = "Checking " +$Server.Name + ", " +$Servers.IndexOf($Server) +" out of "+ $Servers.Count
    Write-Progress -Activity "Checking Servers" -Status $Status -ErrorAction SilentlyContinue -PercentComplete($Servers.IndexOf($Server) / $Servers.Count)

    #Check if the server can be reached
        if(Test-Connection -Computername $Server.Name -Count 1 -ErrorAction SilentlyContinue){
                #Get the users
                $Admins = Get-LoggedOnUsers -ComputerName $Server.Name | Where-Object Username -Like "*admin*"
                Write-host "Done Checking"$Server.Name "..."
                $Reachable += $Server

        }Else{ Write-host $Server.Name "is not reachable"
                $UnReachable += $Server}
        
    $AdminList += @($Admins)
}
#List it out
    Write-Host "-----------------------------"
    Write-host "Connected to "$Reachable.count" out of "$Servers.Count" Servers."
    $FilterdAdminList = $AdminList | Sort-Object Username,Server -Unique
    $FilterdAdminList | Group-Object Username | Select-Object Count, Name | Sort-Object Count -Descending
    Write-host "There are "$UnReachable.count "unreachable servers, use $ UnReachable to see them. `nThis could be because of access rights."

#$FilterdAdminList | Where-Object Username -EQ admingp | ft
