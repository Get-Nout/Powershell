Function Restart-Computer-Extended {
    #region -------- Info ---------         
    #Reboot an array of servers
    #Creator: Nout Geens
    #Version: 1.6
    <#Changelog
        1.0 Created
        1.1 Changed into function
        1.2 Looped for multiple servers
        1.3 Added Validation Check, Corrected some Strings
        1.4 Added smtp & Write-hosts
        1.5 Made the SMTP send only one mail
        1.5.1 Cleared up typo's
        1.5.2 Added an Example
        1.5.3 Added a use case
        1.5.4 Added Imports of modules
        1.6 Added Logging
    #>
    <#Notes
        When running this from a clean powershell or task schedule use this format
        . P:\Maintanance\Restart-Computer-Extended.ps1
        Restart-Computer-Extended -Servers SRV001, SRV002, SRV003 -WaitTime 10 -TimeBetween 8

        Active directory RSAT tools are required on the server, you can install these as admin:
            Import-Module ServerManager
            Add-WindowsFeature -Name "RSAT-AD-PowerShell" –IncludeAllSubFeature
    #>
    <#Examples
        Restart-Computer-Extended -Servers SRV001, SRV002, SRV003 -WaitTime 10 -TimeBetween 8
            This will do the following
                - Search for the server names in AD to check if they exist
                - Check if all the servers are remotly accessible (and online)
                - Starting at SRV001:
                    - Notify the users on that server that it wil reboot in 10 Mins
                    - Wait 9 mins
                    - Notify the users again
                    - Wait 1 Min
                    - Restart the server and wait for 8 Mins
                    - Check if the server came back online
                    - If it did, check for the time online and if it is more than 1 day asume it did not reboot at all
                - Start process for next server...
                - Create a mail and send it
    #>
    #endregion ---------------------

    param( 
        [String[]]$Servers,
        [Int]$WaitTime = 10, # Mins the users get to log off
        [Int]$TimeBetween = 5, # Mins between server & the check if they are booted ok
        [String]$Mailserver = "mailout.ithost.be",
        [Int]$Port = 25,
        [String]$Recipient = "Monitoring@ithost.be",
        [String]$Sender = "Reboot@ithost.be",
        [String]$LogfilePath = "\\Ithost.local\ithost$\techdata\Scripts\Maintenance\Logs\"
        )

    #Import
        Import-Module ActiveDirectory

    #Empty Previous Values
        $RServers = @(); $Server =""; $RServer=""; $Error.Clear(); $ConnectionError ="";$Cancelled = 0;$Success =0;$Failed = 0;
    
    #Get the starttime & create the logging start
        $StartTime = (Get-Date)
        $LogFileName = "RebootLog." +(Get-Date -Format "yyyy-MM-dd-HH-mm") + ".txt"
        $LogFileFullName = $LogfilePath + $LogFileName
        Start-Transcript -Path $LogFileFullName -NoClobber

    #Resolve the names to check if they are valid
        foreach($Server in $Servers){
            if(Get-ADComputer -Filter { name -like $Server}){
                      
                #Check if we can remote powershell into the server
                Write-Host "Testing connection to" $Server "..."
                
                if(Get-CimInstance Win32_OperatingSystem -ComputerName $Server -ErrorAction SilentlyContinue){
                    #Successfuly connected
                    $RServers += Get-ADComputer -Filter { name -like $Server} | Select-object DNSHostName -ExpandProperty DNSHostName

                }else{
                    #Failed to connect
                    Write-Host -f Red $Server "is not reachable at this time.`n Are you Running as admin?"
                    $Body = "`n" + $Server + " was not reachable to reboot, was it online to start with?"
                    $Cancelled += 1
                    
                }
            }else{
                #Not listed in AD
                Write-Host -f Red $Server " was not found in AD!"
                $Cancelled += 1
                $Body = "`n" + $Server + " was not found in AD! Did you make a typo or are you trying to reboot a non domain server?`n"
            }
            
            #If it was cancelled, add it to the mail
            if($Cancelled -ge 1){ 
                $RBody += $Body + "`n ----------------- `n "
            }
        }

    #Start the reboot loop
    foreach($RServer in $RServers){
    try{
        #Notify Admin
        Write-Host "Starting Schedule:"$RServer 

        #Clean previous values
            $Error.Clear(); $Body = ""
        #Check if the waittime is larger than 1
        if($WaitTime -gt 1){
            #Notify the users x Min
            $Message = "Server Reboot in " + $WaitTime + " Minutes, Save all your data!"
            Invoke-Command -computername $RServer -ScriptBlock {msg * $Using:Message} -ErrorAction SilentlyContinue
            Write-Host "Users Notified: " $Message  

            #Wait (x*60-60) Min
            Write-Host "Starting Sleep for the waittime ("  $WaitTime  "minutes)"
            Start-Sleep -Seconds ($WaitTime*60-60)

            #Notify the users 1 Min
            $Message = "Server Reboot in one Minute, Save all your data and quit!"
            Invoke-Command -computername $RServer -ScriptBlock {msg * $Using:Message} -ErrorAction SilentlyContinue
            Write-Host "Users Notified: " $Message 

            #Wait 1 Min
            Write-Host "Starting Sleep for the waittime 1 minute"
            Start-Sleep -Seconds 60

        }else{

            ##Notify the users 1 Min
            $Message = "Server Reboot in one Minute, Save all your data!"
            Invoke-Command -computername $RServer -ScriptBlock {msg * $Using:Message} -ErrorAction SilentlyContinue
            Write-Host "Users Notified: " $Message 
            Write-Host "Starting Sleep for the waittime of 1 minute."
            Start-Sleep -Seconds 60 -ErrorAction SilentlyContinue 
        }

        #Restart the computer
        Write-Host "Restarting: "$RServer -ErrorAction SilentlyContinue 
        Restart-Computer -ComputerName $RServer -Force 

    }Catch{     
        #Error 1
            Write-Host -f Red "Failed to restart computer" $RServer ":"
            $Error[0], "`n"

            #Create notification
            $Body = $RServer + " has not started it's scheduled reboot. `n " + $Error[0] + "`n -----------------"
            $Priority += "High"
            $Failed += 1
    }
    #Wait the time between before starting the next server's reboot
    Write-Host "Waiting for $TimeBetween minutes before continuing..."
    ($TimeBetween*60) | Start-Sleep  
         
    #Check if server booted correctly (only of the previous command has been successfull)
         if(Select-String -InputObject $Error[0] -Pattern "Restart-Computer" -NotMatch){        
            #Get the Time online  
            $RTime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem -ComputerName $RServer).LastBootupTime

            #Check if we have data
            if($RTime -ne ""){
                if($RTime.Days -lt 1){
                #Success
                    #Notify Monitoring
                    $Body = $RServer + " has rebooted and came back online " + $RTime.Hours + " hours and " + $RTime.Minutes + " minutes ago." 
                    $Priority += "Normal"
                    $Success += 1

                }else{
                #Error 2
                    #Notify Monitoring
                    $Body = $Rserver + " has not rebooted `n " + $Error[0] + "`n -----------------"
                    $Priority += "High"
                    $Failed += 1
                }
            }else{
            #Critical 1
                #Notify Monitoring
                $Body = $Server + " has not rebooted, Check if it needs to be turned on! `n " + $Error[0] + "`n -----------------"
                $Priority += "High"
                $Failed += 1
            }
        }
        #Add this line to 
        $RBody += $Body + "`n"
        
    }

    #region Notify Monitoring
        #Create the Title
            
            if($Failed -ge 1){
            #Servers where rebooted, but some failed
                $Subject = "Server Reboot Status Report - Failure (" + $Failed + " out of " + $Servers.count + " have failed!)"
            }elseif($Cancelled -ge 1){
            #there where no failures, but some didn't start the reboot
                $Subject = "Server Reboot Status Report - Cancelled ($Cancelled out of " + $Servers.Count + " have been Cancelled)"
            }else{
            #Everything went magicaly well
                $Subject = "Server Reboot Status Report - Everything went fine! ($Success out of " + $Servers.count + ")"
            }

        #Add a little menu
        $ServerList = $Servers -join " | "
        $Quickview = "------------------ `n Servers: $ServerList `n Startime: $StartTime `n Success: $Success `n Cancelled: $Cancelled `n Failed: $Failed `n------------- `n "
        $Footer = "`n`n This mail was send from: " + $env:COMPUTERNAME + " at " + (Get-Date -Format "yyyy/mm/dd HH:MM")
        $RBody = $Quickview + $RBody + $Footer

        #End Logging
        Stop-Transcript

        #Realy send it
        if($Priority -like "*High*"){
            Send-MailMessage -From $Sender -SmtpServer $Mailserver -Port $Port -to $Recipient -Subject $Subject -Body $RBody -Attachments $LogFileFullName -Priority High
        }else{
            Send-MailMessage -From $Sender -SmtpServer $Mailserver -Port $Port -to $Recipient -Subject $Subject -Body $RBody -Attachments $LogFileFullName 
        }#endregion
}