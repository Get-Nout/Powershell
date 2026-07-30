<#
.SYNOPSIS
    Disables AD user accounts whose account expiration date has passed.
.DESCRIPTION
    Finds every expired AD account and disables it.
.NOTES
    Author: Nout Geens
    Version: 1.0
    Warning: this has no confirmation check - review the account list before running in production.
#>

#Get the Users
	$users = Search-ADAccount -AccountExpired -UsersOnly -ResultPageSize 2000 -resultSetSize $null| Select-Object SamAccountName -ExpandProperty SamAccountName
	
#foreach user
    foreach($user in $users){
        #Get it, Disable it
		Get-ADUser -Identity $user | Disable-ADAccount
	}