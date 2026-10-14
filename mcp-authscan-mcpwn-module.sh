#!/bin/bash
# MCPwn Module for mcp-authscan
# CVE-2026-33032 - Nginx-UI MCP Authentication Bypass
# Integrate into main scanner

check_mcpwn() {
    local target="$1"
    local port="${2:-9000}"
    
    echo "[MODULE] MCPwn (CVE-2026-33032) Check"
    
    # Test /mcp_message (zero-auth endpoint)
    local mcp_msg_code=$(curl -s -o /dev/null -w "%{http_code}" \
        --max-time 10 "http://$target:$port/mcp_message" 2>/dev/null)
    
    # Test /api/backup (unauth backup export)
    local backup_header=$(curl -s -i "http://$target:$port/api/backup" 2>/dev/null | \
        grep -i "X-Backup-Security")
    
    # Verdict
    if [[ "$mcp_msg_code" == "200" ]] || [[ "$mcp_msg_code" == "201" ]]; then
        echo "[CRITICAL] /mcp_message: HTTP $mcp_msg_code (ZERO-AUTH)"
        echo "[CVE-2026-33032] Nginx-UI MCP Authentication Bypass DETECTED"
        return 0
    fi
    
    if [[ -n "$backup_header" ]]; then
        echo "[CRITICAL] /api/backup: Unauth backup export + key in header"
        echo "[CVE-2026-27944] Backup encryption key exposure DETECTED"
        return 0
    fi
    
    return 1
}

export -f check_mcpwn
