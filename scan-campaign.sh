#!/bin/bash
# MCP Gateway Security Audit - VATA Program

SCAN_DIR=~/vata/gateway-scans
mkdir -p "$SCAN_DIR"

echo "[*] MCP Gateway Scanning Campaign - VATA"
echo "[*] Scanning 26 new gateway implementations"
echo "[*] Output dir: $SCAN_DIR"
echo ""

# Priority order (high-value targets first)
PRIORITY=(
    "aws/mcp-proxy-for-aws"
    "docker/mcp-gateway"
    "sigbit/mcp-auth-proxy"
    "tuannvm/oauth-mcp-proxy"
    "enkryptai/secure-mcp-gateway"
    "gatekit-ai/gatekit"
    "chatmcp/mcprouter"
)

echo "[*] PRIORITY TARGETS (scanning first):"
for repo in "${PRIORITY[@]}"; do
    echo "    - $repo"
done

echo ""
echo "[*] Starting clone+scan..."

count=0
while read repo; do
    [[ -z "$repo" ]] && continue
    count=$((count + 1))
    
    name=$(basename "$repo")
    
    echo "[$count/26] $name... " | tr -d '\n'
    
    # Clone shallow
    if git clone --depth 1 "https://$repo.git" "$SCAN_DIR/$name" >/dev/null 2>&1; then
        echo "[CLONED]"
        
        # Quick auth vulnerability scan
        if [ -f ~/vata/mcp_authscan.py ]; then
            timeout 10 python3 ~/vata/mcp_authscan.py "$SCAN_DIR/$name" --include-tests 2>&1 | grep -i "finding\|vulnerability\|error" | head -3
        else
            # Just look for auth patterns
            grep -r "no.*auth\|zero.*auth\|public.*endpoint" "$SCAN_DIR/$name" 2>/dev/null | head -1 && echo "  [!] Zero-auth pattern found" || echo "  [OK]"
        fi
    else
        echo "[FAILED]"
    fi
    
done < ~/vata/gateway-targets-clean.txt

echo ""
echo "[*] Scan complete"
echo "[*] Detailed results in: $SCAN_DIR"
echo "[*] Next: Analyze findings and prep HackerOne submissions"

