Function Get-LoggedOnUsers{
#Creator: Nout Geens
#Version: 1.0

    Param(
        [String]$ComputerName = $env:COMPUTERNAME

        )

    #Create the Command (need to convert it to a scriptblock)
        $Command = [SCRIPTBLOCK]::Create("Quser /Server:" + $ComputerName)
    
    #Execute it   
        $Quser = Invoke-Command -ScriptBlock $Command
        $Quser = $Quser | Select-Object -Skip 1

    #Reset a value
        $UserArray = @(); $Username =""; $SessionName =""; $ID =""; $State =""; $IdleTime =""; $LogonTime =""

    #Convert it to powershell
        foreach($Userline in $Quser){
            #For every line, substring the value
            $Username = $Userline.SubString(1, 20).Trim()
            $SessionName = $Userline.Substring(23,18).Trim()
            $ID = $Userline.Substring(42,3).Trim()
            $State = $Userline.Substring(46,6).Trim()
            $IdleTime = $Userline.Substring(53,10).Trim()
                #Check if the values contain numbers
                    if($IdleTime -eq '.'){
                        $IdleTime = New-TimeSpan -Minutes 0
                    }elseif($IdleTime.Contains('+')){
                      #Is DayHoursMins
                        $IdleTime = $IdleTime.Split('+').split(':')
                        $IdleTime = New-TimeSpan -Days $IdleTime[0] -Hours $IdleTime[1] -Minutes $IdleTime[2]
                    }elseif($IdleTime.Contains(':')){
                      #Is HoursMins 
                        $IdleTime = $IdleTime.Split(':')
                        $IdleTime = New-TimeSpan -Hours $IdleTime[0] -Minutes $IdleTime[1]
                    }elseif($IdleTime.Contains("none")){  
                      #Is Active
                        $IdleTime = New-TimeSpan -Seconds 0
                    }else{
                      #Is Mins
                        $IdleTime = New-TimeSpan -Minutes $IdleTime
                    }
            $LogonTime = Get-date ($Userline.Substring(65,($Userline.Length-65)))

            #Create an object for it
            $Userobject = @()
            $Userobject = New-Object -TypeName psobject
            $UserObject | Add-Member -NotePropertyName "Username" -NotePropertyValue $Username
            $UserObject | Add-Member -NotePropertyName "SessionName" -NotePropertyValue $SessionName
            $UserObject | Add-Member -NotePropertyName "ID" -NotePropertyValue $ID
            $UserObject | Add-Member -NotePropertyName "State" -NotePropertyValue $State
            $UserObject | Add-Member -NotePropertyName "IdleTime" -NotePropertyValue $IdleTime
            $UserObject | Add-Member -NotePropertyName "LogonTime" -NotePropertyValue $LogonTime
            $UserObject | Add-Member -NotePropertyName "Server" -NotePropertyValue $ComputerName

            #Remove this line
            Write-Host "Checked user:" $Username
            #Add the object to the array
            $UserArray += $Userobject
            }
        $UserArray
}