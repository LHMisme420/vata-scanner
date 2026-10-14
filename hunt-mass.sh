#!/bin/bash
while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    
    echo "[*] $target"
    
    # Quick zero-auth test
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$target" 2>/dev/null)
    
    if [[ "$code" == "200" ]] || [[ "$code" == "201" ]]; then
        echo "[+] ZERO-AUTH FOUND: $target (HTTP $code)"
        
        # Extract response
        curl -s "$target" | head -100 > "finding-$(echo $target | md5sum | cut -d' ' -f1).txt"
        
        # Run POC
        ./mcp-zero-auth-poc.sh "$target" enumerate >> findings-log.txt
    fi
done < targets-to-hunt.txt
