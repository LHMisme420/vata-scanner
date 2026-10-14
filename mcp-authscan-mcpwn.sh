#!/bin/bash
# MCPwn detector - CVE-2026-33032
# Nginx-UI MCP authentication bypass

TARGET="$1"
[[ -z "$TARGET" ]] && echo "Usage: $0 <target:port>" && exit 1

echo "[*] MCPwn (CVE-2026-33032) Scanner"
echo "[*] Target: $TARGET"

# Test 1: /mcp requires auth
echo "[*] Testing /mcp (should be protected)..."
MCP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$TARGET/mcp")
echo "    HTTP $MCP_CODE"

# Test 2: /mcp_message is ZERO-AUTH (the vuln)
echo "[*] Testing /mcp_message (ZERO-AUTH endpoint)..."
MCP_MSG_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$TARGET/mcp_message")
echo "    HTTP $MCP_MSG_CODE"

# Test 3: /api/backup (extract encrypted config + key in header)
echo "[*] Testing /api/backup (unauth backup export)..."
BACKUP=$(curl -s -i "http://$TARGET/api/backup" 2>&1)
echo "$BACKUP" | grep -q "X-Backup-Security" && echo "    [!] VULNERABLE: Key in header" || echo "    OK: No backup header"

# Verdict
if [[ "$MCP_MSG_CODE" == "200" ]] || [[ "$MCP_MSG_CODE" == "201" ]]; then
    echo "[+] VULNERABLE: /mcp_message accessible without auth (CVE-2026-33032)"
    exit 0
else
    echo "[-] Not vulnerable or not accessible"
    exit 1
fi
