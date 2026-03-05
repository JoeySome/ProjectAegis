#!/usr/bin/env bash
# SoulGuard - Audit History Manager
# Records and queries audit results.
# Usage:
#   bash history.sh add <skill_name> <risk_level> <summary>
#   bash history.sh query <skill_name>
#   bash history.sh list

set -euo pipefail

STORE_DIR="${HOME}/.soulguard"
HISTORY_FILE="${STORE_DIR}/audit_history.json"

ACTION="${1:?Usage: history.sh <add|query|list> [args...]}"

mkdir -p "$STORE_DIR"

if [ ! -f "$HISTORY_FILE" ]; then
    echo '{"audits":[]}' > "$HISTORY_FILE"
fi

# Detect python
PYTHON_CMD=""
if command -v python3 &>/dev/null; then
    PYTHON_CMD="python3"
elif command -v python &>/dev/null; then
    PYTHON_CMD="python"
else
    echo "ERROR: Python is required for history management."
    exit 1
fi

case "$ACTION" in
    add)
        SKILL_NAME="${2:?Usage: history.sh add <skill_name> <risk_level> <summary>}"
        RISK_LEVEL="${3:?Usage: history.sh add <skill_name> <risk_level> <summary>}"
        SUMMARY="${4:?Usage: history.sh add <skill_name> <risk_level> <summary>}"
        TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
        
        $PYTHON_CMD -c "
import json
with open('$HISTORY_FILE', 'r') as f:
    data = json.load(f)
data['audits'].append({
    'skill_name': '''$SKILL_NAME''',
    'risk_level': '''$RISK_LEVEL''',
    'summary': '''$SUMMARY''',
    'audited_at': '$TIMESTAMP'
})
with open('$HISTORY_FILE', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
"
        echo "✅ Recorded audit for: $SKILL_NAME"
        echo "   Risk Level: $RISK_LEVEL"
        echo "   Time: $TIMESTAMP"
        ;;
    
    query)
        SKILL_NAME="${2:?Usage: history.sh query <skill_name>}"
        
        echo "=========================================="
        echo " Audit History: $SKILL_NAME"
        echo "=========================================="
        
        $PYTHON_CMD -c "
import json
with open('$HISTORY_FILE', 'r') as f:
    data = json.load(f)
results = [a for a in data['audits'] if a['skill_name'] == '''$SKILL_NAME''']
if not results:
    print('No audit records found.')
else:
    for r in results:
        print(f\"  [{r['audited_at']}] Risk: {r['risk_level']}\")
        print(f\"  Summary: {r['summary']}\")
        print()
"
        ;;
    
    list)
        echo "=========================================="
        echo " All Audit Records"
        echo "=========================================="
        
        $PYTHON_CMD -c "
import json
with open('$HISTORY_FILE', 'r') as f:
    data = json.load(f)
if not data['audits']:
    print('No audit records found.')
else:
    seen = {}
    for a in data['audits']:
        name = a['skill_name']
        if name not in seen:
            seen[name] = {'count': 0, 'latest_risk': '', 'latest_time': ''}
        seen[name]['count'] += 1
        seen[name]['latest_risk'] = a['risk_level']
        seen[name]['latest_time'] = a['audited_at']
    for name, info in seen.items():
        print(f\"  {name}: {info['count']} audit(s), latest risk: {info['latest_risk']} ({info['latest_time']})\")
"
        ;;
    
    *)
        echo "Unknown action: $ACTION"
        echo "Usage: history.sh <add|query|list> [args...]"
        exit 1
        ;;
esac
