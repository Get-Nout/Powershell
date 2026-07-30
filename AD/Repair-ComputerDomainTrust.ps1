<#
.SYNOPSIS
    Tests and repairs the secure channel trust between a computer and the domain.
.DESCRIPTION
    Checks Test-ComputerSecureChannel and, if it fails, repairs it using a designated repair account against the local DC. Behavior branches by detected OS version.
.NOTES
    Author: Nout Geens
#>
#Declaration
$DomainName = "contoso.local"
$LocalDC ="DC01"
$RepairAccountName = "TempAdmin"

#Create the computer object
$Computer = New-Object -TypeName PSCustomObject -ArgumentList @{Name = $env:COMPUTERNAME}
$Computer | Add-Member -NotePropertyName OS -NotePropertyValue (Get-CimInstance -ClassName Win32_OperatingSystem |Select-Object Caption -ExpandProperty Caption)

#Do different things depending on the OS
Switch($Computer.OS){
    "*Windows 10*"{
        #Prompt for the repair account's credentials (not stored in the script)
        [pscredential]$CredObject = Get-Credential -UserName $RepairAccountName -Message "Credentials for the domain repair account"

        #Test the connection, if false, run the repair
        
        if(Test-ComputerSecureChannel){
            #The Test Succeeded, the Computer account is ok
            Write-Host "The Test Succeeded, the Computer account is ok"
            $Computer | Add-Member -NotePropertyName "ADAuthenticated" -NotePropertyValue $true -Force
        }

        Else{
            #The Test Failed, the Computer account is not ok!
            Write-Host "The Test Failed, Starting the repair.."
            Test-ComputerSecureChannel -Repair -Server ($LocalDC +"."+ $DomainName) -Credential $CredObject -ErrorAction SilentlyContinue
            
            if(Test-ComputerSecureChannel){
                Write-Host "Repaired the computer object"
            }else{Write-Host "Repair Failed!"}
        }
    Break;}

    "*Windows 8*"{
    
    Break;}

    "*Windows 7*"{
    
    Break;}

}
