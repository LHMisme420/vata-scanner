#!/bin/bash
while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    
    # Quick test
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$target" 2>/dev/null)
    
    if [[ "$code" == "200" ]] || [[ "$code" == "201" ]]; then
        echo "[ZERO-AUTH] $target: HTTP $code"
    elif [[ "$code" =~ ^(301|302|307)$ ]]; then
        # Follow redirects
        final=$(curl -s -L -o /dev/null -w "%{http_code}" --max-time 3 "$target" 2>/dev/null)
        [[ "$final" == "200" ]] && echo "[REDIRECT-200] $target: $code → $final"
    fi
done < targets-all.txt
