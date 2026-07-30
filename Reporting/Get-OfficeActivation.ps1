#Creator: Nout Geens
Get-CimInstance SoftwareLicensingProduct| where {$_.name -like "*office*"}|select name,licensestatus
