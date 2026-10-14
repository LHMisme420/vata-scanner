#!/bin/bash
echo "[*] HackerOne Target Hunting"

while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$target" 2>/dev/null)
    
    if [[ "$code" == "200" ]] || [[ "$code" == "201" ]]; then
        echo "[+] ACCESSIBLE: $target (HTTP $code)"
        
        # Test for zero-auth
        ./mcp-zero-auth-poc.sh "$target" enumerate 2>/dev/null | grep -i "found\|accessible" && \
            echo "[!] POTENTIAL ZERO-AUTH: $target" >> h1-findings.txt
    fi
done < hackerone-targets.txt

echo "[*] Done. Check h1-findings.txt"
