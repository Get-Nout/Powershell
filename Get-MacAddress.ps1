#Notes
    # Check the arp table for the inputted ip address
    # version: 1.0
function Get-MacAddress{
    param(
        [String]$Address,
        [Switch]$All = $True
    )

    #To be sure it's listed and updated, ping the address
    if($Address -ne ""){
        Write-host -f Green "Pinging Address . . ."
        $Empty = Ping $Address -n 1
        $All = $false
    }

    #Get the ARP Table
    $ARPTableRaw = Arp -a
    
    #Create an empty Array
    $ARPTable = @()

    #Loop the table to format is as an object Array
    foreach($Row in $ARPTableRaw){
            
        #Check if the Row is empty or unusable
        if($Row -like "" -or $Row -like "*internet address*"){

        #Check if the row is an interface name
        }Elseif($Row -like "Interface*"){
            $Interface = $Row.Substring(11,$row.LastIndexOf(".")-7).Trim()
        }Else{
            #Trim the Spaces in front & in the back
            $Row = ($Row.TrimStart()).trim()

            #Get the Ip, Mac, And type
            $EntryIP = $Row.Substring(0,$row.LastIndexOf(".")+4).Trim()
            $EntryMac = $Row.Substring($row.IndexOf("-")-2,17).Trim()
            $EntryType = $Row.Substring($Row.Length-7,7).trim()

            #Write to object
            $Entry = New-Object -TypeName PSObject
            $Entry | Add-Member -NotePropertyName "IP" -NotePropertyValue $EntryIP
            $Entry | Add-Member -NotePropertyName "Mac" -NotePropertyValue $EntryMac
            $Entry | Add-Member -NotePropertyName "Type" -NotePropertyValue $EntryType
            $Entry | Add-Member -NotePropertyName "Interface" -NotePropertyValue $Interface

            $ARPTable += $Entry
        }#endelse
    }#endforeach

    if($All){
        $ARPTable
    }

    if($Address -ne $null){
        $ARPTable | Where-Object IP -Like $Address  
    }
}
