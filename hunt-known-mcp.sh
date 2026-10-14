#!/bin/bash
# Hunt known public MCP servers from GitHub

echo "[*] Known MCP Server Hunter"
echo "[*] Scanning public MCP implementations for zero-auth"
echo ""

# Known public MCP servers to test
TARGETS=(
    "https://github.com/modelcontextprotocol/servers"  # Official MCP servers
    "https://github.com/anthropics/anthropic-sdk-python"  # Anthropic SDK
    "https://github.com/mcpjs/sdk"  # MCP JS SDK
)

echo "[*] Cloning target repositories..."

for repo in "${TARGETS[@]}"; do
    name=$(basename "$repo" .git)
    echo "[*] $name"
    
    # Quick clone (shallow)
    git clone --depth 1 "$repo" "/tmp/$name" 2>&1 | grep -E "Cloning|error" || echo "    ✓"
done

echo ""
echo "[*] Searching for server endpoints and auth patterns..."

# Look for hardcoded endpoints, test servers, MCP implementations
echo "[*] Found server definitions:"
find /tmp -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" \) -exec grep -l "mcp.*server\|MCP.*endpoint\|/mcp_" {} \; 2>/dev/null | head -20

echo ""
echo "[*] Searching for zero-auth patterns..."
grep -r "no.*auth\|zero.*auth\|public.*endpoint\|@app.get.*mcp" /tmp --include="*.py" --include="*.js" 2>/dev/null | head -10

