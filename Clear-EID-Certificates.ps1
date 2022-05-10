
	$Folder = "Cert:\CurrentUser\My\"
	$SubjectFilter = "SERIALNUMBER*"
	$Exclusion = "*G=firstname, SN=lastname*"

	foreach($Cert in (Get-childitem $Folder | Where-Object {($_.Subject -NotLike $Exclusion) -and ($_.Subject -Like $SubjectFilter)})){
		Write-Host "Removing File: " $Cert.Subject.Substring(($cert.Subject.IndexOf(",") +2),($Cert.Subject.length - $cert.Subject.IndexOf(",") -2))
		Remove-Item -Path $Cert.PSPath
	}

