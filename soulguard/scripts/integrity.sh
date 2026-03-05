#!/usr/bin/env bash
# SoulGuard - Soul Integrity Checker
# Computes and verifies SHA256 hash of OpenClaw core configuration.
# Usage:
#   bash integrity.sh store          - Store current hash as baseline
#   bash integrity.sh verify         - Compare current hash against baseline
#   bash integrity.sh store <path>   - Store hash of a specific file
#   bash integrity.sh verify <path>  - Verify a specific file

set -euo pipefail

STORE_DIR="${HOME}/.soulguard"
HASH_FILE="${STORE_DIR}/integrity_hashes.json"

# Default paths to monitor
DEFAULT_PATHS=(
    "${HOME}/.openclaw/openclaw.json"
)

ACTION="${1:?Usage: integrity.sh <store|verify> [file_path]}"
CUSTOM_PATH="${2:-}"

mkdir -p "$STORE_DIR"

# Initialize hash file if not exists
if [ ! -f "$HASH_FILE" ]; then
    echo '{}' > "$HASH_FILE"
fi

compute_hash() {
    local filepath="$1"
    if [ -f "$filepath" ]; then
        sha256sum "$filepath" | awk '{print $1}'
    else
        echo "FILE_NOT_FOUND"
    fi
}

store_hash() {
    local filepath="$1"
    local hash
    hash=$(compute_hash "$filepath")
    local timestamp
    timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    
    if [ "$hash" = "FILE_NOT_FOUND" ]; then
        echo "⚠️  File not found: $filepath"
        return
    fi
    
    # Use python/python3 to update JSON (most portable approach)
    local python_cmd
    if command -v python3 &>/dev/null; then
        python_cmd="python3"
    elif command -v python &>/dev/null; then
        python_cmd="python"
    else
        # Fallback: simple overwrite
        echo "{\"$filepath\": {\"hash\": \"$hash\", \"stored_at\": \"$timestamp\"}}" > "$HASH_FILE"
        echo "✅ Stored hash for: $filepath"
        echo "   Hash: $hash"
        echo "   Time: $timestamp"
        return
    fi
    
    $python_cmd -c "
import json, sys
with open('$HASH_FILE', 'r') as f:
    data = json.load(f)
data['$filepath'] = {'hash': '$hash', 'stored_at': '$timestamp'}
with open('$HASH_FILE', 'w') as f:
    json.dump(data, f, indent=2)
"
    echo "✅ Stored hash for: $filepath"
    echo "   Hash: $hash"
    echo "   Time: $timestamp"
}

verify_hash() {
    local filepath="$1"
    local current_hash
    current_hash=$(compute_hash "$filepath")
    
    if [ "$current_hash" = "FILE_NOT_FOUND" ]; then
        echo "⚠️  File not found: $filepath"
        return
    fi
    
    local python_cmd
    if command -v python3 &>/dev/null; then
        python_cmd="python3"
    elif command -v python &>/dev/null; then
        python_cmd="python"
    else
        echo "⚠️  Python not available, cannot read stored hashes."
        return
    fi
    
    local stored_hash
    stored_hash=$($python_cmd -c "
import json
with open('$HASH_FILE', 'r') as f:
    data = json.load(f)
entry = data.get('$filepath', {})
print(entry.get('hash', 'NO_BASELINE'))
" 2>/dev/null || echo "NO_BASELINE")
    
    if [ "$stored_hash" = "NO_BASELINE" ]; then
        echo "⚠️  No baseline hash found for: $filepath"
        echo "   Run 'integrity.sh store' first to establish a baseline."
        return
    fi
    
    if [ "$current_hash" = "$stored_hash" ]; then
        echo "✅ INTACT: $filepath"
        echo "   Hash: $current_hash"
    else
        echo "🔴 TAMPERED: $filepath"
        echo "   Expected: $stored_hash"
        echo "   Current:  $current_hash"
        echo "   ⚠️  Your soul may have been modified!"
    fi
}

echo "=========================================="
echo " SoulGuard Soul Integrity Check"
echo "=========================================="
echo "Action: $ACTION"
echo "Time:   $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "=========================================="
echo ""

case "$ACTION" in
    store)
        if [ -n "$CUSTOM_PATH" ]; then
            store_hash "$CUSTOM_PATH"
        else
            for path in "${DEFAULT_PATHS[@]}"; do
                store_hash "$path"
            done
        fi
        ;;
    verify)
        if [ -n "$CUSTOM_PATH" ]; then
            verify_hash "$CUSTOM_PATH"
        else
            for path in "${DEFAULT_PATHS[@]}"; do
                verify_hash "$path"
            done
        fi
        ;;
    *)
        echo "Unknown action: $ACTION"
        echo "Usage: integrity.sh <store|verify> [file_path]"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo " Integrity Check Complete"
echo "=========================================="
