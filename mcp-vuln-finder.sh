#!/bin/bash

# Targeted MCP vulnerability finder
# Looks for: zero-auth endpoints, bypass patterns, IDOR

echo "[*] MCP VULNERABILITY FINDER"
echo ""

# Focus on the ones with FEWER auth patterns (likely gaps)
TARGETS=(
  "https://github.com/microsoft/playwright-mcp"  # Only 28 auth patterns
  "https://github.com/ChromeDevTools/chrome-devtools-mcp"  # 260 patterns
)

for repo in "${TARGETS[@]}"; do
  name=$(echo "$repo" | cut -d'/' -f5)
  echo "[*] DEEP SCAN: $name"
  echo ""
  
  git clone --quiet "$repo" "/tmp/$name" 2>/dev/null
  
  # Find server setup code (where auth would be configured)
  echo "[*] Server initialization..."
  find "/tmp/$name" -name "*.ts" -o -name "*.js" | xargs grep -l "createServer\|listen\|http\|express\|fastify" 2>/dev/null | head -3
  
  # Look for routes/endpoints with NO auth check
  echo "[*] Checking endpoints for missing auth..."
  grep -r "app\.\(get\|post\|put\|delete\)" "/tmp/$name" 2>/dev/null | grep -v "auth\|token\|bearer" | head -10
  
  # Check for hardcoded credentials or defaults
  echo "[*] Looking for weak/default auth..."
  grep -r "password\|api_key\|secret" "/tmp/$name" 2>/dev/null | grep -v "test\|mock\|example" | head -5
  
  echo ""
  rm -rf "/tmp/$name"
done
