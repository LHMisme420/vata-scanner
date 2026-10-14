#!/bin/bash
# New MCP gateway attack surface - live exploitation angles

echo "[*] MCP Gateway Exploitation Angles - VATA"
echo "[*] 10:39 AM - Fresh vectors for 25 gateways"
echo ""

# ANGLE 1: OAuth DCR (Dynamic Client Registration) abuse
echo "[*] ANGLE 1: OAuth DCR bypass"
echo "    - Many gateways support auto-registration"
echo "    - Can we register malicious clients?"
echo "    - Check: POST /oauth/register with crafted payloads"
echo ""

# ANGLE 2: Cross-tenant isolation breakout
echo "[*] ANGLE 2: Multi-tenant breakout"
echo "    - You found this in metamcp already"
echo "    - Check: Can we access other tenant's servers?"
echo "    - Test: /api/servers?tenant=OTHER_TENANT"
echo ""

# ANGLE 3: SSRF through MCP tool execution
echo "[*] ANGLE 3: SSRF chain via tool calls"
echo "    - Call MCP tools with SSRF payloads"
echo "    - If gateway forwards tool requests unvalidated"
echo "    - Test: /api/tools/execute with url='http://localhost:internal'"
echo ""

# ANGLE 4: Redirect URI bypass → token theft
echo "[*] ANGLE 4: OAuth redirect open redirect"
echo "    - You found redirect_uri validation gaps in Authlib"
echo "    - Check: POST /oauth/authorize?redirect_uri=evil.com"
echo "    - Can we steal tokens via open redirect?"
echo ""

# ANGLE 5: Session fixation / replay
echo "[*] ANGLE 5: State/PKCE validation weaknesses"
echo "    - Reuse old state tokens"
echo "    - Weak PKCE code_verifier generation"
echo "    - Test: /oauth/callback?code=OLD&state=REUSED"
echo ""

echo "[*] Pick one. Build an exploit."
echo ""

