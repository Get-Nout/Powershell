function RunAs{
    #Purpose: Open program on other session
    #Creator: https://stackoverflow.com/users/1527542/gauss
    #Version: 1.0.1
    <#Changelog
        1.0.1    Changed variable names for readability
    #>
    param (
        [string]$Computer = ($env:computername),
        [string]$User = "",    

        [string]$Command,
        [string]$Args
     )

    $script_task = {

        param (
            [string]$User = "",
            [string]$Command,
            [string]$Args
         )

        #Action
        $Action = New-ScheduledTaskAction –Execute $Command
        if($Args.Length > 0) { $Action = New-ScheduledTaskAction –Execute $Command -Argument $Args}

        #Principal
        $Principal = New-ScheduledTaskPrincipal -UserId $User -LogonType Interactive -ErrorAction Ignore

        #Settings
        $Settings = New-ScheduledTaskSettingsSet -MultipleInstances Parallel -Hidden

        #Create TEMPTASK
        $TASK = New-ScheduledTask -Action $Action -Settings $Settings -Principal $Principal

        #Unregister old TEMPTASK
        Unregister-ScheduledTask -TaskName 'TEMPTASK' -ErrorAction Ignore -Confirm:$false

        #Register TEMPTASK
        Register-ScheduledTask -InputObject $TASK -TaskPath '\KD\' -TaskName 'TEMPTASK'

        #Execute TEMPTASK
        Get-ScheduledTask -TaskName 'TEMPTASK' -TaskPath '\KD\' | Start-ScheduledTask

        #Unregister TEMPTASK
        Unregister-ScheduledTask -TaskName 'TEMPTASK' -ErrorAction Ignore -Confirm:$false

    }

    #The scriptblock get the same parameters of the .ps1
    Invoke-Command -ComputerName $Computer -ScriptBlock $script_task -ArgumentList $User, $Command, $Args

}