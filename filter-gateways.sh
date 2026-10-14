#!/bin/bash

echo "[*] Filtering real MCP gateway targets..."

# Clean up the list - remove stargazers, topics, and non-repo pages
cat ~/vata/new-gateways.txt | \
    grep -v "/stargazers" | \
    grep -v "/topics/" | \
    grep -v "/search/" | \
    sort -u > ~/vata/gateway-targets-clean.txt

echo "[+] Real gateway implementations:"
cat ~/vata/gateway-targets-clean.txt

echo ""
echo "[*] Top priority targets (highest risk):"
echo "    - aws/mcp-proxy-for-aws (AWS = high value target)"
echo "    - docker/mcp-gateway (Docker = widely used)"
echo "    - sigbit/mcp-auth-proxy (auth proxy = likely auth bugs)"
echo "    - tuannvm/oauth-mcp-proxy (OAuth = your specialty)"
echo "    - enkryptai/secure-mcp-gateway (security = false confidence)"
echo "    - gatekit-ai/gatekit (established project)"
echo ""
echo "[*] Total unique gateways: $(wc -l < ~/vata/gateway-targets-clean.txt)"

