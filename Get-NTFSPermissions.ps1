#Function to get NTFS Rights
#Creator: BHARAT SUNEJA
#https://exchangepedia.com/2017/11/get-file-or-folder-permissions-using-powershell.html

  function Get-NTFSPermissions ($Object) {
  (get-acl $Object).access | select `
		@{Label="Identity";Expression={$_.IdentityReference}}, `
		@{Label="Right";Expression={$_.FileSystemRights}}, `
		@{Label="Access";Expression={$_.AccessControlType}}, `
		@{Label="Inherited";Expression={$_.IsInherited}}, `
		@{Label="Inheritance Flags";Expression={$_.InheritanceFlags}}, `
		@{Label="Propagation Flags";Expression={$_.PropagationFlags}} | ft -auto
		}

#Example:  Get-NTFSPermissions -Object "\\Nout.local\Data$\Production\Stage1\DWG*"
