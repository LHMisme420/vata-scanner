#!/bin/bash
echo "[*] TIER 2 TARGETS - AUTH BYPASS PATTERNS"

while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    
    echo ""
    echo "[*] $target"
    
    # Test multiple patterns
    patterns=(
        ""
        "/api/auth"
        "/api/v1/auth"
        "/oauth/token"
        "/auth/token"
        "/v1/auth/token"
        "/authenticate"
        "/api/verify"
        "/admin"
        "/api/admin"
        "/.admin"
    )
    
    for pattern in "${patterns[@]}"; do
        url="$target$pattern"
        
        # Try different methods
        for method in GET POST PUT DELETE; do
            code=$(curl -s -X $method -o /dev/null -w "%{http_code}" --max-time 3 "$url" 2>/dev/null)
            
            if [[ "$code" =~ ^(200|201|400|500)$ ]]; then
                echo "[*] $method $pattern: HTTP $code"
                
                # Extract response if interesting
                if [[ "$code" == "200" ]] || [[ "$code" == "201" ]]; then
                    response=$(curl -s -X $method --max-time 3 "$url" 2>/dev/null)
                    if [[ -n "$response" ]]; then
                        echo "[DATA] $response" | head -20
                    fi
                fi
            fi
        done
    done
done < hunt-tier2.txt

