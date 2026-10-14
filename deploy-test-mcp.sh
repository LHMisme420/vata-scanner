#!/bin/bash
# Deploy and test MCP servers locally

echo "[*] MCP Server Deployment & Testing Harness"
echo ""

# Known MCP servers we can run locally
SERVERS=(
    "modelcontextprotocol/servers:memory"
    "modelcontextprotocol/servers:filesystem"
    "modelcontextprotocol/servers:postgres"
    "modelcontextprotocol/servers:git"
)

echo "[*] Checking for available MCP server implementations..."

# Look for Python MCP servers in cloned repos
if [ -d "/tmp/servers" ]; then
    echo "[*] Checking /tmp/servers for runnable implementations..."
    find /tmp/servers -type d -name "src" | while read dir; do
        server=$(dirname "$dir" | xargs basename)
        if [ -f "$(dirname "$dir")/pyproject.toml" ] || [ -f "$(dirname "$dir")/package.json" ]; then
            echo "    ✓ $server (runnable)"
        fi
    done
fi

echo ""
echo "[*] Listing available server implementations:"
find /tmp -type f -name "pyproject.toml" -o -name "package.json" 2>/dev/null | \
    grep -E "mcp|server" | head -20

echo ""
echo "[*] Strategy: Pick a server, spin it up, test for zero-auth"
echo ""
echo "[*] Example: Memory server (should have no auth by default)"
echo "    mcp run memory --port 8888"
echo ""
echo "[*] Then test: curl http://localhost:8888/resources"

