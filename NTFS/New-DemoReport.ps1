<#
.SYNOPSIS
    Builds demo-report.html - a live example of Export-NtfsPermissionReport.ps1's
    HTML output, using synthetic sample data.

.DESCRIPTION
    Extracts the rendering functions straight from Export-NtfsPermissionReport.ps1
    (so the demo can never drift from what the real script actually produces) and
    feeds them a small made-up "Contoso" folder tree instead of a real scan. Real
    customer data never goes into this repo - this is what lets the demo live on
    GitHub Pages safely.

.NOTES
    Author: Nout Geens
#>

$ErrorActionPreference = "Stop"
$scriptPath = Join-Path $PSScriptRoot "Export-NtfsPermissionReport.ps1"
$scriptText = Get-Content -Raw $scriptPath

function Get-FunctionSource {
    param([string]$Text, [string]$Name)

    $startIdx = $Text.IndexOf("function $Name {")
    if ($startIdx -lt 0) { throw "Could not find function $Name in $scriptPath" }

    $depth = 0
    $braceStart = $Text.IndexOf('{', $startIdx)
    for ($j = $braceStart; $j -lt $Text.Length; $j++) {
        if ($Text[$j] -eq '{') { $depth++ }
        elseif ($Text[$j] -eq '}') {
            $depth--
            if ($depth -eq 0) {
                return $Text.Substring($startIdx, ($j - $startIdx + 1))
            }
        }
    }
    throw "Unbalanced braces extracting $Name"
}

Invoke-Expression (Get-FunctionSource $scriptText "ConvertTo-HtmlEncoded")
Invoke-Expression (Get-FunctionSource $scriptText "Build-ExplorerHtmlReport")

# ---- Synthetic "Contoso" sample data - no real customer info ----
$script:RootPath = "D:\Shares"
$script:nodeId = 0
$IncludeInherited = $false
$ExpandNestedGroups = $true

$script:Rows = [System.Collections.Generic.List[object]]::new()
$script:MembershipRows = [System.Collections.Generic.List[object]]::new()

function Add-DemoRow {
    param($Path, $Depth, $ItemType, $Identity = $null, $Rights = $null, $AccessType = $null, $IsInherited = $null, $ObjectClass = "TreeNode")
    $script:Rows.Add([pscustomobject]@{
        Path = $Path; Depth = $Depth; ItemType = $ItemType
        Identity = $Identity; Rights = $Rights; AccessType = $AccessType
        IsInherited = $IsInherited; ObjectClass = $ObjectClass
    })
}

# Root
Add-DemoRow "D:\Shares" 0 "Directory"
Add-DemoRow "D:\Shares" 0 "Directory" "Everyone" "ReadAndExecute, Synchronize" "Allow" $false "Unknown"
Add-DemoRow "D:\Shares" 0 "Directory" "BUILTIN\Administrators" "FullControl" "Allow" $false "BuiltInOrLocal"

# Finance (has an explicit group ACE with nested membership, plus a Deny entry)
Add-DemoRow "D:\Shares\Finance" 1 "Directory"
Add-DemoRow "D:\Shares\Finance" 1 "Directory" "CONTOSO\Finance-Team" "Modify, Synchronize" "Allow" $false "group"
Add-DemoRow "D:\Shares\Finance" 1 "Directory" "CONTOSO\Contractors" "Modify, Synchronize" "Deny" $false "group"

Add-DemoRow "D:\Shares\Finance\Payroll" 2 "Directory"
Add-DemoRow "D:\Shares\Finance\Payroll" 2 "Directory" "CONTOSO\Payroll-Team" "FullControl" "Allow" $false "group"

Add-DemoRow "D:\Shares\Finance\Budgets2026.xlsx" 2 "File"
Add-DemoRow "D:\Shares\Finance\Budgets2026.xlsx" 2 "File" "CONTOSO\Finance-Team" "Modify, Synchronize" "Allow" $true "group"

# HR (inherited-only leaf, to show the "toggle empty" / inherited-only styling)
Add-DemoRow "D:\Shares\HR" 1 "Directory"
Add-DemoRow "D:\Shares\HR" 1 "Directory" "CONTOSO\HR-Team" "ReadAndExecute, Synchronize" "Allow" $false "group"

Add-DemoRow "D:\Shares\HR\Archive" 2 "Directory"

# IT
Add-DemoRow "D:\Shares\IT" 1 "Directory"
Add-DemoRow "D:\Shares\IT" 1 "Directory" "CONTOSO\IT-Team" "FullControl" "Allow" $false "group"
Add-DemoRow "D:\Shares\IT" 1 "Directory" "CONTOSO\svc-backup" "ReadAndExecute, Synchronize" "Allow" $false "user"

# Public (everyone, no extra groups)
Add-DemoRow "D:\Shares\Public" 1 "Directory"

# ---- Group membership expansion (Finance-Team has a nested Payroll-Team) ----
$financeMembers = @(
    @{ Level = 0; MemberName = "Alice Nguyen"; MemberSamAccount = "alice.nguyen"; MemberClass = "user" }
    @{ Level = 0; MemberName = "Ben Carter"; MemberSamAccount = "ben.carter"; MemberClass = "user" }
    @{ Level = 0; MemberName = "Payroll-Team"; MemberSamAccount = "Payroll-Team"; MemberClass = "group" }
    @{ Level = 1; MemberName = "Dana Whitfield"; MemberSamAccount = "dana.whitfield"; MemberClass = "user" }
)
foreach ($m in $financeMembers) {
    $script:MembershipRows.Add([pscustomobject]@{
        PermissionPath = "D:\Shares\Finance"; PermissionIdentity = "CONTOSO\Finance-Team"
        Level = $m.Level; MemberName = $m.MemberName; MemberSamAccount = $m.MemberSamAccount
        MemberClass = $m.MemberClass; Error = $null
    })
}

$hrMembers = @(
    @{ Level = 0; MemberName = "Priya Shah"; MemberSamAccount = "priya.shah"; MemberClass = "user" }
    @{ Level = 0; MemberName = "Marco Bianchi"; MemberSamAccount = "marco.bianchi"; MemberClass = "user" }
)
foreach ($m in $hrMembers) {
    $script:MembershipRows.Add([pscustomobject]@{
        PermissionPath = "D:\Shares\HR"; PermissionIdentity = "CONTOSO\HR-Team"
        Level = $m.Level; MemberName = $m.MemberName; MemberSamAccount = $m.MemberSamAccount
        MemberClass = $m.MemberClass; Error = $null
    })
}

$itMembers = @(
    @{ Level = 0; MemberName = "Sofia Martins"; MemberSamAccount = "sofia.martins"; MemberClass = "user" }
    @{ Level = 0; MemberName = "WKS-BUILD01"; MemberSamAccount = "WKS-BUILD01$"; MemberClass = "computer" }
)
foreach ($m in $itMembers) {
    $script:MembershipRows.Add([pscustomobject]@{
        PermissionPath = "D:\Shares\IT"; PermissionIdentity = "CONTOSO\IT-Team"
        Level = $m.Level; MemberName = $m.MemberName; MemberSamAccount = $m.MemberSamAccount
        MemberClass = $m.MemberClass; Error = $null
    })
}

$outFile = Join-Path $PSScriptRoot "demo-report.html"
Build-ExplorerHtmlReport -HtmlPath $outFile
Write-Host "Wrote $outFile"
