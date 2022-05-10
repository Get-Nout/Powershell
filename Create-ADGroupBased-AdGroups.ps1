#Script to populate Ad Groups with the members of corresponding Default Groups
# Members of "Printer1-Default" are added tot group "Printer1"

#Declaration 
$NameIndicator = "Nout-prt*"
$DefaultIndicator = "*default"

#Get the groups
$PrinterGroups = Get-ADGroup -Filter { (name -like $NameIndicator) -and (name -like $DefaultIndicator) } |Select-Object Name -ExpandProperty Name

#Clear previous values
$DoesNotExist = @()

#Loop the loop
foreach($PrinterGroup in $PrinterGroups){
    Write-host "Checking Printergroup:"$PrinterGroup

    #Generate the "basic group Name"
    $NonDefaultGroup = $PrinterGroup -replace("_Default","")

    try{
        #Get the "basic group"
        $NonDefaultGroup = Get-ADGroup -Identity $NonDefaultGroup
        Write-Host "Found Group:          " $NonDefaultGroup.name

        #Get the members of the Default Group
        $Members = Get-ADGroupMember -Identity $PrinterGroup.Name |Select-Object Name, SamAccountName,Enabled
        
        Try{
            #Add them to the "basic groups"
            foreach($Member in $Members){
                if($Member.Enabled){
                    Write-Host -ForegroundColor Yellow $Member.name
                    Add-ADGroupMember -Identity $NonDefaultGroup.Name -Members $Member.SamAccountName
                }
            }
        }Catch{
            #error on Add-AdGroupMember
            Write-Host -ForegroundColor Yellow "Already a member of the group."
        }
        
    }catch{
        #error on Get-AdGroup
        Write-Host -ForegroundColor Red "Counterpart of $PrinterGroup does not exist!"
        $DoesNotExist += $NonDefaultGroup + ","
    }
}

#Show them what u have done
if($DoesNotExist -ne ","){
    Write-Host -ForegroundColor Red "These are not AD Groups:"
    Write-Host -ForegroundColor Red $DoesNotExist |Format-Table -AutoSize
}else{ Write-Host -ForegroundColor Green "Everything seems fine." }

