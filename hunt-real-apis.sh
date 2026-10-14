#!/bin/bash
echo "[*] Hunting real API endpoints for zero-auth access"

while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    
    echo "[*] $target"
    
    # Test actual API endpoints (not just root)
    for ep in /api /v1 /v2 /models /predictions /inference /completions; do
        code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$target$ep" 2>/dev/null)
        
        if [[ "$code" == "200" ]] || [[ "$code" == "201" ]]; then
            echo "[+] ZERO-AUTH: $target$ep (HTTP $code)"
            
            # Extract response to see what's exposed
            response=$(curl -s --max-time 3 "$target$ep" 2>/dev/null)
            echo "$response" | head -20
            
            echo "[!] $target$ep" >> real-findings.txt
        fi
    done
done < big-fish-real.txt

echo ""
echo "[*] Results in real-findings.txt"
