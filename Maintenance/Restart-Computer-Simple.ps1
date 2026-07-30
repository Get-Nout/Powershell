#Rebootscript
#V1.0

#Declaration
$ServerNames = "localhost"

#Empty Previous Values
$Servers = @();$ServerName =""; $Server =""

#Resolve the names to check if they are valid
foreach($ServerName in $ServerNames){
    $Servers += Get-ADComputer -Filter { name -like $ServerName}
}


foreach($Server in $Servers){ 
    try{
        #Notify the users
        Invoke-Command -computername $Server.DNSHOSTNAME -ScriptBlock {msg * "Server Reboot in 5 Minuits, Save all your data!"} -ErrorAction SilentlyContinue

            #Wait 4 Minuits
            Start-Sleep -Seconds 240

        #Notify the users
        Invoke-Command -computername $Server.DNSHOSTNAME -ScriptBlock {msg * "Server Reboot in 1 Minuit, Save all your data and quit!"} -ErrorAction SilentlyContinue

            #Wait 1 Minuit
            Start-Sleep -Seconds 60

        #Restart the computer
        Restart-Computer -ComputerName $Server.DNSHOSTNAME -Force
        
    }Catch{ 
        Write-Host "Something failed"
    }
}
