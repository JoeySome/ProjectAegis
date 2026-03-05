# SoulGuard - Audit History Manager (PowerShell)
# Records and queries audit results.
# Usage:
#   .\history.ps1 -Action add -SkillName <name> -RiskLevel <level> -Summary <text>
#   .\history.ps1 -Action query -SkillName <name>
#   .\history.ps1 -Action list

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("add", "query", "list")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$SkillName,
    
    [Parameter(Mandatory=$false)]
    [string]$RiskLevel,
    
    [Parameter(Mandatory=$false)]
    [string]$Summary
)

$ErrorActionPreference = "Stop"

$StoreDir = Join-Path $env:USERPROFILE ".soulguard"
$HistoryFile = Join-Path $StoreDir "audit_history.json"

# Ensure store directory
if (-not (Test-Path $StoreDir)) {
    New-Item -ItemType Directory -Path $StoreDir -Force | Out-Null
}

# Initialize history file
if (-not (Test-Path $HistoryFile)) {
    '{"audits":[]}' | Set-Content $HistoryFile -Encoding UTF8
}

$data = Get-Content $HistoryFile -Raw | ConvertFrom-Json

switch ($Action) {
    "add" {
        if (-not $SkillName -or -not $RiskLevel -or -not $Summary) {
            Write-Error "Usage: history.ps1 -Action add -SkillName <name> -RiskLevel <level> -Summary <text>"
            exit 1
        }
        
        $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        
        $entry = @{
            skill_name = $SkillName
            risk_level = $RiskLevel
            summary    = $Summary
            audited_at = $timestamp
        }
        
        # Ensure audits is an array
        if ($null -eq $data.audits) {
            $data.audits = @()
        }
        $data.audits += $entry
        
        $data | ConvertTo-Json -Depth 10 | Set-Content $HistoryFile -Encoding UTF8
        
        Write-Output "✅ Recorded audit for: $SkillName"
        Write-Output "   Risk Level: $RiskLevel"
        Write-Output "   Time: $timestamp"
    }
    
    "query" {
        if (-not $SkillName) {
            Write-Error "Usage: history.ps1 -Action query -SkillName <name>"
            exit 1
        }
        
        Write-Output "=========================================="
        Write-Output " Audit History: $SkillName"
        Write-Output "=========================================="
        
        $results = $data.audits | Where-Object { $_.skill_name -eq $SkillName }
        
        if (-not $results -or $results.Count -eq 0) {
            Write-Output "No audit records found."
        } else {
            foreach ($r in $results) {
                Write-Output "  [$($r.audited_at)] Risk: $($r.risk_level)"
                Write-Output "  Summary: $($r.summary)"
                Write-Output ""
            }
        }
    }
    
    "list" {
        Write-Output "=========================================="
        Write-Output " All Audit Records"
        Write-Output "=========================================="
        
        if (-not $data.audits -or $data.audits.Count -eq 0) {
            Write-Output "No audit records found."
        } else {
            $grouped = $data.audits | Group-Object skill_name
            foreach ($group in $grouped) {
                $latest = $group.Group | Sort-Object audited_at | Select-Object -Last 1
                Write-Output "  $($group.Name): $($group.Count) audit(s), latest risk: $($latest.risk_level) ($($latest.audited_at))"
            }
        }
    }
}
