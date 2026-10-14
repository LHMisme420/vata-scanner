# OAuth2 Redirect URI Port Bypass in Hydra

## Vulnerability
Hydra's redirect URI validation allows attackers to bypass the registered callback URI by specifying a different port on loopback addresses (127.0.0.1, ::1, localhost IP).

## Severity
Medium - Allows authorization code interception on shared loopback interface

## Root Cause
`fosite/authorize_helper.go:isMatchingAsLoopback()` skips port validation for loopback addresses to support native apps per RFC 8252, but doesn't restrict to registered ports.

## Proof of Concept
- Registered: `http://127.0.0.1/callback`
- Bypass: `http://127.0.0.1:9999/callback` → ALLOWED
- Result: Authorization code sent to attacker's port

## Impact
- OAuth authorization codes can be redirected to attacker-controlled loopback port
- Requires attacker control of redirect_uri parameter in authorization request
- Affects applications using loopback redirect URIs

## Affected Code
`fosite/authorize_helper.go` lines 180-200 (isMatchingAsLoopback function)

## Recommendation
Restrict loopback port matching to registered ports, or require explicit port in redirect_uri.
