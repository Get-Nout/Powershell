<#
.SYNOPSIS
    Creates an Explorer-style HTML tree report of NTFS permissions and Active Directory group memberships.

.DESCRIPTION
    Recursively scans a folder tree, reads NTFS ACLs, resolves domain users/groups in Active Directory,
    expands AD group memberships, and exports:
      - NTFS permissions CSV
      - AD group memberships CSV
      - JSON
      - Clickable Explorer-style HTML report (always generated)

.REQUIREMENTS
    - Windows PowerShell 5.1+ or PowerShell 7+
    - RSAT ActiveDirectory module installed
    - Read permissions on the target file system path
    - Permission to query Active Directory

.EXAMPLE
    .\Export-NtfsPermissionReport.ps1 -Path "J:\JHD-Data" -OutputFolder "C:\Temp\NtfsAudit" -MaxDepth 5 -ExpandNestedGroups

.EXAMPLE
    .\Export-NtfsPermissionReport.ps1 -Path "\\server\share" -IncludeInherited -ExpandNestedGroups -OutputFolder ".\Report"

.NOTES
    Author: Nout Geens
#>

[CmdletBinding()]
param(
    # If omitted, a parameter picker window is shown instead of running headless.
    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path $_ })]
    [string]$Path,

    # Defaults to a folder next to this script, not the process's current
    # working directory (which is often System32 when launched via a
    # shortcut, scheduled task, or right-click "Run with PowerShell").
    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = (Join-Path $PSScriptRoot "NtfsPermissionReport"),

    [Parameter(Mandatory = $false)]
    [int]$MaxDepth = 10,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeInherited,

    [Parameter(Mandatory = $false)]
    [switch]$ExpandNestedGroups,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeFiles,

    [Parameter(Mandatory = $false)]
    [switch]$HtmlReport = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:IdentityCache = @{}
$script:GroupMemberCache = @{}
$script:Rows = New-Object System.Collections.Generic.List[object]
$script:MembershipRows = New-Object System.Collections.Generic.List[object]
$script:nodeId = 0
$script:RootPath = $null

function Initialize-Environment {
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        throw "ActiveDirectory PowerShell module not found. Install RSAT Active Directory tools first."
    }

    Import-Module ActiveDirectory -ErrorAction Stop

    if (-not (Test-Path $OutputFolder)) {
        New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
    }
}

function Resolve-Identity {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Identity
    )

    $cached = $script:IdentityCache[$Identity]
    if ($null -ne $cached) {
        return $cached
    }

    $result = [ordered]@{
        Identity          = $Identity
        Domain            = $null
        SamAccountName    = $null
        DistinguishedName = $null
        ObjectClass       = "Unknown"
        DisplayName       = $null
        Enabled           = $null
        FoundInAD         = $false
        LookupError       = $null
    }

    try {
        $namePart = $Identity

        if ($Identity -match "^([^\\]+)\\(.+)$") {
            $result.Domain = $Matches[1]
            $namePart = $Matches[2]
        }

        if ($Identity -match "^(BUILTIN|NT AUTHORITY|NT SERVICE|APPLICATION PACKAGE AUTHORITY)\\") {
            $result.ObjectClass = "BuiltInOrLocal"
            $script:IdentityCache[$Identity] = [pscustomobject]$result
            return $script:IdentityCache[$Identity]
        }

        $ldapFilterValue = $namePart.Replace("\", "\5c").Replace("*", "\2a").Replace("(", "\28").Replace(")", "\29")

        $adObject = Get-ADObject `
            -LDAPFilter "(|(sAMAccountName=$ldapFilterValue)(name=$ldapFilterValue)(userPrincipalName=$ldapFilterValue))" `
            -Properties sAMAccountName,displayName,distinguishedName,objectClass,enabled `
            -ErrorAction Stop |
            Select-Object -First 1

        if ($null -ne $adObject) {
            $result.SamAccountName = $adObject.sAMAccountName
            $result.DistinguishedName = $adObject.DistinguishedName
            $result.ObjectClass = $adObject.ObjectClass
            $result.DisplayName = $adObject.DisplayName
            $result.FoundInAD = $true

            if ($adObject.PSObject.Properties.Name -contains "Enabled") {
                $result.Enabled = $adObject.Enabled
            }
        }
    }
    catch {
        $result.LookupError = $_.Exception.Message
    }

    $script:IdentityCache[$Identity] = [pscustomobject]$result
    return $script:IdentityCache[$Identity]
}

function Get-GroupMembersSafe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$GroupIdentity,

        [Parameter(Mandatory = $false)]
        [int]$Level = 0,

        [Parameter(Mandatory = $false)]
        [string[]]$Visited = @()
    )

    $cachedMembers = $script:GroupMemberCache[$GroupIdentity]
    if ($null -ne $cachedMembers) {
        return $cachedMembers
    }

    $members = [System.Collections.Generic.List[object]]::new()

    if ($Visited -contains $GroupIdentity) {
        return @()
    }

    try {
        $groupMembers = Get-ADGroupMember -Identity $GroupIdentity -ErrorAction Stop

        foreach ($member in $groupMembers) {
            $memberRow = [pscustomobject]@{
                ParentGroup       = $GroupIdentity
                Level             = $Level
                MemberName        = $member.Name
                MemberSamAccount  = $member.SamAccountName
                MemberClass       = $member.ObjectClass
                DistinguishedName = $member.DistinguishedName
                Error             = $null
            }

            $members.Add($memberRow)

            if ($ExpandNestedGroups -and $member.ObjectClass -eq "group") {
                $nestedMembers = Get-GroupMembersSafe `
                    -GroupIdentity $member.DistinguishedName `
                    -Level ($Level + 1) `
                    -Visited ($Visited + $GroupIdentity)

                foreach ($nested in $nestedMembers) {
                    $members.Add($nested)
                }
            }
        }
    }
    catch {
        $members.Add([pscustomobject]@{
            ParentGroup       = $GroupIdentity
            Level             = $Level
            MemberName        = $null
            MemberSamAccount  = $null
            MemberClass       = "LookupError"
            DistinguishedName = $null
            Error             = $_.Exception.Message
        })
    }

    $script:GroupMemberCache[$GroupIdentity] = $members.ToArray()
    return $script:GroupMemberCache[$GroupIdentity]
}

function New-ReportRow {
    param(
        [string]$Path,
        [string]$Tree,
        [string]$ItemType,
        [int]$Depth,
        [string]$Identity = $null,
        [object]$Rights = $null,
        [object]$AccessType = $null,
        [object]$IsInherited = $null,
        [object]$InheritanceFlags = $null,
        [object]$PropagationFlags = $null,
        [string]$ObjectClass = "TreeNode",
        [string]$SamAccountName = $null,
        [string]$DisplayName = $null,
        [string]$DistinguishedName = $null,
        [string]$Error = $null
    )

    return [pscustomobject]@{
        Path              = $Path
        Tree              = $Tree
        ItemType          = $ItemType
        Depth             = $Depth
        Identity          = $Identity
        Rights            = $Rights
        AccessType        = $AccessType
        IsInherited       = $IsInherited
        InheritanceFlags  = $InheritanceFlags
        PropagationFlags  = $PropagationFlags
        ObjectClass       = $ObjectClass
        SamAccountName    = $SamAccountName
        DisplayName       = $DisplayName
        DistinguishedName = $DistinguishedName
        Error             = $Error
    }
}

function Add-AclRowsForPath {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileSystemInfo]$Item,

        [Parameter(Mandatory = $true)]
        [int]$Depth
    )

    $itemType = if ($Item.PSIsContainer) { "Directory" } else { "File" }
    $treeText = ("  " * $Depth) + "|- " + $Item.Name

    # This row guarantees that every folder/file appears in the HTML tree,
    # even when it has no explicit ACL entries because inherited permissions are excluded.
    $script:Rows.Add((New-ReportRow -Path $Item.FullName -Tree $treeText -ItemType $itemType -Depth $Depth -ObjectClass "TreeNode"))

    try {
        $acl = Get-Acl -LiteralPath $Item.FullName -ErrorAction Stop
    }
    catch {
        $script:Rows.Add((New-ReportRow -Path $Item.FullName -Tree $treeText -ItemType $itemType -Depth $Depth -ObjectClass "AclReadError" -Error $_.Exception.Message))
        return
    }

    foreach ($ace in $acl.Access) {
        if (-not $IncludeInherited -and $ace.IsInherited) {
            continue
        }

        $identity = $ace.IdentityReference.Value
        $resolved = Resolve-Identity -Identity $identity

        $script:Rows.Add((New-ReportRow -Path $Item.FullName -Tree $treeText -ItemType $itemType -Depth $Depth `
            -Identity $identity -Rights $ace.FileSystemRights -AccessType $ace.AccessControlType `
            -IsInherited $ace.IsInherited -InheritanceFlags $ace.InheritanceFlags -PropagationFlags $ace.PropagationFlags `
            -ObjectClass $resolved.ObjectClass -SamAccountName $resolved.SamAccountName -DisplayName $resolved.DisplayName `
            -DistinguishedName $resolved.DistinguishedName -Error $resolved.LookupError))

        if ($resolved.FoundInAD -and $resolved.ObjectClass -eq "group") {
            $members = Get-GroupMembersSafe -GroupIdentity $resolved.DistinguishedName

            foreach ($member in $members) {
                $script:MembershipRows.Add([pscustomobject]@{
                    PermissionPath     = $Item.FullName
                    PermissionIdentity = $identity
                    GroupDN            = $resolved.DistinguishedName
                    ParentGroup        = $member.ParentGroup
                    Level              = $member.Level
                    MemberName         = $member.MemberName
                    MemberSamAccount   = $member.MemberSamAccount
                    MemberClass        = $member.MemberClass
                    MemberDN           = $member.DistinguishedName
                    Error              = $member.Error
                })
            }
        }
    }
}

function Walk-Tree {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileSystemInfo]$Item,

        [Parameter(Mandatory = $true)]
        [int]$Depth
    )

    if ($Depth -gt $MaxDepth) {
        return
    }

    Write-Host (("  " * $Depth) + "|- " + $Item.Name)
    Add-AclRowsForPath -Item $Item -Depth $Depth

    if ($Item.PSIsContainer) {
        try {
            $children = Get-ChildItem -LiteralPath $Item.FullName -Force -ErrorAction Stop

            foreach ($child in $children) {
                if (-not $IncludeFiles -and -not $child.PSIsContainer) {
                    continue
                }

                Walk-Tree -Item $child -Depth ($Depth + 1)
            }
        }
        catch {
            $script:Rows.Add((New-ReportRow -Path $Item.FullName `
                -Tree (("  " * ($Depth + 1)) + "|- [ACCESS DENIED OR ENUMERATION ERROR]") `
                -ItemType "EnumerationError" -Depth ($Depth + 1) -ObjectClass "EnumerationError" `
                -Error $_.Exception.Message))
        }
    }
}

function ConvertTo-HtmlEncoded {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return ""
    }

    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Build-ExplorerHtmlReport {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HtmlPath
    )

    $nodes = @{}
    $membersByPathAndGroup = @{}

    foreach ($memberRow in $script:MembershipRows) {
        if ([string]::IsNullOrWhiteSpace($memberRow.PermissionPath) -or [string]::IsNullOrWhiteSpace($memberRow.PermissionIdentity)) {
            continue
        }

        $memberKey = "$($memberRow.PermissionPath)|$($memberRow.PermissionIdentity)"

        if (-not $membersByPathAndGroup.ContainsKey($memberKey)) {
            $membersByPathAndGroup[$memberKey] = [System.Collections.Generic.List[object]]::new()
        }

        $membersByPathAndGroup[$memberKey].Add($memberRow)
    }

    foreach ($row in $script:Rows) {
        if ([string]::IsNullOrWhiteSpace($row.Path)) {
            continue
        }

        if (-not $nodes.ContainsKey($row.Path)) {
            $nodes[$row.Path] = [ordered]@{
                Path        = $row.Path
                Name        = if ($row.Depth -eq 0) { $row.Path } else { Split-Path -Path $row.Path -Leaf }
                Depth       = $row.Depth
                ItemType    = $row.ItemType
                Parent      = Split-Path -Path $row.Path -Parent
                Permissions = [System.Collections.Generic.List[object]]::new()
                Children    = [System.Collections.Generic.List[string]]::new()
            }
        }

        if ($row.Identity) {
            $nodes[$row.Path].Permissions.Add($row)
        }
    }

    foreach ($key in @($nodes.Keys)) {
        $parent = $nodes[$key].Parent

        if ($parent -and $nodes.ContainsKey($parent) -and $key -ne $parent) {
            $nodes[$parent].Children.Add($key)
        }
    }

    # The root's full path was already resolved once in the main script body;
    # reuse it instead of hitting the filesystem again here.
    $rootPath = $script:RootPath

    if (-not $nodes.ContainsKey($rootPath)) {
        return
    }

    $script:nodeId = 0

    function Render-Node {
        param(
            [string]$NodePath,
            [System.Text.StringBuilder]$Builder
        )

        try {

        $node = $nodes[$NodePath]
        $currentId = "node-$script:nodeId"
        $script:nodeId++

        $safeName = ConvertTo-HtmlEncoded $node.Name
        $safePath = ConvertTo-HtmlEncoded $node.Path
        $node.Children.Sort()
        $children = $node.Children
        $hasChildren = $children.Count -gt 0
        $nodePermissions = $node.Permissions
        $hasPerms = $nodePermissions.Count -gt 0
        $hasExplicitPerms = $false
        foreach ($permissionCheck in $nodePermissions) {
            if ($null -ne $permissionCheck -and $permissionCheck.IsInherited -eq $false) {
                $hasExplicitPerms = $true
                break
            }
        }
        $explicitClass = if ($hasExplicitPerms) { " has-explicit" } else { " inherited-only" }

        $toggleClass = if ($hasChildren -or $hasPerms) { "toggle" } else { "toggle empty" }
        $folderIcon = if ($node.ItemType -eq "File") { "&#128196;" } elseif ($hasChildren) { "&#128193;" } else { "&#128194;" }
        $isRootNode = ($node.Depth -eq 0)
        $rowOpenClass = if ($isRootNode) { " open" } else { "" }
        $childrenClass = if ($isRootNode) { "node-children" } else { "node-children collapsed" }

        [void]$Builder.AppendLine("<li class='tree-node$explicitClass'>")
        [void]$Builder.AppendLine("  <div class='node-row$rowOpenClass' data-target='$currentId'>")
        [void]$Builder.AppendLine("    <span class='$toggleClass'>&#9654;</span>")
        [void]$Builder.AppendLine("    <span class='icon'>$folderIcon</span>")
        [void]$Builder.AppendLine("    <span class='node-name'>$safeName</span>")
        [void]$Builder.AppendLine("    <span class='node-path'>$safePath</span>")
        [void]$Builder.AppendLine("  </div>")
        [void]$Builder.AppendLine("  <div id='$currentId' class='$childrenClass'>")

        if ($hasPerms) {
            [void]$Builder.AppendLine("    <table class='permission-table'>")
            [void]$Builder.AppendLine("      <thead><tr><th>Identity</th><th>Rights</th><th>Type</th><th>Inherited</th><th>AD Object</th><th>Display Name</th><th>AD Group Members</th><th>Error</th></tr></thead>")
            [void]$Builder.AppendLine("      <tbody>")

            foreach ($perm in $nodePermissions) {
                $identity = ConvertTo-HtmlEncoded $perm.Identity
                $rights = ConvertTo-HtmlEncoded $perm.Rights
                $accessType = ConvertTo-HtmlEncoded $perm.AccessType
                $isInherited = ConvertTo-HtmlEncoded $perm.IsInherited
                $objectClass = ConvertTo-HtmlEncoded $perm.ObjectClass
                $displayName = ConvertTo-HtmlEncoded $perm.DisplayName
                $errorText = ConvertTo-HtmlEncoded $perm.Error
                $badgeClass = if ($perm.AccessType -eq "Deny") { "badge deny" } else { "badge allow" }
                $permissionRowClass = if ($perm.IsInherited -eq $true) { "inherited-permission" } else { "explicit-permission" }
                $memberKey = "$($node.Path)|$($perm.Identity)"
                $memberHtml = ""

                if ($membersByPathAndGroup.ContainsKey($memberKey)) {
                    $memberList = $membersByPathAndGroup[$memberKey]
                    $memberCount = $memberList.Count
                    $memberBuilder = New-Object System.Text.StringBuilder

                    [void]$memberBuilder.Append("<details class='member-details'>")
                    [void]$memberBuilder.Append("<summary>$memberCount member(s)</summary>")
                    [void]$memberBuilder.Append("<ul class='member-list'>")

                    foreach ($m in $memberList) {
                        $levelNumber = 0
                        if ($null -ne $m.Level) {
                            $levelNumber = [int]$m.Level
                        }

                        $indent = " " * ($levelNumber * 2)
                        $memberName = ConvertTo-HtmlEncoded $m.MemberName
                        $memberSam = ConvertTo-HtmlEncoded $m.MemberSamAccount
                        $memberClass = ConvertTo-HtmlEncoded $m.MemberClass
                        $memberError = ConvertTo-HtmlEncoded $m.Error

                        if ($levelNumber -gt 0) {
                            $nestedPrefix = "&#8627; "
                        }
                        else {
                            $nestedPrefix = ""
                        }

                        if (-not [string]::IsNullOrWhiteSpace($memberError)) {
                            $errorSuffix = " <span class='error'>($memberError)</span>"
                        }
                        else {
                            $errorSuffix = ""
                        }

                        [void]$memberBuilder.Append("<li><span class='member-indent'>$indent</span>$nestedPrefix<span class='member-name'>$memberName</span> <span class='member-meta'>[$memberClass] $memberSam</span>$errorSuffix</li>")
                    }

                    [void]$memberBuilder.Append("</ul>")
                    [void]$memberBuilder.Append("</details>")
                    $memberHtml = $memberBuilder.ToString()
                }

                [void]$Builder.AppendLine("        <tr class='$permissionRowClass'>")
                [void]$Builder.AppendLine("          <td class='identity'>$identity</td>")
                [void]$Builder.AppendLine("          <td>$rights</td>")
                [void]$Builder.AppendLine("          <td><span class='$badgeClass'>$accessType</span></td>")
                [void]$Builder.AppendLine("          <td>$isInherited</td>")
                [void]$Builder.AppendLine("          <td>$objectClass</td>")
                [void]$Builder.AppendLine("          <td>$displayName</td>")
                [void]$Builder.AppendLine("          <td class='member-cell'>$memberHtml</td>")
                [void]$Builder.AppendLine("          <td class='error'>$errorText</td>")
                [void]$Builder.AppendLine("        </tr>")
            }

            [void]$Builder.AppendLine("      </tbody>")
            [void]$Builder.AppendLine("    </table>")
        }

        if ($hasChildren) {
            [void]$Builder.AppendLine("    <ul class='tree-list'>")

            foreach ($child in $children) {
                Render-Node -NodePath $child -Builder $Builder
            }

            [void]$Builder.AppendLine("    </ul>")
        }

        [void]$Builder.AppendLine("  </div>")
        [void]$Builder.AppendLine("</li>")
        }
        catch {
            Write-Host "========== RENDER-NODE DEBUG ==========" -ForegroundColor Red
            Write-Host "NodePath: $NodePath" -ForegroundColor Yellow
            if ($null -ne $node) {
                Write-Host "Node name: $($node.Name)" -ForegroundColor Yellow
                Write-Host "Node type: $($node.ItemType)" -ForegroundColor Yellow
                Write-Host "Node depth: $($node.Depth)" -ForegroundColor Yellow
            }
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
            throw
        }
    }

    $generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $rootHtmlBuilder = New-Object System.Text.StringBuilder
    Render-Node -NodePath $rootPath -Builder $rootHtmlBuilder
    $rootHtml = $rootHtmlBuilder.ToString()
    $encodedRootPath = ConvertTo-HtmlEncoded $rootPath

    $htmlDocument = @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>NTFS Permission Explorer</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&family=Inter:wght@400;500;600&family=IBM+Plex+Mono:wght@400;500;600&display=swap');

:root {
  --ink: #111826;
  --panel: #161f30;
  --panel-2: #1c2740;
  --line: #2a3752;
  --amber: #f0a531;
  --amber-soft: #f0a53133;
  --teal: #3fc6bd;
  --teal-soft: #3fc6bd2b;
  --coral: #ef6f6c;
  --coral-soft: #ef6f6c2b;
  --cream: #f4efe4;
  --muted: #8b96ad;
}

* { box-sizing: border-box; }

body {
  margin: 0;
  background: radial-gradient(circle at 10% 0%, #1b2438 0%, var(--ink) 45%);
  color: var(--cream);
  font-family: 'Inter', "Segoe UI", Arial, sans-serif;
}

.app-header {
  padding: 28px 28px 18px;
  border-bottom: 1px solid var(--line);
}

.app-header .eyebrow {
  font-family: 'IBM Plex Mono', monospace;
  letter-spacing: .14em;
  text-transform: uppercase;
  font-size: 12px;
  color: var(--amber);
  margin-bottom: 8px;
}

.app-header h1 {
  margin: 0 0 8px 0;
  font-family: 'Space Grotesk', sans-serif;
  font-size: 28px;
  font-weight: 700;
  color: var(--cream);
}

.app-header h1 span { color: var(--muted); font-weight: 500; }

.app-header .meta {
  font-family: 'IBM Plex Mono', monospace;
  color: var(--muted);
  font-size: 12.5px;
}

.toolbar {
  display: flex;
  gap: 10px;
  align-items: center;
  padding: 14px 22px;
  background: var(--panel);
  border-bottom: 1px solid var(--line);
  position: sticky;
  top: 0;
  z-index: 5;
}

.toolbar button {
  font-family: 'IBM Plex Mono', monospace;
  font-size: 12px;
  padding: 8px 14px;
  border-radius: 20px;
  background: var(--panel-2);
  border: 1px solid var(--line);
  color: var(--muted);
  cursor: pointer;
  transition: all .15s;
  white-space: nowrap;
}

.toolbar button:hover { border-color: var(--amber); color: var(--cream); }
.toolbar button.active { background: var(--amber); color: #1a1200; border-color: var(--amber); font-weight: 600; }

#searchBox {
  min-width: 320px;
  flex: 1;
  background: var(--panel-2);
  border: 1px solid var(--line);
  color: var(--cream);
  padding: 10px 14px;
  border-radius: 10px;
  font-family: 'Inter', sans-serif;
  font-size: 13px;
}

#searchBox:focus { outline: none; border-color: var(--amber); }
#searchBox::placeholder { color: var(--muted); }

.report-shell { padding: 22px; }

.explorer-panel {
  background: linear-gradient(180deg, var(--panel-2), var(--panel));
  border: 1px solid var(--line);
  border-radius: 16px;
  padding: 16px;
}

.tree-list {
  list-style: none;
  margin: 0;
  padding-left: 22px;
  border-left: 1px dotted var(--line);
}

.explorer-panel > .tree-list {
  padding-left: 0;
  border-left: 0;
}

.tree-node { margin: 2px 0; }

.node-row {
  display: flex;
  align-items: center;
  gap: 6px;
  min-height: 30px;
  padding: 4px 10px;
  border-radius: 7px;
  cursor: pointer;
  user-select: none;
  white-space: nowrap;
  color: var(--cream);
}

.node-row:hover { background: var(--amber-soft); }

.toggle {
  width: 16px;
  display: inline-block;
  color: var(--muted);
  font-size: 11px;
  transition: transform .12s ease;
}

.toggle.empty { visibility: hidden; }
.node-row.open .toggle { transform: rotate(90deg); color: var(--amber); }
.icon { width: 22px; }
.node-name { font-family: 'Space Grotesk', sans-serif; font-weight: 600; }

.node-path {
  font-family: 'IBM Plex Mono', monospace;
  color: var(--muted);
  font-size: 11.5px;
  margin-left: 8px;
}

.node-children {
  margin-left: 20px;
  padding-left: 8px;
}

.collapsed { display: none; }

.permission-table {
  width: calc(100% - 18px);
  margin: 8px 0 12px 18px;
  border-collapse: collapse;
  font-size: 12px;
  background: var(--panel);
}

.permission-table th,
.permission-table td {
  border: 1px solid var(--line);
  padding: 6px 8px;
  text-align: left;
  vertical-align: top;
  color: var(--cream);
}

.permission-table th {
  background: var(--panel-2);
  color: var(--amber);
  font-family: 'IBM Plex Mono', monospace;
  text-transform: uppercase;
  letter-spacing: .04em;
  font-size: 10.5px;
  font-weight: 600;
  position: sticky;
  top: 58px;
}

.identity { font-family: 'IBM Plex Mono', monospace; color: var(--cream); }
.error { color: var(--coral); }

.badge {
  display: inline-block;
  padding: 2px 10px;
  border-radius: 999px;
  font-weight: 650;
  font-family: 'IBM Plex Mono', monospace;
  font-size: 11px;
}

.badge.allow { background: var(--teal-soft); color: var(--teal); }
.badge.deny { background: var(--coral-soft); color: var(--coral); }
.hidden-by-search { display: none; }

body.modified-only .tree-node.inherited-only:not(.has-explicit-descendant) {
  display: none;
}

body.modified-only .permission-table tbody tr.inherited-permission {
  display: none;
}

body.modified-only .permission-table:has(tbody tr.explicit-permission) tbody tr.explicit-permission {
  display: table-row;
}

.member-cell {
  min-width: 220px;
}

.member-details {
  display: none;
}

body.show-members .member-details {
  display: block;
}

.member-details summary {
  cursor: pointer;
  color: var(--amber);
  font-weight: 650;
  font-family: 'IBM Plex Mono', monospace;
  font-size: 11.5px;
}

.member-list {
  margin: 6px 0 0 0;
  padding-left: 16px;
  max-height: 260px;
  overflow: auto;
}

.member-list li {
  margin: 3px 0;
  line-height: 1.35;
  color: var(--cream);
}

.member-name {
  font-weight: 600;
}

.member-meta {
  color: var(--muted);
  font-size: 11px;
}

.member-indent {
  white-space: pre;
  font-family: 'IBM Plex Mono', monospace;
}
</style>
</head>
<body>
<header class="app-header">
  <div class="eyebrow">&#9679; NTFS Permissions &mdash; Read Only</div>
  <h1>Permission <span>Explorer</span></h1>
  <div class="meta">Root: $encodedRootPath &nbsp; | &nbsp; Generated: $generatedAt &nbsp; | &nbsp; Include inherited: $IncludeInherited &nbsp; | &nbsp; Nested groups: $ExpandNestedGroups</div>
</header>

<div class="toolbar">
  <button id="expandAllButton" type="button">Expand all</button>
  <button id="collapseAllButton" type="button">Collapse all</button>
  <button id="showMembersButton" type="button">Show AD members</button>
  <button id="modifiedOnlyButton" type="button">Show modified only</button>
  <input id="searchBox" type="search" placeholder="Search folders, identities, rights, AD names...">
</div>

<main class="report-shell">
  <section class="explorer-panel">
    <ul class="tree-list">
      $rootHtml
    </ul>
  </section>
</main>

<script>
function toggleNodeByRow(row) {
  const id = row.getAttribute('data-target');
  const el = document.getElementById(id);
  if (!el) return;
  el.classList.toggle('collapsed');
  row.classList.toggle('open', !el.classList.contains('collapsed'));
}

document.addEventListener('click', function(event) {
  const row = event.target.closest('.node-row');
  if (!row) return;
  toggleNodeByRow(row);
});

function expandAll() {
  document.querySelectorAll('.node-children').forEach(el => el.classList.remove('collapsed'));
  document.querySelectorAll('.node-row').forEach(el => el.classList.add('open'));
}

function collapseAll() {
  document.querySelectorAll('.node-children').forEach(el => el.classList.add('collapsed'));
  document.querySelectorAll('.node-row').forEach(el => el.classList.remove('open'));
}

function filterTree(query) {
  const q = query.toLowerCase().trim();
  const nodes = [...document.querySelectorAll('.tree-node')];

  if (!q) {
    nodes.forEach(n => n.classList.remove('hidden-by-search'));
    collapseAll();
    const first = document.querySelector('.node-row');
    if (first) toggleNodeByRow(first);
    return;
  }

  nodes.forEach(n => n.classList.add('hidden-by-search'));

  nodes.forEach(node => {
    const text = node.innerText.toLowerCase();

    if (text.includes(q)) {
      let current = node;

      while (current && current.classList) {
        if (current.classList.contains('tree-node')) {
          current.classList.remove('hidden-by-search');
          const childContainer = current.querySelector(':scope > .node-children');
          const row = current.querySelector(':scope > .node-row');
          if (childContainer) childContainer.classList.remove('collapsed');
          if (row) row.classList.add('open');
        }

        current = current.parentElement ? current.parentElement.closest('.tree-node') : null;
      }
    }
  });
}

document.getElementById('expandAllButton').addEventListener('click', expandAll);
document.getElementById('collapseAllButton').addEventListener('click', collapseAll);
document.getElementById('showMembersButton').addEventListener('click', function () {
  document.body.classList.toggle('show-members');
  const isOn = document.body.classList.contains('show-members');
  this.textContent = isOn ? 'Hide AD members' : 'Show AD members';
  this.classList.toggle('active', isOn);
});

document.getElementById('modifiedOnlyButton').addEventListener('click', function () {
  document.body.classList.toggle('modified-only');
  const isOn = document.body.classList.contains('modified-only');
  this.textContent = isOn ? 'Show all folders' : 'Show modified only';
  this.classList.toggle('active', isOn);
  if (isOn) {
    expandAll();
  }
});

document.querySelectorAll('.tree-node.has-explicit').forEach(function(node) {
  let parent = node.parentElement ? node.parentElement.closest('.tree-node') : null;
  while (parent) {
    parent.classList.add('has-explicit-descendant');
    parent = parent.parentElement ? parent.parentElement.closest('.tree-node') : null;
  }
});

document.getElementById('searchBox').addEventListener('input', function () {
  filterTree(this.value);
});
</script>
</body>
</html>
"@

    $htmlDocument | Set-Content -Path $HtmlPath -Encoding UTF8
}

function Export-Reports {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $aclCsv = Join-Path $OutputFolder "ntfs-permissions-$timestamp.csv"
    $membershipCsv = Join-Path $OutputFolder "ad-group-memberships-$timestamp.csv"
    $json = Join-Path $OutputFolder "ntfs-permissions-$timestamp.json"

    $script:Rows | Export-Csv -Path $aclCsv -NoTypeInformation -Encoding UTF8
    $script:MembershipRows | Export-Csv -Path $membershipCsv -NoTypeInformation -Encoding UTF8
    $script:Rows | ConvertTo-Json -Depth 6 | Set-Content -Path $json -Encoding UTF8

    Write-Host ""
    Write-Host "ACL report:        $aclCsv"
    Write-Host "Membership report: $membershipCsv"
    Write-Host "JSON report:       $json"

    # HTML report is always generated, regardless of -HtmlReport.
    $html = Join-Path $OutputFolder "ntfs-permissions-explorer-$timestamp.html"
    Build-ExplorerHtmlReport -HtmlPath $html
    Write-Host "Explorer HTML:     $html"
}

function Show-ParameterDialog {
    param(
        [string]$InitialPath,
        [string]$InitialOutputFolder,
        [int]$InitialMaxDepth,
        [bool]$InitialIncludeInherited,
        [bool]$InitialExpandNestedGroups,
        [bool]$InitialIncludeFiles
    )

    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase
    Add-Type -AssemblyName System.Windows.Forms

    [xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="NTFS Permission Report" Height="560" Width="640"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#F5F6F8" FontFamily="Segoe UI" FontSize="13">
  <DockPanel LastChildFill="True">
    <Border DockPanel.Dock="Top" Background="#111827" Padding="24,18">
      <StackPanel>
        <TextBlock Text="NTFS Permission Report" Foreground="White" FontSize="20" FontWeight="Bold"/>
        <TextBlock Text="Choose a folder and scan options" Foreground="#CBD5E1" FontSize="12" Margin="0,4,0,0"/>
      </StackPanel>
    </Border>

    <Border DockPanel.Dock="Bottom" Background="#F5F6F8" Padding="24,14" BorderThickness="0,1,0,0" BorderBrush="#D8DEE9">
      <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
        <Button x:Name="BtnCancel" Content="Cancel" Padding="16,8" Margin="0,0,10,0" Background="White" BorderBrush="#D8DEE9" BorderThickness="1"/>
        <Button x:Name="BtnRun" Content="Run Scan" Padding="18,8" Background="#1D4ED8" Foreground="White" FontWeight="SemiBold" BorderThickness="0"/>
      </StackPanel>
    </Border>

    <ScrollViewer VerticalScrollBarVisibility="Auto">
      <StackPanel Margin="24">
        <TextBlock Text="Folder to scan" FontWeight="SemiBold" Margin="0,0,0,4"/>
        <Grid Margin="0,0,0,16">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
          </Grid.ColumnDefinitions>
          <TextBox x:Name="TxtPath" Grid.Column="0" Padding="8" VerticalContentAlignment="Center"/>
          <Button x:Name="BtnBrowsePath" Grid.Column="1" Content="Browse..." Margin="8,0,0,0" Padding="14,8"/>
        </Grid>

        <TextBlock Text="Output folder" FontWeight="SemiBold" Margin="0,0,0,4"/>
        <Grid Margin="0,0,0,16">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
          </Grid.ColumnDefinitions>
          <TextBox x:Name="TxtOutputFolder" Grid.Column="0" Padding="8" VerticalContentAlignment="Center"/>
          <Button x:Name="BtnBrowseOutput" Grid.Column="1" Content="Browse..." Margin="8,0,0,0" Padding="14,8"/>
        </Grid>

        <StackPanel Orientation="Horizontal" Margin="0,0,0,18">
          <TextBlock Text="Max folder depth" FontWeight="SemiBold" VerticalAlignment="Center"/>
          <TextBox x:Name="TxtMaxDepth" Width="70" Margin="12,0,0,0" Padding="8" TextAlignment="Center"/>
        </StackPanel>

        <CheckBox x:Name="ChkIncludeInherited" Content="Include inherited permissions" Margin="0,0,0,12"/>
        <CheckBox x:Name="ChkExpandNestedGroups" Content="Expand nested AD group memberships" Margin="0,0,0,12"/>
        <CheckBox x:Name="ChkIncludeFiles" Content="Include files, not just folders" Margin="0,0,0,12"/>

        <TextBlock x:Name="TxtValidation" Foreground="#B91C1C" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0" Visibility="Collapsed"/>
      </StackPanel>
    </ScrollViewer>
  </DockPanel>
</Window>
'@

    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [Windows.Markup.XamlReader]::Load($reader)

    $txtPath = $window.FindName("TxtPath")
    $txtOutputFolder = $window.FindName("TxtOutputFolder")
    $txtMaxDepth = $window.FindName("TxtMaxDepth")
    $chkIncludeInherited = $window.FindName("ChkIncludeInherited")
    $chkExpandNestedGroups = $window.FindName("ChkExpandNestedGroups")
    $chkIncludeFiles = $window.FindName("ChkIncludeFiles")
    $txtValidation = $window.FindName("TxtValidation")
    $btnBrowsePath = $window.FindName("BtnBrowsePath")
    $btnBrowseOutput = $window.FindName("BtnBrowseOutput")
    $btnRun = $window.FindName("BtnRun")
    $btnCancel = $window.FindName("BtnCancel")

    $txtPath.Text = $InitialPath
    $txtOutputFolder.Text = $InitialOutputFolder
    $txtMaxDepth.Text = $InitialMaxDepth.ToString()
    $chkIncludeInherited.IsChecked = $InitialIncludeInherited
    $chkExpandNestedGroups.IsChecked = $InitialExpandNestedGroups
    $chkIncludeFiles.IsChecked = $InitialIncludeFiles

    $btnBrowsePath.Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Select the folder to scan"
        $dialog.ShowNewFolderButton = $false
        if (-not [string]::IsNullOrWhiteSpace($txtPath.Text) -and (Test-Path -LiteralPath $txtPath.Text)) {
            $dialog.SelectedPath = (Resolve-Path -LiteralPath $txtPath.Text).Path
        }
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtPath.Text = $dialog.SelectedPath
        }
    }.GetNewClosure())

    $btnBrowseOutput.Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Select the output folder for the reports"
        $dialog.ShowNewFolderButton = $true
        if (-not [string]::IsNullOrWhiteSpace($txtOutputFolder.Text) -and (Test-Path -LiteralPath $txtOutputFolder.Text)) {
            $dialog.SelectedPath = (Resolve-Path -LiteralPath $txtOutputFolder.Text).Path
        }
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtOutputFolder.Text = $dialog.SelectedPath
        }
    }.GetNewClosure())

    $btnCancel.Add_Click({
        $window.DialogResult = $false
    }.GetNewClosure())

    $btnRun.Add_Click({
        $validationErrors = New-Object System.Collections.Generic.List[string]

        if ([string]::IsNullOrWhiteSpace($txtPath.Text) -or -not (Test-Path -LiteralPath $txtPath.Text)) {
            $validationErrors.Add("Please choose a folder to scan that exists.")
        }

        if ([string]::IsNullOrWhiteSpace($txtOutputFolder.Text)) {
            $validationErrors.Add("Please choose an output folder.")
        }

        $parsedDepth = 0
        if (-not [int]::TryParse($txtMaxDepth.Text, [ref]$parsedDepth) -or $parsedDepth -lt 0) {
            $validationErrors.Add("Max folder depth must be a whole number of 0 or more.")
        }

        if ($validationErrors.Count -gt 0) {
            $txtValidation.Text = ($validationErrors -join " ")
            $txtValidation.Visibility = "Visible"
            return
        }

        $window.DialogResult = $true
    }.GetNewClosure())

    $dialogResult = $window.ShowDialog()

    if ($dialogResult -ne $true) {
        return $null
    }

    return [pscustomobject]@{
        Path               = $txtPath.Text
        OutputFolder       = $txtOutputFolder.Text
        MaxDepth           = [int]$txtMaxDepth.Text
        IncludeInherited   = [bool]$chkIncludeInherited.IsChecked
        ExpandNestedGroups = [bool]$chkExpandNestedGroups.IsChecked
        IncludeFiles       = [bool]$chkIncludeFiles.IsChecked
    }
}

if (-not $PSBoundParameters.ContainsKey('Path')) {
    if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
        Write-Host "The parameter picker needs an STA thread. Relaunch with: powershell -STA -File `"$PSCommandPath`"" -ForegroundColor Red
        exit 1
    }

    $selection = Show-ParameterDialog -InitialPath $Path -InitialOutputFolder $OutputFolder -InitialMaxDepth $MaxDepth `
        -InitialIncludeInherited $IncludeInherited -InitialExpandNestedGroups $ExpandNestedGroups -InitialIncludeFiles $IncludeFiles

    if ($null -eq $selection) {
        Write-Host "Cancelled - no folder was selected." -ForegroundColor Yellow
        exit
    }

    $Path = $selection.Path
    $OutputFolder = $selection.OutputFolder
    $MaxDepth = $selection.MaxDepth
    $IncludeInherited = [switch]$selection.IncludeInherited
    $ExpandNestedGroups = [switch]$selection.ExpandNestedGroups
    $IncludeFiles = [switch]$selection.IncludeFiles
}

try {
    Initialize-Environment

    $rootItem = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    $script:RootPath = $rootItem.FullName

    Write-Host "Scanning: $($rootItem.FullName)"
    Write-Host "MaxDepth: $MaxDepth"
    Write-Host "IncludeInherited: $IncludeInherited"
    Write-Host "ExpandNestedGroups: $ExpandNestedGroups"
    Write-Host "IncludeFiles: $IncludeFiles"
    Write-Host ""

    Walk-Tree -Item $rootItem -Depth 0
    Export-Reports
}
catch {
    Write-Host "========== FULL ERROR ==========" -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
    throw
}
