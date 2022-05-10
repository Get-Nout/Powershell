Function Ping-Time {
 param( [String]$Destination, $Delay = 1
 while($true){
    $Date = get-date -Format HH:mm:ss
   
	$TestObject = Test-Connection $Destination -Count 1 |Select-Object * 
    	$TestObject |Add-Member -NotePropertyName Time -NotePropertyValue $Date
    	$TestObject | Select-Object Address,Time,ResponseTime

     Start-Sleep -Seconds $Delay
 }
}