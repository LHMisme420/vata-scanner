#!/bin/bash
# Direct Agensi MCP server scanning

echo "[*] Agensi MCP Scanner (Direct Method)"

# Known Agensi MCP servers from search/browsing
# These are public marketplace listings

targets=(
    "https://mcp-demo.agensi.ai"
    "https://mcp-test.agensi.ai"
    "https://api.agensi.ai/mcp"
    "https://registry.agensi.ai"
    "https://glama.ai/mcp/servers"
)

echo "[*] Testing known Agensi endpoints..."

> agensi-direct-findings.txt

for target in "${targets[@]}"; do
    echo "[*] $target"
    
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$target" 2>/dev/null)
    
    if [[ "$code" != "000" ]]; then
        echo "    HTTP $code"
        
        if [[ "$code" != "401" ]] && [[ "$code" != "403" ]]; then
            echo "[+] ACCESSIBLE: $target" >> agensi-direct-findings.txt
        fi
    fi
done

cat agensi-direct-findings.txt
