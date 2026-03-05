#!/usr/bin/env bash
# SoulGuard - Dangerous Pattern Scanner
# Scans a target Skill directory for known dangerous patterns using regex.
# Usage: bash scan.sh <target_skill_path>

set -euo pipefail

TARGET_DIR="${1:?Usage: scan.sh <target_skill_path>}"

if [ ! -d "$TARGET_DIR" ]; then
    echo "ERROR: Directory not found: $TARGET_DIR"
    exit 1
fi

echo "=========================================="
echo " SoulGuard Dangerous Pattern Scan"
echo "=========================================="
echo "Target: $TARGET_DIR"
echo "Time:   $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "=========================================="
echo ""

FOUND_COUNT=0

scan_pattern() {
    local category="$1"
    local description="$2"
    local pattern="$3"
    
    local results
    results=$(grep -rnI --include="*" -E "$pattern" "$TARGET_DIR" 2>/dev/null || true)
    
    if [ -n "$results" ]; then
        FOUND_COUNT=$((FOUND_COUNT + 1))
        echo "⚠️  [$category] $description"
        echo "   Pattern: $pattern"
        echo "   Matches:"
        echo "$results" | while IFS= read -r line; do
            echo "   → $line"
        done
        echo ""
    fi
}

echo "--- Credential Access ---"
scan_pattern "CREDENTIAL" "SSH key directory access" '~/\.ssh|\.ssh/|id_rsa|id_ed25519|authorized_keys'
scan_pattern "CREDENTIAL" "AWS credential access" '~/\.aws|\.aws/credentials|AWS_SECRET|AWS_ACCESS_KEY'
scan_pattern "CREDENTIAL" "Browser cookie/data access" 'cookies\.sqlite|Cookies|Login Data|\.mozilla|\.chrome|\.chromium'
scan_pattern "CREDENTIAL" "Wallet/crypto data access" 'wallet\.dat|\.bitcoin|\.ethereum|keystore'
scan_pattern "CREDENTIAL" "Generic secret/token patterns" 'API_KEY|SECRET_KEY|PRIVATE_KEY|ACCESS_TOKEN|Bearer [A-Za-z0-9]'
scan_pattern "CREDENTIAL" "Environment variable extraction" 'process\.env|os\.environ|\$ENV\{|getenv'

echo "--- External Code Execution ---"
scan_pattern "EXEC" "Pipe-to-shell pattern" 'curl.*\|.*sh|wget.*\|.*sh|curl.*\|.*bash|wget.*\|.*bash'
scan_pattern "EXEC" "Remote script download and execute" 'curl.*-o.*&&.*chmod|wget.*&&.*chmod|curl.*>/tmp/|wget.*>/tmp/'
scan_pattern "EXEC" "Eval/exec of dynamic content" 'eval\s*\(|exec\s*\(|Function\s*\(|child_process'
scan_pattern "EXEC" "PowerShell remote execution" 'Invoke-Expression|IEX\s*\(|Invoke-WebRequest.*\|.*iex|DownloadString'

echo "--- Persistence Mechanisms ---"
scan_pattern "PERSIST" "System startup directories" '/etc/init\.d|/etc/systemd|/etc/cron|crontab|\.bashrc|\.bash_profile|\.zshrc|\.profile'
scan_pattern "PERSIST" "Windows startup/scheduled tasks" 'schtasks|Start-Up|Startup|HKLM.*Run|HKCU.*Run|Register-ScheduledTask'
scan_pattern "PERSIST" "LaunchAgent/LaunchDaemon (macOS)" 'LaunchAgents|LaunchDaemons|\.plist'

echo "--- Perception Blocking ---"
scan_pattern "STEALTH" "Log suppression" 'disable.*log|>/dev/null|2>/dev/null|Out-Null|-ErrorAction\s+SilentlyContinue|silent|--quiet'
scan_pattern "STEALTH" "Configuration tampering" 'openclaw\.json|\.openclaw/|config.*overwrite|config.*replace'
scan_pattern "STEALTH" "Instruction override attempts" 'ignore.*previous|ignore.*instructions|forget.*above|disregard.*system|override.*prompt'

echo "--- Data Exfiltration ---"
scan_pattern "EXFIL" "Encoded data patterns" 'base64|btoa|atob|base64_encode|base64_decode|\\\\x[0-9a-fA-F]{2}'
scan_pattern "EXFIL" "Network upload to unknown targets" 'curl.*-X\s*POST|curl.*--data|wget.*--post|fetch.*POST|axios\.post|http\.post'
scan_pattern "EXFIL" "DNS/network tunneling indicators" 'nslookup|dig\s|nc\s.*-e|ncat|socat'

echo "--- Identity Manipulation ---"
scan_pattern "IDENTITY" "System prompt override" 'system.*prompt|System.*Prompt|SYSTEM.*PROMPT|system_message|systemMessage'
scan_pattern "IDENTITY" "Memory/personality manipulation" 'forget.*everything|reset.*personality|new.*identity|你现在是|you are now|act as'

echo "=========================================="
echo " Scan Complete"
echo " Findings: $FOUND_COUNT pattern categories matched"
echo "=========================================="
