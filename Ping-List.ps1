#Ping-list v1.56
#get-nout
#Script to Ping a list of IP Adresses, Write & Filter the output to a file #
#Needs Edditing at the SubnetCalculation Part
function Ping-List{

    Param(
        [Parameter(Mandatory=$true,Position=1,HelpMessage="Like 192.168.1.0")]
            [String]$Subnet,
        [Parameter(HelpMessage="Standard: 24")]
            [Int]$Mask=24,
        [Parameter(Position=2,HelpMessage="Standard Start: 0")]
            [int]$Byte4,
        [Parameter(Position,HelpMessage="Standard End: Depends on Mask")]
            [int]$EndByte4=0,
        [Parameter(HelpMessage="Standard Path: S\DUMP\")]
            [String]$FilePath="S:\DUMP\",
        [Parameter(HelpMessage="Standard Speed: 1.0 Sec/Ping")]
            [Double]$Speed=1
        )
#Input Checks

#Calculate the Subnet
    #Split the Bytes
        [int]$Byte1,[int]$Byte2,[int]$Byte3,[int]$Byte4 = $Subnet.Split('.')

    if($EndByte4 -eq 0){
    Switch ( $Mask )
        {
            32 { <#Error Message Here#> }
            31 { <#Error Message Here#> }
		    30 { $EndByte4 = $Byte4 + (4-2)}
		    29 { $EndByte4 = $Byte4 + (8-2)}
		    28 { $EndByte4 = $Byte4 + (16-2)}
		    27 { $EndByte4 = $Byte4 + (32-2)}
		    26 { $EndByte4 = $Byte4 + (64-2)}
		    25 { $EndByte4 = $Byte4 + (128-2)}
		    24 { $EndByte4 = $Byte4 + (256-2)}
		    23 { $EndByte4 = $Byte4 + (512-2)}
		    22 { $EndByte4 = $Byte4 + (1024-2)}
		    21 { $EndByte4 = $Byte4 + (2048-2)}
		    20 { $EndByte4 = $Byte4 + (4096-2)}
		    19 { $EndByte4 = $Byte4 + (8192-2)}
		    18 { $EndByte4 = $Byte4 + (16384-2)}
		    17 { $EndByte4 = $Byte4 + (32768-2)}
		    16 { $EndByte4 = $Byte4 + (65536-2)}
		    15 { $EndByte4 = $Byte4 + (131072-2)}
		    14 { $EndByte4 = $Byte4 + (262144-2)}
		    13 { $EndByte4 = $Byte4 + (524288-2)}
		    12 { $EndByte4 = $Byte4 + (1048576-2)}
		    11 { $EndByte4 = $Byte4 + (2097152-2)}
		    10 { $EndByte4 = $Byte4 + (4194304-2)}
		    09 { $EndByte4 = $Byte4 + (8388608-2)}
		    08 { $EndByte4 = $Byte4 + (16777216-2)}
        }}

    #Check if the 1st byte is empty
        if($EndByte1 -eq $null){
        $EndByte1 = $Byte1
        }
    #Check if the 2nd byte is empty
        if($EndByte2 -eq $null){
            $EndByte2 = $Byte2
        }
    #Check if the 3th byte is empty
        if($EndByte3 -eq $null){
            $EndByte3 = $Byte3
        }

    #Check if the 4th byte is Larger than 255
    while($EndByte4 -gt 255){
        $EndByte3 = $EndByte3 + 1
        $EndByte4 = $EndByte4 - 255
        #Check if the 3rd byte is Larger than 255
        while($EndByte3 -gt 255){
            $EndByte2 = $EndByte2 + 1
            $EndByte3 = $EndByte3 - 255
            #Check if the 2nd byte is Larger than 255
            while($EndByte2 -gt 255){
                $EndByte1 = $EndByte1 + 1
                $EndByte2 = $EndByte2 - 255
            }
        }
    }

    #Check if the 1st byte is empty
        if($EndByte1 -eq $null){
        $EndByte1 = $Byte1
        }
    #Check if the 2nd byte is empty
        if($EndByte2 -eq $null){
            $EndByte2 = $Byte2
        }
    #Check if the 3th byte is empty
        if($EndByte3 -eq $null){
            $EndByte3 = $Byte3
        }


#Creating File Names
    $FileName = $FilePath + "ping-list-filthy.txt"
    $FileNameOut = $FilePath + "ping-list-clean.txt"
    $FileNameOutTemp = $FilePath + "ping-list-filthytemp.txt"

#Notify the user
    Write-Host "End file: $FileNameOut"
    Write-Host "Start IP: " $Byte1.ToString() . $Byte2.ToString() . $Byte3.ToString() . $Byte4.ToString()
    Write-Host "End IP:" $EndByte1.ToString() . $EndByte2.ToString() . $EndByte3.ToString() . $EndByte4.ToString()
    Write-Host "---------------"

#Pings & Pongs
    while($Byte4 -ne ($EndByte4 +1)){
        $IP = $Byte1.ToString() +"." + $Byte2.ToString() +"." + $Byte3.ToString() +"." + $Byte4.ToString()
        Write-host "Pinging $IP"
        ping $IP -w $Speed | Add-Content $FileName
        $Byte4 = $Byte4 + 1
    }

#Neater Text file
    Get-Content $FileName | Where-Object {$_ -notmatch 'reply' `
                                     -and $_ -notmatch 'request' `
                                     -and $_ -notmatch 'pinging' `
                                     -and $_ -notmatch'PING: transmit'} | Set-Content $FileNameOutTemp
    Get-Content $FileNameOutTemp | Where { $_.Trim(" `t" )} | Set-Content $FileNameOut

#Remove Junk files
    Remove-Item $FileName, $FileNameOutTemp
 }
