#Set wallpaper
#declaration
    $Server = "RDSITH003"
    $Username = "geert"
    $FilePath = 'C:\windows\oei.png'

    $Testrun = $true #set to false to run it for real

#PS into the server, take a nap
    Enter-PSSession -ComputerName $Server
    Start-Sleep -Seconds 1

    #Get all the user SIDs
        $SIDs = Get-childitem 'Registry::HKEY_USERS\' `            | Where-Object {($_.Name -NotLike "*_Classes") -and ($_.Name -NotLike "*_Default") -and ($_.Name.Length -gt 20)} `            | Select-Object Name -ExpandProperty Name

        $Done = $false

        #Filter the users for the one we need
        foreach($SID in $SIDs){
                #reset the Querry
                $InitialQuerry = $null

                Write-Host "Checking $SID"
                Write-Host -f Gray "  If you get a reg error next, it's the wrong user this time.."
                #Import the data for the querry
                $InitialQuerry = (reg query (($SID+ '\Volatile Environment')))

                #Check if it is empty
                if($InitialQuerry -ne $null){
                    #Offer souls to the demonlord in exchange for the username
                    $InitialQuerry = [String]$InitialQuerry
                    $InitialQuerry = $InitialQuerry.Substring($InitialQuerry.IndexOf(" USERNAME") +19,$InitialQuerry.Length - $InitialQuerry.IndexOf(" USERNAME") -19)
                    $InitialQuerry = $InitialQuerry.Substring(0,$InitialQuerry.IndexOf("USERPROFILE"))
                    $InitialQuerry = $InitialQuerry.TrimStart()
                    $SIDUsername  = $InitialQuerry.TrimEnd()

                    Write-Host -ForegroundColor Yellow "  Success, we found a user: $SIDUsername !"

                    if($SIDUsername -like $Username){
                        Write-Host -f Green "  $SIDUsername is the one you were looking for!"
                        #Create the path to the regkey
                            $path = 'Registry::' + $SID + '\Control Panel\Desktop\'

                        #Check the current wallpaper
                            $Wallpaper = Get-ItemProperty -path $path -name Wallpaper | Select-Object WallPaper -ExpandProperty Wallpaper
                            Write-host -ForegroundColor Green "  Found Wallpaper: $Wallpaper"

                        #Set the premium wallpaper
                            Write-Host -ForegroundColor Green "  Setting wallpaper..."
                            if($testrun = $false){Set-ItemProperty -path $path -name Wallpaper -value $FilePath}
                            $Wallpaper = Get-ItemProperty -path $path -name Wallpaper | Select-Object WallPaper -ExpandProperty Wallpaper
                            Write-host -ForegroundColor Green "  New Wallpaper: $Wallpaper"

                        #Try running User parameter dll's to reload the desktop (doesn't work all the time)
                            rundll32.exe user32.dll UpdatePerUserSystemParameters
                    }else{
                        Write-Host -f Gray "  This is not the droid you were looking for..."
                    }
                }#Endif Query success
            
        }  

#Exit the session
    Get-PSSession | Remove-PSSession