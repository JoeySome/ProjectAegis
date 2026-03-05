# SoulGuard - Soul Integrity Checker (PowerShell)
# Computes and verifies SHA256 hash of OpenClaw core configuration.
# Usage:
#   .\integrity.ps1 -Action store              - Store current hash as baseline
#   .\integrity.ps1 -Action verify              - Compare current hash against baseline
#   .\integrity.ps1 -Action store -FilePath <p> - Store hash of a specific file
#   .\integrity.ps1 -Action verify -FilePath <p> - Verify a specific file

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("store", "verify")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$FilePath
)

$ErrorActionPreference = "Stop"

$StoreDir = Join-Path $env:USERPROFILE ".soulguard"
$HashFile = Join-Path $StoreDir "integrity_hashes.json"

# Default paths to monitor
$DefaultPaths = @(
    (Join-Path $env:USERPROFILE ".openclaw\openclaw.json")
)

# Ensure store directory exists
if (-not (Test-Path $StoreDir)) {
    New-Item -ItemType Directory -Path $StoreDir -Force | Out-Null
}

# Initialize hash file if not exists
if (-not (Test-Path $HashFile)) {
    '{}' | Set-Content $HashFile -Encoding UTF8
}

function Get-FileHashValue {
    param([string]$Path)
    if (Test-Path $Path -PathType Leaf) {
        return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLower()
    } else {
        return "FILE_NOT_FOUND"
    }
}

function Store-HashEntry {
    param([string]$Path)
    
    $hash = Get-FileHashValue $Path
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    
    if ($hash -eq "FILE_NOT_FOUND") {
        Write-Output "⚠️  File not found: $Path"
        return
    }
    
    $data = Get-Content $HashFile -Raw | ConvertFrom-Json
    
    # Add or update entry
    $entry = @{
        hash = $hash
        stored_at = $timestamp
    }
    
    if ($data.PSObject.Properties.Name -contains $Path) {
        $data.$Path = $entry
    } else {
        $data | Add-Member -NotePropertyName $Path -NotePropertyValue $entry
    }
    
    $data | ConvertTo-Json -Depth 10 | Set-Content $HashFile -Encoding UTF8
    
    Write-Output "✅ Stored hash for: $Path"
    Write-Output "   Hash: $hash"
    Write-Output "   Time: $timestamp"
}

function Verify-HashEntry {
    param([string]$Path)
    
    $currentHash = Get-FileHashValue $Path
    
    if ($currentHash -eq "FILE_NOT_FOUND") {
        Write-Output "⚠️  File not found: $Path"
        return
    }
    
    $data = Get-Content $HashFile -Raw | ConvertFrom-Json
    
    if (-not ($data.PSObject.Properties.Name -contains $Path)) {
        Write-Output "⚠️  No baseline hash found for: $Path"
        Write-Output "   Run 'integrity.ps1 -Action store' first to establish a baseline."
        return
    }
    
    $storedHash = $data.$Path.hash
    
    if ($currentHash -eq $storedHash) {
        Write-Output "✅ INTACT: $Path"
        Write-Output "   Hash: $currentHash"
    } else {
        Write-Output "🔴 TAMPERED: $Path"
        Write-Output "   Expected: $storedHash"
        Write-Output "   Current:  $currentHash"
        Write-Output "   ⚠️  Your soul may have been modified!"
    }
}

Write-Output "=========================================="
Write-Output " SoulGuard Soul Integrity Check"
Write-Output "=========================================="
Write-Output "Action: $Action"
Write-Output "Time:   $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))"
Write-Output "=========================================="
Write-Output ""

$pathsToCheck = if ($FilePath) { @($FilePath) } else { $DefaultPaths }

switch ($Action) {
    "store" {
        foreach ($p in $pathsToCheck) {
            Store-HashEntry $p
        }
    }
    "verify" {
        foreach ($p in $pathsToCheck) {
            Verify-HashEntry $p
        }
    }
}

Write-Output ""
Write-Output "=========================================="
Write-Output " Integrity Check Complete"
Write-Output "=========================================="
