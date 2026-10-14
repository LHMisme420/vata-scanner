# VATA-007: Bearer Token Timing Attack via Example Implementation

## Discovery
- **File:** `anthropic-sdk/docs_src/authorization/tutorial001.py`
- **Line:** 13-15
- **Severity:** HIGH (CVSS ~7.5)
- **Class:** B-series (OAuth credential handling)

## Vulnerable Code
```python
class StaticTokenVerifier(TokenVerifier):
    async def verify_token(self, token: str) -> AccessToken | None:
        return KNOWN_TOKENS.get(token)  # Uses == comparison (not timing-safe)
```

## The Attack
1. Attacker submits Bearer tokens with different prefixes
2. Measures response time to each request
3. Identifies prefix when timing slightly increases (==  match proceeds further)
4. Iteratively builds token character-by-character
5. Successfully guesses valid token without brute-forcing all possibilities

## Impact
- Unauthorized access if tokens are weak/predictable
- Bypasses intended security model if timing variance is significant
- Affects any implementation copying this example pattern

## Proof of Concept
```python
import time

# Simulating timing attack
tokens_to_try = ["a", "b", "c", "..."]
for candidate in tokens_to_try:
    start = time.time()
    result = verify_token(candidate)  # Uses dict.get()
    elapsed = time.time() - start
    if elapsed > threshold:  # Longer = closer match
        print(f"Candidate {candidate} is valid prefix")
```

## Remediation
```python
import hmac
import hashlib

class SecureTokenVerifier(TokenVerifier):
    async def verify_token(self, token: str) -> AccessToken | None:
        stored = KNOWN_TOKENS.get(token)
        if not stored:
            return None
        # Use timing-safe comparison
        if not hmac.compare_digest(token, stored.token):
            return None
        return stored
```

## References
- CWE-208: Observable Timing Discrepancy
- Anthropic SDK docs: `docs_src/authorization/tutorial001.py`
