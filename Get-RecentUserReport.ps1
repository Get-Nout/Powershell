$ADGroup = "Users-nout-CXA"
$LatestLogonMonths = 3 #months
$ExportLocation = "c:\temp\"
$CustomerName = "nout"

#Get the users
$Users = Get-ADGroupMember $ADGroup -Recursive | Select-Object SamAccountName -ExpandProperty SamAccountName

#Get today, x months ago
$LatestLogonDate = (Get-Date).AddMonths(-($LatestLogonMonths))

#Reset previous values, start the loop
$ActiveUsers = @(); $InactiveUsers = @();

foreach($User in $Users){
    #Get more properties of the users
    $User = Get-ADUser -Identity $User -Properties LastLogonDate, Enabled | Select-Object Name, SamAccountName, LastLogonDate, Enabled

    #Check if they have logged in recently
    if($User.LastLogonDate -gt $LatestLogonDate){
           Write-Host $user.Name " has recently logged on"
           $ActiveUsers += $User
    }else{      
           Write-Host $user.Name  -f Red " has not recently logged on"
           $InactiveUsers += $User
    }#End check
}

#Creating 3 files
    #Active Users
        $ActiveFile = $ExportLocation + $CustomerName + "-ActiveUsers-" + (Get-date -format "yyyy-MM-dd.HH-mm") +".csv"
        $ActiveUsers | Sort-Object LastLogonDate | Export-Csv $ActiveFile -Force -NoTypeInformation

    #Inactive Users
        $InactiveFile = $ExportLocation + $CustomerName + "-InactiveUsers-" + (Get-date -format "yyyy-MM-dd.HH-mm") +".csv"
        $InactiveUsers | Sort-Object LastLogonDate | Export-Csv $InactiveFile -Force -NoTypeInformation

    #Summary
        $SummaryFile = $ExportLocation + $CustomerName + "-Summary-" + (Get-date -format "yyyy-MM-dd.HH-mm") +".txt"

        $Summary =@()

        $Summary += "This script was run for users logged in since " + $LatestLogonDate +" ("+$LatestLogonMonths +" months)"
        $Summary += "The users were a member of " +$ADGroup
        $Summary += "There are " + $ActiveUsers.Count + " active users, of which " + (($ActiveUsers | Where-Object Enabled -EQ $false) | Measure-Object ).Count + " is/are disabled. `n"
        $Summary += "There are " + $InactiveUsers.Count + " inactive users, of which " + (($InactiveUsers | Where-Object Enabled -EQ $false) | Measure-Object ).Count + " is/are disabled. `n"

        $Summary | Out-File $SummaryFile -Force
