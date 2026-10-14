#!/bin/bash
# Hunt new MCP gateway implementations on GitHub

echo "[*] MCP Gateway Hunter - VATA Program"
echo "[*] Searching for unscanned gateway implementations..."
echo ""

# Search GitHub for MCP gateway repos
# Focus on: gateway, proxy, router, orchestrator, manager implementations

QUERIES=(
    "mcp gateway"
    "mcp proxy"
    "mcp server manager"
    "mcp router"
    "model context protocol gateway"
    "mcp orchestrator"
)

> ~/vata/gateway-targets.txt

for query in "${QUERIES[@]}"; do
    echo "[*] Searching: \"$query\""
    
    # GitHub API search (no auth, limited rate)
    curl -s "https://api.github.com/search/repositories?q=$query+language:python+language:go+language:typescript&sort=stars&order=desc&per_page=20" 2>/dev/null | \
        grep -oP '"html_url":"https://github\.com/[^"]+' | \
        sed 's/"html_url":"//' | \
        sed 's/"$//' >> ~/vata/gateway-targets.txt
    
done

# Remove duplicates and known (already scanned)
KNOWN=(
    "github.com/mcpjungle/mcpjungle"
    "github.com/metatool-ai/metamcp"
    "github.com/lucky-aeon/mcp-gateway"
    "github.com/hoophq/mcpproxy"
    "github.com/atrawog/mcp-oauth-gateway"
)

sort -u ~/vata/gateway-targets.txt > /tmp/all-gateways.txt

echo "[*] Filtering known targets..."
for known in "${KNOWN[@]}"; do
    sed -i "/$known/d" /tmp/all-gateways.txt
done

NEW_COUNT=$(wc -l < /tmp/all-gateways.txt)
echo "[+] Found $NEW_COUNT new gateway implementations"
echo ""
echo "[*] New targets:"
cat /tmp/all-gateways.txt

# Save for testing
cp /tmp/all-gateways.txt ~/vata/new-gateway-targets.txt

echo ""
echo "[*] Next: Clone and scan these repos for zero-auth vulnerabilities"

