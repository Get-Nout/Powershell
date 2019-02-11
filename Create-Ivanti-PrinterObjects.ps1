#Script for generating Invanti building blocks for printers.
#Based on template from Exported ivanti Building block v10.2.800.0
#Also Creates an AD Group if value is enabled
#Creator: Nout Geens
#Customer: CLB ICT & Hosting
#V2.4

<#Changelog
  2.4: Added Check on export folder  
#>
#Declaration
    $PrintServer = "Printserver"
    $Domain = "Domainname\" #Invanti can't handle .LOCAL!
    $ADGroupLead = "Nout-PRT-"
    $GroupOU = "OU=Printers,OU=Local-groups,OU=Nout,DC=local"
    $TemplateLocation = "C:\temp\Template.txt"
    $ExportLocation = "C:\temp\Printers\"

    $CreateAdGroups = "no"
    $Default = "yes"
    $ADGroupEnd ="_Default"

#Get the Printers, not microsoft xps
    $Printers = @()
    $Printers = Get-Printer -ComputerName $PrintServer| Where-Object name -NotLike "*Microsoft*" |Select-Object Name -Unique

#Import the template
    $Template = Get-Content -Path $TemplateLocation

#Clearing Values
    $CountFiles,$CountGroups,$CountExisting = 0

#Test the Export Location, if unexistent, create it
    if((Test-Path -Path $ExportLocation) -eq $false){
        New-Item -Path $ExportLocation -ItemType Directory
    }

#Create AD Groups
if($CreateAdGroups -eq "yes"){
    foreach($Printer in $Printers){
        if($Default -eq "Yes" -or $Default -eq "yes"){
            $ShortName = $ADGroupLead + $printer.Name +$ADGroupEnd
        }else{ 
            $ShortName = $ADGroupLead + $printer.Name
        }
    
        $LongName = "Printer " +$Printer.Name
        #Try to create the group
        try {
            New-ADGroup -Name $ShortName -SamAccountName $ShortName `                                        -GroupCategory Security `
                                        -GroupScope DomainLocal `
                                        -DisplayName $LongName `
                                        -Path $GroupOU `
                                        -Description ("Users with access to: " +$LongName)`
                                        -ErrorAction SilentlyContinue `
                                        -ErrorVariable $TryError `                
            Write-host -BackgroundColor Black -ForegroundColor Green "AD Group Created:" $ShortName
            $CountGroups ++
            }
        #If it Failed
        catch{
            #Does it exist?
            try{ 
                Get-ADGroup -Identity $ShortName | out-null
                Write-Host -BackgroundColor Black -ForegroundColor Yellow "AD Group Already Exists: $ShortName"
                $CountExisting ++
                }
            #Still does not exist
            Catch{ Write-host -BackgroundColor Black -ForegroundColor Red "Failed to create:" $ShortName 
            $TryError}
        }
    }
}
#Create Building Blocks for Ivanti
    foreach($Printer in $Printers){
        #Get the printer properties
        $Name = $Printer.Name
        $Share = "\\"+$PrintServer +"\"+ $Name
        $Driver = $Printer.DriverName

        #Create the Group properties               
        if($Default -eq "Yes" -or $Default -eq "yes"){
            $Group = $ADGroupLead + $Printer.Name + $ADGroupEnd
        }else{ 
            $Group = $ADGroupLead + $Printer.Name
        }

        $GroupFQDN = $Domain + $Group

        #Get the SID
        $GroupSID = Get-ADGroup -Identity $Group
        $GroupSID = $GroupSID.SID | Select-Object AccountDomainSid -ExpandProperty Value

        #Create a New GUID
        $GUID = "{" +([guid]::NewGuid() | Select-Object GUID -ExpandProperty GUID) + "}"

        #If default is set 
        if($Default -eq "Yes" -or $Default -eq "yes"){
            $ExportFile = $ExportLocation + $Printer.Name + $ADGroupEnd + ".xml"
        }else{ 
            $ExportFile = $ExportLocation + $Printer.Name +".xml"
        }

        #Replace the values from the loaded template
        $Template = $Template.Replace("[Share]",$Share)
        $Template = $Template.Replace("[Driver]",$Driver)
        $Template = $Template.Replace("[Group]",$GroupFQDN)
        $Template = $Template.Replace("[GroupSID]",$GroupSID)
        $Template = $Template.Replace("[GUID]",$GUID)
        $Template = $Template.Replace("[Default]",$Default)

        #Write to new file
        $Template | Set-Content -Path $ExportFile #-ErrorAction SilentlyContinue
        Write-Host -BackgroundColor Black -ForegroundColor Green "Created or Modified file: $ExportFile"

        #Reload the Original Template
        $Template = Get-Content -Path $TemplateLocation -ErrorAction SilentlyContinue
        $ExportFile = ""

        #Count the changes you are making
        $CountFiles++
    }

#Get the amount of files created
    $Totalfiles = Get-ChildItem $ExportLocation | Measure-Object | %{$_.Count}

#Show what you have done
    Write-Host -BackgroundColor Black -ForegroundColor Gray "-------------------------------------------------"
    Write-Host -BackgroundColor Black -ForegroundColor Green "Created $CountGroups AD Groups under $GroupOU"
    Write-Host -BackgroundColor Black -ForegroundColor Yellow "$CountExisting AD Groups Already Existed"
    Write-Host -BackgroundColor Black -ForegroundColor Green "Tried to Create $CountFiles Files under $ExportLocation"
    Write-Host -BackgroundColor Black -ForegroundColor Green "Total Files: $Totalfiles "
    Write-Host -BackgroundColor Black -ForegroundColor Gray "-------------------------------------------------"
