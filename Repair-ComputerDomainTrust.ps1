<#Info
    Repairs the trust between two computer objects
#>
#Declaration
$DomainName = "nout.local"
$LocalDC ="SRVNOUT101"
$RepairAccountName = "TempAdmin"
$RepairAccountPWD = "SüperSecure123"

#Create the computer object
$Computer = New-Object -TypeName PSCustomObject -ArgumentList @{Name = $env:COMPUTERNAME}
$Computer | Add-Member -NotePropertyName OS -NotePropertyValue (Get-CimInstance -ClassName Win32_OperatingSystem |Select-Object Caption -ExpandProperty Caption)

#Do different things depending on the OS
Switch($Computer.OS){
    "*Windows 10*"{
        #Creating the Secure credentials
        #Convert the Pwd to secure string
        [SecureString]$RepairAccountPWDSecure = ConvertTo-SecureString $RepairAccountPWD -AsPlainText -Force
        #Create the Cred Object
        [pscredential]$CredObject = New-Object System.Management.Automation.PSCredential ($RepairAccountName, $RepairAccountPWDSecure)

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
