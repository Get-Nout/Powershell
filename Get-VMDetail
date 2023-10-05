Function Get-VMDetail{
    <#Info
        Purpose: Get Details you can't get trough Get-VM (Hyper-V)
                 Made this to get the Hostname of a VM from Hyper-v
        Creator: Nout Geens
        Version: 1.0
            1.0: NG: Created
        How it works:
            Pulls Ciminstance & associated info, converts that raw data into an object
    #>
    Param([String]$VMName, [String]$ComputerName = "Localhost")

    #Create the Query and get the info
    $Query = "Select * From Msvm_ComputerSystem Where ElementName='$VMName'"
    $VM = Get-CimInstance -namespace root\virtualization\v2 -query $Query -computername $ComputerName

    #Get associated information
    $vm_info = Get-CimAssociatedInstance -InputObject $vm

    #Get the Details we need from that info
    $RawData = ($vm_info | Where-Object Name -Like "Key-Value Pair Exchange").GuestIntrinsicExchangeItems

    #Convert the Content from Raw data into an PSObject
    $Content = $RawData.Replace("<PROPERTY","`n`t<PROPERTY")
    $Content = $Content.Replace("<INSTANCE","`n<INSTANCE")
    $ContentArray = $Content -split ("</Instance>")
    $OutputObject = New-Object PSObject 

    #Convert each 'Instance' into a Property using its name and Data property
    foreach($Instance in $ContentArray){
        $Properties = $Instance -Split("<PROPERTY NAME")

        $InstanceObject = New-Object PSObject

        #Converting the properties to real properties
        foreach($Property in $Properties){
            if($Property -notlike "*INSTANCE*"){
                if($Property -ne "" -and $Property.length -ne 0){
                    $Property = $Property.Replace('=',"")
                    $PropertyName = $Property.Substring(1,$Property.IndexOf("TYPE")-3)

                    if($Property -like "*VALUE*"){
                        $PropertyValue = $Property.Substring($Property.Indexof("<VALUE>")+7,$Property.IndexOf("/")-$Property.Indexof("<VALUE>")-8)
                    }else{
                        $PropertyValue = ""
                    }
                }
                $InstanceObject | Add-Member -NotePropertyName $PropertyName -NotePropertyValue $PropertyValue
                
            }   
        }     
            if($InstanceObject.Name -ne $null -and $InstanceObject.Data -ne $null){
                $OutputObject | Add-Member -NotePropertyName $InstanceObject.Name -NotePropertyValue $InstanceObject.Data
            }
    }
    #Return the object
    $OutputObject 
}
