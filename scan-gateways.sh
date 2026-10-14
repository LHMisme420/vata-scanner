#!/bin/bash
# Clone and scan MCP gateways for zero-auth vulnerabilities

SCAN_DIR=~/vata/gateway-scans
mkdir -p $SCAN_DIR

echo "[*] MCP Gateway Scanning Campaign"
echo "[*] Output: $SCAN_DIR"
echo ""

# Read target list
count=0
while read repo; do
    [[ -z "$repo" ]] && continue
    count=$((count + 1))
    
    # Extract owner/name
    owner=$(echo "$repo" | cut -d/ -f1)
    name=$(echo "$repo" | cut -d/ -f2)
    
    echo "[$count] Cloning: $owner/$name"
    
    # Shallow clone
    git clone --depth 1 "https://github.com/$owner/$name" "$SCAN_DIR/$name" 2>&1 | grep -E "Cloning|error|fatal"
    
done < ~/vata/gateway-targets-clean.txt

echo ""
echo "[*] Cloned $(ls -d $SCAN_DIR/*/ 2>/dev/null | wc -l) gateways"
echo "[*] Running authscan on each..."

