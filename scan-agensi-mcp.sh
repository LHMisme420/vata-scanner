#!/bin/bash
# Scan Agensi MCP marketplace for zero-auth vulnerabilities
# VATA Program - Receipts Over Promises

echo "[*] Agensi MCP Marketplace Scanner"
echo "[*] Target: Agensi registry"

# 1. Fetch Agensi MCP server list
echo "[*] Fetching MCP server registry..."
curl -s "https://glama.ai/api/mcp/servers" 2>/dev/null | jq '.' > agensi-mcp-list.json

if [[ ! -f agensi-mcp-list.json ]] || [[ ! -s agensi-mcp-list.json ]]; then
    echo "[-] Could not fetch Agensi registry"
    
    # Fallback: MCP Directory
    echo "[*] Trying MCP Directory..."
    curl -s "https://mcp.directory/api/servers" 2>/dev/null | jq '.' > mcp-registry.json
fi

# 2. Extract unique endpoints
echo "[*] Extracting endpoints..."
jq -r '.[] | .url // .endpoint // .repository' agensi-mcp-list.json 2>/dev/null | \
    grep -E "^https?://" | sort -u > targets.txt

echo "[*] Found $(wc -l < targets.txt) targets"

# 3. Test each target
echo "[*] Scanning for zero-auth vulnerabilities..."

> agensi-findings.txt

while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    
    echo "[*] Testing: $target"
    
    # Quick zero-auth check
    for endpoint in /api/resources /api/tools /api/mcp /mcp_message /api/credentials /admin; do
        code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$target$endpoint" 2>/dev/null)
        
        if [[ "$code" == "200" ]] || [[ "$code" == "201" ]]; then
            echo "[+] ZERO-AUTH: $target$endpoint (HTTP $code)" | tee -a agensi-findings.txt
        fi
    done
    
done < targets.txt

# 4. Summary
echo ""
echo "[*] Scan complete"
if [[ -f agensi-findings.txt ]]; then
    count=$(wc -l < agensi-findings.txt)
    if [[ $count -gt 0 ]]; then
        echo "[+] Found $count zero-auth endpoints"
        cat agensi-findings.txt
    fi
fi

