#Script to report the current GPO's in your domain
#Creator: Nout Geens
#Version: 1.0
<#Changelog
    1.0    Created
#>

#Imports
    Import-Module grouppolicy 

#Set the domain to search for GPOs 
    $DomainName = $env:USERDNSDOMAIN

#Clear Values
    $GPO = "";$GPOPerm =""; $GPOs = @(); $DisabledGPOs = @();
 
#Find GPOs in the current domain 
    Write-Host "Getting All GPO's..."
    $GPOs = Get-GPO -all -Domain $DomainName | Select-Object * | Sort-Object DisplayName

#Get the disabled Gpo's
    $DisabledGPOs = $GPOs| Where-Object GpoStatus -EQ AllSettingsDisabled

#Clear more values (Seprated for testing perposes)
    $GPOObjects =@(); $GPOObjects0 =@(); $GPOObjects1 =@(); $GPOObjectsAuth1 =@();; $GPOObjectsAuth =@();
    $GPOUserObjects =@(); $GPOUserObjects0 =@(); $GPOUserObjects1 =@(); $GPOUserObjectsAuth1 =@();; $GPOUserObjectsAuth =@();
    $GPOCompObjects =@(); $GPOCompObjects0 =@(); $GPOCompObjects1 =@(); $GPOCompObjectsAuth1 =@();; $GPOCompObjectsAuth =@();
    $GPOUserObjectSetEmpty=@();$GPOCompObjectSetEmpty=@();

#region mainloop
    foreach($GPO in $GPOs){
        #Get the GPO Permission, check only the people it applies to
        $GPOPerm = Get-GPPermission -Name $GPO.DisplayName -All |Where-Object Permission -eq "GpoApply"

        #Add the users to the GPO object as a property called "AppliesTo"
        $GPO |Add-Member -NotePropertyName AppliesTo -NotePropertyValue $GPOPerm.Trustee.Name
        Write-Host -f Yellow $GPO.DisplayName -No;Write-Host " has " -No; Write-Host -f Yellow ($GPO.AppliesTo).count -No;Write-Host " User, Computer or Group it is applied to."
       
        #region Create User & Computer Settings: Empty or not
        [XML]$xml = Get-GPOReport -Name $GPO.DisplayName -ReportType xml

            #region Check the user gpo count, if 3, it is empty
            $GPOUserSet = $XML.GPO.User 
            $GPOUserSetCount = ($GPOUserSet | Get-Member -MemberType Property).count

            if(($GPOUserSetCount -eq 3) -and ($GPO.GpoStatus -ne "ComputerSettingsDisabled") -and ($GPO.GpoStatus -ne "AllSettingsDisabled")){ #Create the property
                $GPO |Add-Member -NotePropertyName UserSettingsEmpty -NotePropertyValue $True
                $GPOUserObjectSetEmpty += $GPO
            }else{ 
                $GPO |Add-Member -NotePropertyName UserSettingsEmpty -NotePropertyValue $False
            }
            #endregion

            #region Check the comp gpo count, if 3, it is empty
            $GPOCompSet = $XML.GPO.Computer
            $GPOCompSetCount = ($GPOCompSet | Get-Member -MemberType Property).count

            if(($GPOCompSetCount -eq 3 ) -and ($GPO.GpoStatus -ne "ComputerSettingsDisabled") -and ($GPO.GpoStatus -ne "AllSettingsDisabled")){
                $GPO |Add-Member -NotePropertyName ComputerSettingsEmpty -NotePropertyValue $True
                $GPOCompObjectSetEmpty += $GPO
            }else{
                $GPO |Add-Member -NotePropertyName ComputerSettingsEmpty -NotePropertyValue $False
            }
            #endregion

        #endregion

        
        #region Add the edited objects into another Array
            #region Loop for Applies To: Everything
                if(($GPO.AppliesTo).count -eq 0){
                    $GPOObjects0 += $GPO
                }elseif(($GPO.AppliesTo).count -eq 1){
                    #Check for Authenticated users
                    if($GPO.AppliesTo -eq "Authenticated Users"){ $GPOObjectsAuth1  += $GPO }    
                    $GPOObjects1 += $GPO
                }else{
                    if($GPO.AppliesTo -eq "Authenticated Users"){ $GPOObjectsAuth  += $GPO }    
                    $GPOObjects += $GPO
                }#endregion Everything

            #region Loop for Applies To: Computer
                if($GPO.GpoStatus -eq "UserSettingsDisabled"){
                    if(($GPO.AppliesTo).count -eq 0){
                        $GPOCompObjects0 += $GPO
                    }elseif(($GPO.AppliesTo).count -eq 1){
                        #Check for Authenticated users
                        if($GPO.AppliesTo -eq "Authenticated Users"){ $GPOCompObjectsAuth1  += $GPO }    
                        $GPOCompObjects1 += $GPO
                    }else{
                        if($GPO.AppliesTo -eq "Authenticated Users"){ $GPOCompObjectsAuth  += $GPO }    
                        $GPOCompObjects += $GPO
                    }     
                      
                }#endregion Computer

            #region Loop for Applies To: Users
                if($GPO.GpoStatus -eq "ComputerSettingsDisabled"){
                    if(($GPO.AppliesTo).count -eq 0){
                        $GPOUserObjects0 += $GPO
                    }elseif(($GPO.AppliesTo).count -eq 1){
                        #Check for Authenticated users
                        if($GPO.AppliesTo -eq "Authenticated Users"){ $GPOUserObjectsAuth1  += $GPO }    
                        $GPOUserObjects1 += $GPO
                    }else{
                        if($GPO.AppliesTo -eq "Authenticated Users"){ $GPOUserObjectsAuth  += $GPO }    
                        $GPOUserObjects += $GPO
                    }    
                }#endregion User

            #endregion Adding to array
        
        

    } #endregion Mainloop

#region Reporting
    Write-Host "--------------------------------------------------------------"
    Write-Host "Found " -No; Write-Host -f Yellow $GPOs.Count -No; Write-Host " GPOs in the domain " -No; Write-Host -f Yellow $DomainName 
    Write-Host "--------------------------------------------------------------"
    Write-Host "   All Policies:"
    Write-Host "   ------------------"
    Write-Host "    > " -No; Write-Host -f Yellow $DisabledGPOs.Count -No; Write-Host " are completely disabled. "
    Write-Host "    > " -No; Write-Host -f Yellow $GPOObjects0.Count -No; Write-Host " have no groups they apply to. "
    Write-Host "    > " -No; Write-Host -f Yellow $GPOObjects1.Count -No; Write-Host " have 1 groups they apply to."
    Write-Host "       > " -No; Write-Host -f Yellow $GPOObjectsAuth1.Count -No; Write-Host " of these have the group. 'Authenticated users' "
    Write-Host "    > " -No; Write-Host -f Yellow $GPOObjects.Count -No; Write-Host " have multiple groups they apply to. "
    Write-Host "       > " -No; Write-Host -f Yellow $GPOObjectsAuth.Count -No; Write-Host " of these have the group 'Authenticated users'. "
    Write-Host "   ------------------"
    Write-Host "   Computer Policies:"
    Write-Host "   ------------------"
    Write-Host "    > " -No; Write-Host -f Yellow $GPOCompObjects0.Count -No; Write-Host " have no groups they apply to. "
    Write-Host "    > " -No; Write-Host -f Yellow $GPOCompObjects1.Count -No; Write-Host " have 1 groups they apply to. "
    Write-Host "       > " -No; Write-Host -f Yellow $GPOCompObjectsAuth1.Count -No; Write-Host " of these have the group 'Authenticated users'. "
    Write-Host "    > " -No; Write-Host -f Yellow $GPCompOObjects.Count -No; Write-Host " have multiple groups they apply to. "
    Write-Host "       > " -No; Write-Host -f Yellow $GPOCompObjectsAuth.Count -No; Write-Host " of these have the group 'Authenticated users'. "
    Write-Host "    > " -No; Write-Host -f Red $GPOCompObjectSetEmpty.Count -No; Write-Host " don't have computer settings, yet have computer settings enabled."
    Write-Host "   ------------------"
    Write-Host "   User Policies:"
    Write-Host "   ------------------"
    Write-Host "    > " -No; Write-Host -f Yellow $GPOUserObjects0.Count -No; Write-Host " have no groups they apply to."
    Write-Host "    > " -No; Write-Host -f Yellow $GPOUserObjects1.Count -No; Write-Host " have 1 groups they apply to."
    Write-Host "       > " -No; Write-Host -f Yellow $GPOUserObjectsAuth1.Count -No; Write-Host " of these have the group 'Authenticated users'."
    Write-Host "    > " -No; Write-Host -f Yellow $GPOUserObjects.Count -No; Write-Host " have multiple groups they apply to."
    Write-Host "       > " -No; Write-Host -f Yellow $GPOUserObjectsAuth.Count -No; Write-Host " of these have the group 'Authenticated users'. "
    Write-Host "    > " -No; Write-Host -f Red $GPOUserObjectSetEmpty.Count -No; Write-Host " don't have user settings, yet have user settings enabled."
    Write-Host "   ------------------"
    Write-Host "--------------------------------------------------------------"
    
#endregion
