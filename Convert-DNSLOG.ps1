#Convert-DNSLOG
#Niet af
#Get Content
    $Content = Get-Content -Path "\\SRVITH013\techdata`$\Scripts\DUMP\DNSLOG.txt"

#Remove the Header (30 lines)
    $Content | Select-Object -Last (($Content | Measure-Object).Count - 30)

#Replace the Dates with a single number
    $Content.Replace(" 1/" , " 01/")
    $Content.Replace(" 2/" , " 02/")
    $Content.Replace(" 3/" , " 03/")
    $Content.Replace(" 4/" , " 04/")
    $Content.Replace(" 5/" , " 05/")
    $Content.Replace(" 6/" , " 06/")
    $Content.Replace(" 7/" , " 07/")
    $Content.Replace(" 8/" , " 08/")
    $Content.Replace(" 9/" , " 09/")

#Replace the Hours with a single number
    $Content.Replace(" 0:" , " 00:")
    $Content.Replace(" 1:" , " 01:")
    $Content.Replace(" 2:" , " 02:")
    $Content.Replace(" 3:" , " 03:")
    $Content.Replace(" 4:" , " 04:")
    $Content.Replace(" 5:" , " 05:")
    $Content.Replace(" 6:" , " 06:")
    $Content.Replace(" 7:" , " 07:")
    $Content.Replace(" 8:" , " 08:")
    $Content.Replace(" 9:" , " 09:")

#Remove the Empty Rows
    foreach($Row in $Content){
        if($Row -ne ""){
            Write-Host "Empty line"

            }
    }