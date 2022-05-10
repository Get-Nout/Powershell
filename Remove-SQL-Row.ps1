#Script to Backup rows, and delete it from the original table
#Version: 1.7
#Creator: Nout Geens & Karl Thijs (SQL Hero)
<#Changelog
    1.1: Added Variables instead of plain text code
    1.2: Updated Naming
    1.3: Made SURE checks
    1.4: Added Brackets to make it work again
    1.5: Made it loop
    1.6: Changed the Write-hosts' to make it match

#>

#Declaration
$CurrentUser = "WMSuser"
$SQLServer = "Server2.fabr.local" #use Server\Instance for named SQL instances!
$SQLDBName = "Fabrelac_WMS"
$SQLTable = "Pallets"
$SQLTableBackup = "palletsbackup"

#Get the Password
Write-host "Gebruikersnaam:"$CurrentUser
$Password = Read-Host "Password" -AsSecureString

#Connect to the SQL
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; User ID=$CurrentUser ; Password=$Password;Integrated Security=false"
$SqlConnection.open()

#Create the Commandset
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.Connection = $SqlConnection
$SqlCmd.CommandTimeout = 0

#Initiate the loop
$Continue = 1
while($Continue -eq 1){

    #Supply the pallet ID
    $PalletID = Read-Host "Geef het PalletID op"
    Write-Host -ForegroundColor Yellow "Bent u zeker dat u pallet"$PalletID "wilt wissen? "
    $Sure = Read-Host "(J/?N)"


    if($Sure -eq 'j' -or $Sure -eq 'J'){
        #Copy
        $CopyRow = "INSERT INTO [$SQLDBName].[dbo].[$SQLTableBackup]
                   ([PalletID]
                   ,[Code],[Status],[GoodsTypeID],[GoodsSizeID],[LastLoc],[NextLoc],[EndLoc],[OrgLoc],[Blocked],[CraneMissionID],[Prio],[CreateDate],[ModifiedDate]
                   ,[UserID],[ToRate],[ArticleID],[BatchId])
            select [PalletID],[Code],[Status],[GoodsTypeID],[GoodsSizeID],[LastLoc],[NextLoc],[EndLoc],[OrgLoc],[Blocked],[CraneMissionID]
                   ,[Prio],[CreateDate],[ModifiedDate],[UserID],[ToRate],[ArticleID],[BatchId]
            from dbo.$SQLTable 
            where Code = '$PalletID'"

        $SqlCmd.CommandText = $CopyRow
        $RowsCopied = $SqlCmd.ExecuteNonQuery()
        #Notify the user
        if($RowsCopied -eq 1){ Write-host -ForegroundColor Yellow "Pallet $PalletID is Gebackuped"}

        $DeleteRow = "Delete from dbo.$SQLTable where code = '$PalletID'"

        #If the copy went through
        if($RowsCopied -gt 0){
            $SqlCmd.CommandText = $DeleteRow
            $RowsDeleted = $SqlCmd.ExecuteNonQuery()

            #Notify the user
            if($RowsCopied -eq 1){ Write-host -ForegroundColor RED "Pallet $PalletID is verwijderd uit de Tabel."}

         #if the copy did not succeed   
         }else{ Write-Host -ForegroundColor Red "Er is iets mis gegaan, Kloppen de gegevens?"}
    }
    #Notify about the looping
    Write-Host

}