#Declaration
$TranscriptPath = "C:\Scripts\Logs\"
$RegkeyPath = "HKCU:\Software\"
$RegkeyName = "BootInfo"
$RegkeyPropertyName = "RebootTime"

#Test the Logpath, create it if it does not exist
if(Test-Path $TranscriptPath){
}else{ 
    New-Item -ItemType Directory -Force -Path $TranscriptPath
}

#Start Logging 
$TranscriptName = $TranscriptPath + (Get-Date -Format "yyyy.MM.dd-HH.mm.ss").tostring() +".txt"
Start-Transcript -Path $TranscriptName

#Get the boottime
$Boottime = ((Get-CimInstance Win32_OperatingSystem).LastBootupTime)

#Create the Regfolder
Try{
    New-Item -Path $RegkeyPath -Name $RegkeyName -ErrorAction Stop
}Catch{
    Write-host -f Green "Reg key already exists."
}

#Create function to Start & Lock
function Startandlock{
         Write-Host -f DarkYellow "No Previous Logon Detected, Starting Program and autolocking"

         #Renewing the value for next logon
            New-ItemProperty -Path ($RegkeyPath + $RegkeyName) -Name $RegkeyPropertyName -Value $Boottime -Force
     
         #PASTE SCRIPT HERE v v v v v v v v v v
         .  C:\Scripts\Test.bat
     
         #END SCRIPT HERE   ^ ^ ^ ^ ^ ^ ^ ^ ^ ^

         #Waiting 5 secs, locking
         Start-Sleep -Seconds 5
         rundll32.exe user32.dll, LockWorkStation
}

#Check if the Current boot time equals the stored one
if(Get-ItemProperty -Path ($RegkeyPath + $RegkeyName) -Name $RegkeyPropertyName -ErrorAction SilentlyContinue){
    
    if((Get-Date (Get-ItemProperty -Path ($RegkeyPath + $RegkeyName) -Name $RegkeyPropertyName | Select-Object RebootTime -ExpandProperty RebootTime)).ToString()` -eq (Get-date $Boottime).ToString()){
         Write-host -f Green "Previous Logon Detected, "-No ;Write-Host -f red "NOT" -no; Write-Host -f green " autolocking."
    }else{
        Startandlock #Check function above
    }
}else{
        Startandlock #Check function above
    }

Stop-Transcript

