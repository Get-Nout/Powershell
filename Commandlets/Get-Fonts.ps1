#List installed Font Families
#Creator: Nout Geens

[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
$Fonts = (New-Object System.Drawing.Text.InstalledFontCollection).Families 
$Fonts | Format-Table -AutoSize
Write-Host "You have " -NoNewline ; Write-Host -f Yellow $Fonts.Count -NoNewline ; Write-Host " fonts installed."
