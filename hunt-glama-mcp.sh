#!/bin/bash
# Hunt MCP servers on Glama.ai

echo "[*] Glama.ai MCP Server Hunt"

# Fetch glama registry
echo "[*] Fetching glama.ai/mcp/servers..."
curl -s "https://glama.ai/mcp/servers" > glama-servers.html

# Extract server URLs from page
echo "[*] Parsing server listings..."
grep -oP 'https?://[^\s"<>]+' glama-servers.html | \
    grep -E "mcp|server|api" | sort -u > glama-targets.txt

echo "[*] Found $(wc -l < glama-targets.txt) potential targets"

# Test each for zero-auth
echo "[*] Testing for zero-auth vulnerabilities..."

> glama-findings.txt

while IFS= read -r server; do
    [[ -z "$server" ]] && continue
    
    echo "[*] Testing: $server"
    
    # Test common zero-auth endpoints
    for ep in "" "/api/resources" "/api/tools" "/mcp_message" "/api/mcp"; do
        code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$server$ep" 2>/dev/null)
        
        if [[ "$code" == "200" ]]; then
            echo "[+] ZERO-AUTH: $server$ep" | tee -a glama-findings.txt
        fi
    done
    
done < glama-targets.txt

echo ""
echo "[*] Done. Results in glama-findings.txt"
cat glama-findings.txt

