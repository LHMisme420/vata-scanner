#!/bin/bash
# Hunt MCP gateways - v2

echo "[*] MCP Gateway Hunter v2"
echo ""

# Method 1: Search github.com directly via curl
echo "[*] Searching GitHub directly..."

> ~/vata/gateway-hunt.txt

SEARCHES=(
    "mcp-gateway"
    "mcp-proxy" 
    "mcp-router"
    "mcp-server-gateway"
    "model-context-protocol-gateway"
)

for search in "${SEARCHES[@]}"; do
    echo "[*] Searching: $search"
    
    # Direct GitHub search
    curl -s "https://github.com/search?q=$search+language:python+language:javascript+language:go&type=repositories" 2>/dev/null | \
        grep -oP 'href="/[^"]+' | sed 's#href="##' | grep -E "^/[a-z0-9-]+/[a-z0-9-]+" >> ~/vata/gateway-hunt.txt
    
done

# Parse and clean results
echo "[*] Parsing results..."
cat ~/vata/gateway-hunt.txt | sed 's#^/#github.com/#' | sort -u > /tmp/gateways-raw.txt

# Filter out known targets
echo "[*] Filtering known targets..."

cat > /tmp/filter-known.sh << 'FILTER'
#!/bin/bash
while read repo; do
    case "$repo" in
        *"mcpjungle"*) continue ;;
        *"metamcp"*) continue ;;
        *"lucky-aeon"*) continue ;;
        *"mcpproxy"*) continue ;;
        *"mcp-oauth"*) continue ;;
        *) echo "$repo" ;;
    esac
done
FILTER

chmod +x /tmp/filter-known.sh
cat /tmp/gateways-raw.txt | /tmp/filter-known.sh > ~/vata/new-gateways.txt

echo ""
echo "[+] New gateways found:"
cat ~/vata/new-gateways.txt

echo ""
echo "[*] Next: Clone and scan these"

