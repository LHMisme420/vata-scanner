#!/bin/bash

# Test code reuse across OAuth servers
# Usage: ./test-code-reuse.sh <authorization_endpoint> <token_endpoint> <client_id> <client_secret>

AUTH_EP="$1"
TOKEN_EP="$2"
CLIENT_ID="$3"
CLIENT_SECRET="$4"

echo "=== Code Reuse Hunt ==="
echo "Target: $AUTH_EP"
echo ""

# Step 1: Get authorization code
echo "[1] Requesting auth code..."
CODE=$(curl -s "$AUTH_EP?client_id=$CLIENT_ID&response_type=code&redirect_uri=http://localhost:8080&state=xyz" \
  -L -i | grep -oP 'code=\K[^&]+' | head -1)

echo "Code: $CODE"

if [ -z "$CODE" ]; then
  echo "Failed to get code"
  exit 1
fi

# Step 2: Redeem code (first use)
echo "[2] Redeeming code (first use)..."
RESPONSE1=$(curl -s -X POST "$TOKEN_EP" \
  -d "grant_type=authorization_code&code=$CODE&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&redirect_uri=http://localhost:8080" \
  -H "Content-Type: application/x-www-form-urlencoded")

echo "Response 1: $RESPONSE1"
TOKEN1=$(echo "$RESPONSE1" | grep -oP '"access_token"\s*:\s*"\K[^"]+')

if [ -z "$TOKEN1" ]; then
  echo "First redemption failed — likely code is invalid or server doesn't issue tokens this way"
  exit 1
fi

echo "Token 1: $TOKEN1"
echo ""

# Step 3: Replay the SAME code
echo "[3] Replaying code (should fail)..."
RESPONSE2=$(curl -s -X POST "$TOKEN_EP" \
  -d "grant_type=authorization_code&code=$CODE&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&redirect_uri=http://localhost:8080" \
  -H "Content-Type: application/x-www-form-urlencoded")

echo "Response 2: $RESPONSE2"
TOKEN2=$(echo "$RESPONSE2" | grep -oP '"access_token"\s*:\s*"\K[^"]+')

if [ -n "$TOKEN2" ]; then
  echo "⚠️  VULNERABILITY: Code reused! Second token issued!"
  echo "Token 1: $TOKEN1"
  echo "Token 2: $TOKEN2"
  exit 0
else
  echo "✅ SECURE: Code properly revoked after first use"
  exit 1
fi
