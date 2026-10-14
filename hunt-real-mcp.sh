#!/bin/bash
# Hunt real MCP servers from registry

echo "[*] Real MCP Server Hunter"

# Get glama.ai MCP servers page and extract actual server repos/URLs
echo "[*] Fetching Glama.ai MCP server catalog..."

curl -s "https://glama.ai/mcp/servers" | \
    grep -oP '(?:https://github\.com/[^\s"<>]+|https://[a-z0-9.-]+\.[a-z]{2,}/[^\s"<>]+)' | \
    grep -v "glama.ai" | \
    sort -u > real-mcp-servers.txt

echo "[*] Found $(wc -l < real-mcp-servers.txt) real MCP servers"

# Show what we found
echo "[*] Top targets:"
head -10 real-mcp-servers.txt

# Now test REAL servers for zero-auth
echo ""
echo "[*] Testing real MCP server endpoints..."

> real-mcp-findings.txt

while IFS= read -r server; do
    [[ -z "$server" ]] && continue
    
    # Skip GitHub repo links, test actual deployed endpoints
    if [[ "$server" =~ github.com ]]; then
        # Extract hostname for deployed version
        domain=$(echo "$server" | sed 's/github\.com\/\([^/]*\)\/\([^/]*\).*/\1.\2.dev/' | tr '[:upper:]' '[:lower:]')
        server="https://$domain"
    fi
    
    echo "[*] $server"
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$server" 2>/dev/null)
    
    if [[ "$code" == "200" ]] || [[ "$code" == "201" ]]; then
        echo "[+] LIVE: $server (HTTP $code)" | tee -a real-mcp-findings.txt
        
        # Test zero-auth endpoints on LIVE servers
        for ep in /api/resources /api/tools /mcp_message /api/mcp; do
            ep_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$server$ep" 2>/dev/null)
            [[ "$ep_code" == "200" ]] && echo "  [!] ZERO-AUTH: $ep" | tee -a real-mcp-findings.txt
        done
    fi
    
done < real-mcp-servers.txt

echo ""
cat real-mcp-findings.txt

