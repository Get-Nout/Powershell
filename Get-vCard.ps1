# Create a vCard to import on mobile devices
# V2.0
# Creator: Nout
<# Info
    Creates vCards from AD Users    
#>

#Importing modules
    Import-Module ActiveDirectory

#Declaration
    $Group = "users-noutcorp"
    $Company = "noutcorp"
    $Website = "https://www.nootnoot.be"
    $vCardPath = "C:\temp\vCards" 

#Get The users
    $Users = Get-ADGroupMember $Group

#Today is the day
    $date = get-date -UFormat "%Y%m%d"
    $datetext = -join("REV:",$date)

#One for all, all for one
ForEach ($user in $Users){ 
    #Name
    $FullName = "FN:" + $($user.Name)

    $Givenname = get-ADUser -identity $($user) -Properties givenname|Select-Object givenname -ExpandProperty givenname
    $Surname = get-ADUser -identity $($user) -Properties surname|Select-Object surname -ExpandProperty surname
    $Name = -join("N;LANGUAGE=nl-be:",$Surname,$Givenname)

    #Organisation
    $Organisation = "ORG:" +  $Company
    $title =  Get-ADUser -identity $($user) -Properties title|Select-Object title -ExpandProperty title
    $titleText = -join("TITLE:",$title)
    
    #Address
    $streetaddress = Get-ADUser -identity $($user) -Properties streetaddress|Select-Object streetaddress -ExpandProperty streetaddress
    $post = Get-ADUser -identity $($user) -Properties postalcode |Select-Object postalcode -ExpandProperty postalcode
    $city =  Get-ADUser -identity $($user) -Properties city |Select-Object city -ExpandProperty city
    $country = "Belgium" #Get-ADUser -identity $($user) -Properties country |ft country -HideTableHeaders|Out-String
    
    $addresstext = -join("ADR;WORK;PREF:",$streetadress," ",$post," ",$city," ",$country)

    #Mobile Phone
    $mobile = Get-ADUser -identity $($user) -Properties mobile|Select-Object mobile -ExpandProperty mobile
    $mobiletext = -join("TEL;CELL;VOICE:",$mobile)

    #E-mail
    $email = Get-ADUser -identity $($user) -Properties emailAddress|Select-Object emailAddress -ExpandProperty emailAddress
    $emailtext = -join("EMAIL;PREF;INTERNET:",$email)

    #V-card Creation
    $vCardFile = -join($Givenname,$Surname,".vcf")
    $vCardName = $vCardPath + $vCardFile

    #Test to see if vcard file already exists
    $outputvCard = Test-Path $vCardName 
        If (!$outputvCard){
         #if not then create the file
         $outputvcard = New-Item -Path $vCardName -ItemType Folder -Force
        }    

    #Adding it to the vcard 
    Add-Content -Path $vCardPath -Value "BEGIN:VCARD"
    Add-Content -Path $vCardPath -Value "VERSION:2.1"
    Add-Content -Path $vCardPath -Value $Name
    Add-Content -Path $vCardPath -Value $FullName
    Add-Content -Path $vCardPath -Value $Organisation
    Add-Content -Path $vCardPath -Value $titleText
    Add-Content -Path $vCardPath -Value $mobiletext
    Add-Content -Path $vCardPath -Value $addresstext 
    Add-Content -Path $vCardPath -Value $Website
    Add-Content -Path $vCardPath -Value $emailtext
    Add-Content -Path $vCardPath -Value $datetext
    Add-Content -Path $vCardPath -Value "END:VCARD"
     }

