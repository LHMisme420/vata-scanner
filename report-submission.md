# Hydra CVE Submission - Responsible Disclosure

## Reporting Channels (in order of preference)

### 1. Ory Security Contact (Primary)
- Email: security@ory.sh
- Method: Direct email to security team
- Expected response time: 5-7 days

### 2. Ory HackerOne Program
- URL: https://hackerone.com/ory
- Method: Submit via HackerOne platform
- Structured disclosure with timeline tracking

### 3. GitHub Security Advisory
- URL: https://github.com/ory/hydra/security/advisories
- Method: Create draft security advisory
- Notifies maintainers directly

### 4. NVD (National Vulnerability Database)
- Only after vendor has patched or declined
- Shows public record of vulnerability

## Recommended: Email to security@ory.sh

### Email Template

Subject: Security Vulnerability Report - Hydra OAuth2 Redirect URI Port Bypass

Body:
---
To the Ory Security Team,

I've discovered a vulnerability in Hydra's OAuth2 redirect URI validation that allows authorization code interception through port bypass on loopback addresses.

**Vulnerability Summary:**
- Component: fosite/authorize_helper.go - isMatchingAsLoopback()
- Type: OAuth2 Authorization Code Interception
- Severity: High
- Impact: Account compromise, user session hijacking

**Technical Details:**
When a client registers a loopback redirect URI with a specific port (e.g., http://127.0.0.1:3000/callback), Hydra incorrectly allows redirect to any port on the same loopback address (e.g., http://127.0.0.1:9999/callback).

**Proof of Concept:**
- Registered: http://127.0.0.1:3000/callback
- Bypass: http://127.0.0.1:9999/callback → ALLOWED (should be BLOCKED)

**Root Cause:**
isMatchingAsLoopback() skips port validation entirely for loopback addresses. While RFC 8252 allows port flexibility for dynamic discovery, it should not bypass registered port restrictions.

**Attack Scenario:**
1. Attacker intercepts OAuth request, modifies redirect_uri to attacker-controlled port
2. User authorizes on Hydra
3. Code sent to attacker's port instead of legitimate app
4. Attacker exchanges code for access token, gains account access

**Remediation Suggestion:**
Require port match when a specific port is registered:
```go
if registered.Port() != "" && registered.Port() != requested.Port() {
    return false
}
```

**Responsible Disclosure:**
I'm following responsible disclosure practices. Please advise on:
- Timeline for patch
- CVE assignment
- Public disclosure date

I'll keep this vulnerability confidential until you publish a fix.

Attached: Full technical analysis and PoC code

Best regards,
[Your name/handle]
---

## What to Attach
1. hydra-redirect-port-bypass.md (full technical report)
2. PoC code files
3. Test cases demonstrating bypass

## Timeline After Submission
- Day 1-5: Vendor reviews, may request clarification
- Day 5-30: Vendor works on patch
- Day 30: Vendor releases patch OR declines
- Day 30-90: Public disclosure (if patch released)
- Day 90+: Public disclosure regardless (if no response)

## Document Everything
Record:
- Date submitted
- Contact email
- Response received
- Timeline agreed
- Patch release date
- CVE assigned
- Public disclosure date

This becomes your VATA finding record.
