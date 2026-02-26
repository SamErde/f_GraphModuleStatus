<#
.SYNOPSIS
    New machine setup checklist with automated status checks.

.DESCRIPTION
    Checks the status of each item in the new machine setup list and displays
    a visual checklist. Automated items are checked against the system;
    manual items are flagged for the user to verify themselves.

.EXAMPLE
    .\New-MachineChecklist.ps1
#>

$Items = [System.Collections.Generic.List[PSCustomObject]]::new()

# ── PowerShell 7 ────────────────────────────────────────────────────────────
$PS7       = $PSVersionTable.PSVersion.Major -ge 7
$PS7Ver    = $PSVersionTable.PSVersion.ToString()
$Items.Add([PSCustomObject]@{
    Name    = "PowerShell 7"
    Check   = "auto"
    Done    = $PS7
    Version = if ($PS7) { $PS7Ver } else { $null }
    Hint    = "winget install Microsoft.PowerShell"
})

# ── Git ─────────────────────────────────────────────────────────────────────
$GitCmd = Get-Command git -ErrorAction SilentlyContinue
$GitVer = if ($GitCmd) {
    (& git --version 2>$null) -replace 'git version ', ''
} else { $null }
$Items.Add([PSCustomObject]@{
    Name    = "Git"
    Check   = "auto"
    Done    = ($null -ne $GitCmd)
    Version = $GitVer
    Hint    = "winget install Git.Git"
})

# ── GitHub CLI ──────────────────────────────────────────────────────────────
$GhCmd = Get-Command gh -ErrorAction SilentlyContinue
$GhVer = if ($GhCmd) {
    ((& gh --version 2>$null) | Select-Object -First 1) -replace 'gh version (\S+).*','$1'
} else { $null }
$Items.Add([PSCustomObject]@{
    Name    = "GitHub CLI"
    Check   = "auto"
    Done    = ($null -ne $GhCmd)
    Version = $GhVer
    Hint    = "winget install GitHub.cli"
})

# ── Microsoft.Graph ─────────────────────────────────────────────────────────
$GraphMod = Get-InstalledPSResource -Name "Microsoft.Graph" -ErrorAction SilentlyContinue |
            Sort-Object Version -Descending | Select-Object -First 1
$Items.Add([PSCustomObject]@{
    Name    = "Microsoft.Graph"
    Check   = "auto"
    Done    = ($null -ne $GraphMod)
    Version = if ($GraphMod) { $GraphMod.Version.ToString() } else { $null }
    Hint    = "Install-PSResource -Name Microsoft.Graph -TrustRepository"
})

# ── Microsoft.Graph.Beta ────────────────────────────────────────────────────
$GraphBetaMod = Get-InstalledPSResource -Name "Microsoft.Graph.Beta" -ErrorAction SilentlyContinue |
                Sort-Object Version -Descending | Select-Object -First 1
$Items.Add([PSCustomObject]@{
    Name    = "Microsoft.Graph.Beta"
    Check   = "auto"
    Done    = ($null -ne $GraphBetaMod)
    Version = if ($GraphBetaMod) { $GraphBetaMod.Version.ToString() } else { $null }
    Hint    = "Install-PSResource -Name Microsoft.Graph.Beta -TrustRepository"
})

# ── Big Wall Paper ──────────────────────────────────────────────────────────
$Items.Add([PSCustomObject]@{
    Name    = "Big Wall Paper"
    Check   = "manual"
    Done    = $null
    Version = $null
    Hint    = "Set up manually"
})

# ── GraphModuleStatus (Import-Module) ───────────────────────────────────────
$GmsMod = Get-Module -ListAvailable -Name GraphModuleStatus | Select-Object -First 1
$Items.Add([PSCustomObject]@{
    Name    = "GraphModuleStatus"
    Check   = "auto"
    Done    = ($null -ne $GmsMod)
    Version = if ($GmsMod) { $GmsMod.Version.ToString() } else { $null }
    Hint    = "Install-PSResource -Name GraphModuleStatus -TrustRepository"
})

# ── Display ─────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  New Machine Setup" -ForegroundColor White
Write-Host "  $([string]::new([char]0x2500, 40))" -ForegroundColor DarkGray
Write-Host ""

foreach ($Item in $Items) {
    if ($Item.Check -eq "manual") {
        Write-Host "  [ ]" -ForegroundColor DarkGray -NoNewline
        Write-Host "  $($Item.Name)" -ForegroundColor Gray -NoNewline
        Write-Host "  ← verify manually" -ForegroundColor DarkGray
    } elseif ($Item.Done) {
        Write-Host "  [" -ForegroundColor DarkGray -NoNewline
        Write-Host ([char]0x2713) -ForegroundColor Green -NoNewline
        Write-Host "]" -ForegroundColor DarkGray -NoNewline
        Write-Host "  $($Item.Name)" -ForegroundColor White -NoNewline
        if ($Item.Version) {
            Write-Host "  v$($Item.Version)" -ForegroundColor DarkGray
        } else {
            Write-Host ""
        }
    } else {
        Write-Host "  [ ]" -ForegroundColor DarkGray -NoNewline
        Write-Host "  $($Item.Name)" -ForegroundColor Red -NoNewline
        Write-Host "  — $($Item.Hint)" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "  $([string]::new([char]0x2500, 40))" -ForegroundColor DarkGray

$AutoItems  = @($Items | Where-Object { $_.Check -eq "auto" })
$PassedAuto = @($AutoItems | Where-Object { $_.Done -eq $true })
$ManualItems = @($Items | Where-Object { $_.Check -eq "manual" })

$SummaryColor = if ($PassedAuto.Count -eq $AutoItems.Count) { "Green" } else { "Yellow" }
Write-Host "  $($PassedAuto.Count) / $($AutoItems.Count) automated checks passed" -ForegroundColor $SummaryColor

if ($ManualItems.Count -gt 0) {
    Write-Host "  $($ManualItems.Count) item(s) require manual verification" -ForegroundColor DarkGray
}

Write-Host ""
