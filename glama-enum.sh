#!/bin/bash
# Parse glama.ai for real MCP server endpoints from Crostini

echo "[*] Glama.ai Real MCP Server Enumeration"
echo "[*] Fetching from Crostini environment..."
echo ""

# Fetch glama.ai MCP servers page
curl -s "https://glama.ai/mcp/servers" -o /tmp/glama.html 2>/dev/null

if [ ! -s /tmp/glama.html ]; then
    echo "[-] Failed to fetch glama.ai"
    echo "[*] Trying alternative: MCP Directory GitHub"
    curl -s "https://raw.githubusercontent.com/modelcontextprotocol/servers/main/README.md" -o /tmp/mcp-readme.md
    exit 1
fi

echo "[+] Fetched $(wc -c < /tmp/glama.html) bytes"
echo ""

# Extract GitHub repos
echo "[*] Extracting GitHub repositories..."
grep -oP 'href="https://github\.com/[^"]+' /tmp/glama.html | sed 's/href="//g' | sort -u > /tmp/github-repos.txt

echo "    Found: $(wc -l < /tmp/github-repos.txt) repos"
echo ""
echo "[*] Top 20 MCP servers:"
head -20 /tmp/github-repos.txt

echo ""
echo "[*] Saving full list to ~/vata/glama-targets.txt"
cat /tmp/github-repos.txt > ~/vata/glama-targets.txt

