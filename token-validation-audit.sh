#!/bin/bash
# Token validation gaps hunter

gateway=$1
name=$(basename "$gateway")

echo "[*] Auditing: $name"
echo ""

# Check 1: Token endpoint validation
echo "  [1] Token endpoint - does it validate request signatures?"
grep -r "validate.*token\|verify.*signature\|check.*hmac" "$gateway" --include="*.py" --include="*.go" --include="*.js" | grep -v "test\|comment" | wc -l | xargs echo "      Found validation checks:"

# Check 2: Scope validation
echo "  [2] Scope escalation - can attacker request higher scopes?"
grep -r "scope.*validate\|check.*scope\|allowed.*scope" "$gateway" --include="*.py" --include="*.go" --include="*.js" | wc -l | xargs echo "      Scope validations:"

# Check 3: Token reuse/replay
echo "  [3] Token reuse - is 'used' flag set after token validation?"
grep -r "used.*true\|mark.*used\|replay.*check" "$gateway" --include="*.py" --include="*.go" --include="*.js" | wc -l | xargs echo "      Reuse protections:"

# Check 4: Zero-auth endpoints
echo "  [4] Zero-auth endpoints - any public token endpoints?"
grep -r "GET.*token\|POST.*token" "$gateway" --include="*.py" --include="*.go" --include="*.js" | grep -v "auth\|require\|validate" | head -3

echo ""
