#Disables Users with an end date that has passed.
#v1.0
#Creator: Nout Geens
#Warning: this has no Confirmation Check

#Get the Users
	$users = Search-ADAccount -AccountExpired -UsersOnly -ResultPageSize 2000 -resultSetSize $null| Select-Object SamAccountName -ExpandProperty SamAccountName
	
#foreach user
    foreach($user in $users){
        #Get it, Disable it
		Get-ADUser -Identity $user | Disable-ADAccount
	}