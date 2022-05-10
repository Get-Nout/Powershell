

function ping-u(){
param(
    [String]$Text = "Noot Noot!"
)
#First Line
    $i = 0
    while($i -lt $Text.Length +5){
        Write-Host "=" -NoNewline
        $i++
    }
    Write-Host "="

#Second line
    Write-Host "| " $Text " |"

#Third line
    $i = 0
    while($i -lt $Text.Length){
        Write-Host "=" -NoNewline
        $i++
    }
    Write-Host "\   =="
#Four
    $i = 0
    while($i -lt $Text.Length+1){
        Write-Host " " -NoNewline
        $i++
    }
    Write-host "\  |"
#Five
    $i = 0
    while($i -lt $Text.Length+2){
        Write-Host " " -NoNewline
        $i++
    }
    Write-host "\ |"
#Six
    $i = 0
    while($i -lt $Text.Length+3){
        Write-Host " " -NoNewline
        $i++
    }
    Write-host "\|"

#Pinguin
    #Line 1
    $i = 0
    while($i -lt $Text.Length+6){
        Write-Host " " -NoNewline
        $i++
    }
    Write-host "__"
    #Line 2
    $i = 0
    while($i -lt $Text.Length+3){
        Write-Host " " -NoNewline
        $i++
    }
    Write-host "-=(o '."
    #Line 3
    $i = 0
    while($i -lt $Text.Length+6){
        Write-Host " " -NoNewline
        $i++
    }
    Write-host "'.-.\"
    #Line 4
    $i = 0
    while($i -lt $Text.Length+6){
        Write-Host " " -NoNewline
        $i++
    }
    Write-host "/|  \\"
    #Line 5
    $i = 0
    while($i -lt $Text.Length+6){
        Write-Host " " -NoNewline
        $i++
    }
    Write-host "'|  ||"
    #Line 6
    $i = 0
    while($i -lt $Text.Length+6){
        Write-Host " " -NoNewline
        $i++
    }
    Write-host "_\_):,_"
}

ping-u

