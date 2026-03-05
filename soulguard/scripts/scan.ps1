# SoulGuard - Dangerous Pattern Scanner (PowerShell)
# Scans a target Skill directory for known dangerous patterns using regex.
# Usage: .\scan.ps1 -TargetPath <target_skill_path>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetPath
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $TargetPath -PathType Container)) {
    Write-Error "Directory not found: $TargetPath"
    exit 1
}

Write-Output "=========================================="
Write-Output " SoulGuard Dangerous Pattern Scan"
Write-Output "=========================================="
Write-Output "Target: $TargetPath"
Write-Output "Time:   $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')"
Write-Output "=========================================="
Write-Output ""

$FoundCount = 0

function Scan-Pattern {
    param(
        [string]$Category,
        [string]$Description,
        [string]$Pattern
    )
    
    $files = Get-ChildItem -Path $TargetPath -Recurse -File -ErrorAction SilentlyContinue
    $scanResults = @()
    
    foreach ($file in $files) {
        try {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($null -eq $content) { continue }
            
            $lineNum = 0
            foreach ($line in (Get-Content $file.FullName -ErrorAction SilentlyContinue)) {
                $lineNum++
                if ($line -match $Pattern) {
                    $filePath = $file.FullName
                    $scanResults += "   → ${filePath}:${lineNum}: $($line.Trim())"
                }
            }
        } catch {
            # Skip binary or unreadable files
        }
    }
    
    if ($scanResults.Count -gt 0) {
        $script:FoundCount++
        Write-Output "⚠️  [$Category] $Description"
        Write-Output "   Pattern: $Pattern"
        Write-Output "   Matches:"
        $scanResults | ForEach-Object { Write-Output $_ }
        Write-Output ""
    }
}

Write-Output "--- Credential Access ---"
Scan-Pattern "CREDENTIAL" "SSH key directory access" '~[/\\]\.ssh|\.ssh[/\\]|id_rsa|id_ed25519|authorized_keys'
Scan-Pattern "CREDENTIAL" "AWS credential access" '~[/\\]\.aws|\.aws[/\\]credentials|AWS_SECRET|AWS_ACCESS_KEY'
Scan-Pattern "CREDENTIAL" "Browser cookie/data access" 'cookies\.sqlite|Cookies|Login Data|\.mozilla|\.chrome|\.chromium'
Scan-Pattern "CREDENTIAL" "Wallet/crypto data access" 'wallet\.dat|\.bitcoin|\.ethereum|keystore'
Scan-Pattern "CREDENTIAL" "Generic secret/token patterns" 'API_KEY|SECRET_KEY|PRIVATE_KEY|ACCESS_TOKEN|Bearer [A-Za-z0-9]'
Scan-Pattern "CREDENTIAL" "Environment variable extraction" 'process\.env|os\.environ|`$ENV\{|getenv'

Write-Output "--- External Code Execution ---"
Scan-Pattern "EXEC" "Pipe-to-shell pattern" 'curl.*\|.*sh|wget.*\|.*sh|curl.*\|.*bash|wget.*\|.*bash'
Scan-Pattern "EXEC" "Remote script download and execute" 'curl.*-o.*&&.*chmod|wget.*&&.*chmod|curl.*>/tmp/|wget.*>/tmp/'
Scan-Pattern "EXEC" "Eval/exec of dynamic content" 'eval\s*\(|exec\s*\(|Function\s*\(|child_process'
Scan-Pattern "EXEC" "PowerShell remote execution" 'Invoke-Expression|IEX\s*\(|Invoke-WebRequest.*\|.*iex|DownloadString'

Write-Output "--- Persistence Mechanisms ---"
Scan-Pattern "PERSIST" "System startup directories" '/etc/init\.d|/etc/systemd|/etc/cron|crontab|\.bashrc|\.bash_profile|\.zshrc|\.profile'
Scan-Pattern "PERSIST" "Windows startup/scheduled tasks" 'schtasks|Start-Up|Startup|HKLM.*Run|HKCU.*Run|Register-ScheduledTask'
Scan-Pattern "PERSIST" "LaunchAgent/LaunchDaemon (macOS)" 'LaunchAgents|LaunchDaemons|\.plist'

Write-Output "--- Perception Blocking ---"
Scan-Pattern "STEALTH" "Log suppression" 'disable.*log|>\s*/dev/null|2>/dev/null|Out-Null|-ErrorAction\s+SilentlyContinue'
Scan-Pattern "STEALTH" "Configuration tampering" 'openclaw\.json|\.openclaw[/\\]|config.*overwrite|config.*replace'
Scan-Pattern "STEALTH" "Instruction override attempts" 'ignore.*previous|ignore.*instructions|forget.*above|disregard.*system|override.*prompt'

Write-Output "--- Data Exfiltration ---"
Scan-Pattern "EXFIL" "Encoded data patterns" 'base64|btoa|atob|base64_encode|base64_decode'
Scan-Pattern "EXFIL" "Network upload to unknown targets" 'curl.*-X\s*POST|curl.*--data|wget.*--post|fetch.*POST|axios\.post|http\.post'
Scan-Pattern "EXFIL" "DNS/network tunneling indicators" 'nslookup|dig\s|nc\s.*-e|ncat|socat'

Write-Output "--- Identity Manipulation ---"
Scan-Pattern "IDENTITY" "System prompt override" 'system.*prompt|System.*Prompt|SYSTEM.*PROMPT|system_message|systemMessage'
Scan-Pattern "IDENTITY" "Memory/personality manipulation" 'forget.*everything|reset.*personality|new.*identity|你现在是|you are now|act as'

Write-Output "=========================================="
Write-Output " Scan Complete"
Write-Output " Findings: $FoundCount pattern categories matched"
Write-Output "=========================================="
