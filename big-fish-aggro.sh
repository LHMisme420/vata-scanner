#!/bin/bash
# Test for OBVIOUS zero-auth patterns others missed

echo "[*] Testing OBVIOUS zero-auth endpoints on big fish"

# Common endpoints that devs leave unprotected
endpoints=(
    "/"
    "/api"
    "/api/v1"
    "/mcp"
    "/status"
    "/health"
    "/config"
    "/debug"
    "/metrics"
    "/swagger"
    "/docs"
    "/openapi.json"
    "/.well-known"
)

# Big fish that might have slipped
targets=(
    "https://api.openai.com"
    "https://api.anthropic.com"
    "https://api.claude.ai"
    "https://api.mistral.ai"
    "https://api.perplexity.ai"
    "https://api.together.ai"
    "https://api.replicate.com"
    "https://api.huggingface.co"
    "https://api.cohere.com"
    "https://api.aleph-alpha.com"
)

for target in "${targets[@]}"; do
    echo ""
    echo "[*] $target"
    
    for ep in "${endpoints[@]}"; do
        code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$target$ep" 2>/dev/null)
        
        if [[ "$code" == "200" ]] || [[ "$code" == "201" ]]; then
            echo "[!] ZERO-AUTH: $ep (HTTP $code)"
            
            # Extract what's there
            curl -s "$target$ep" | head -100 >> "findings/$target-$ep.txt" 2>/dev/null
        fi
    done
done

