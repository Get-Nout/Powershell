<#
.SYNOPSIS
    Converts an Outlook contacts CSV export into individual vCard (.vcf) files.
.DESCRIPTION
    Reads a CSV of Outlook contacts (Dutch column headers) and writes one .vcf file per contact.
.NOTES
    Original Author: dmitrysotnikov
    Editor: Nout Geens
    Version: 2.0
.EXAMPLE
    Go to Outlook, Contacts > Ctrl-A > Open / Open & Export > Export to file > Comma Separated Values > save the CSV
    Out-vCard -CSVFile "c:\temp\list.csv" -OutPath "c:\temp\putthemhere\" -Delimiter ","
#>

#Info: Works only with the Dutch version of Outlook's export



function Out-vCard {
    param(
        [String]$CSVFile = "C:\temp\Contacten.CSV",
        [String]$OutPath = "C:\temp\",
        [String]$Delimiter = ','
    )

    #Import the data
    $Data = Import-Csv $CSVFile -Delimiter $Delimiter

    $i = 0

    #Loop the contacts in the data
    foreach($Contact in $Data){
        #Create a filename, Since not all values are filled properly, Create a custom name
        $Filename = "Contact-" + $i +".vcf"
        $FullFilename = $OutPath + $Filename

        #Dutch Version:
        New-Item -Path $FullFilename
        Add-Content -path $FullFilename "BEGIN:VCARD"
        Add-Content -path $FullFilename "VERSION:2.1"
        Add-Content -path $FullFilename ("N:" + $Contact.Achternaam+ ";" + $Contact.Voornaam)
        Add-Content -path $FullFilename ("FN:" + $Contact.Voornaam + " " + $Contact.Achternaam)
        Add-Content -path $FullFilename ("ORG:" + $Contact.Bedrijf)
        Add-Content -path $FullFilename ("TITLE:" + $Contact.Functie)
        Add-Content -path $FullFilename ("TEL;WORK;VOICE:" + $Contact.'Telefoon op werk')
        Add-Content -path $FullFilename ("TEL;HOME;VOICE:" + $Contact.'Telefoon thuis')
        Add-Content -path $FullFilename ("TEL;CELL;VOICE:" + $Contact.'Mobiele telefoon')
        Add-Content -path $FullFilename ("TEL;WORK;FAX:" + $Contact.'Fax op werk')
        Add-Content -path $FullFilename ("ADR;WORK;PREF:" + ";;" + $Contact.'Werkadres, straat' + ";" + $Contact.'Werkadres, postcode' + " " + $contact.'Werkadres, plaats' + "; ;;" + $Contact.'Land/regio (werk)')
        Add-Content -path $FullFilename ("URL;WORK:" + $Contact.Webpagina)
        Add-Content -path $FullFilename ("EMAIL;PREF;INTERNET:" + $Contact.'E-mailadres')
        Add-Content -path $FullFilename "END:VCARD"

        $i++
    }
}