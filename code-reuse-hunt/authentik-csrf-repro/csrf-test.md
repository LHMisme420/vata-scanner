# Authentik State Parameter CSRF

## Proof of Concept

1. Create test OAuth2 client in Authentik
2. Craft auth request WITHOUT matching state
3. Exchange code without state validation
4. Token issued despite CSRF mismatch

## Root Cause

- `AuthorizationCode` model (models.py:593) does NOT store `state`
- `TokenRequest.parse()` (token/base.py:65) does NOT parse `state`
- No validation in token endpoint

## Fix

Add `state` field to AuthorizationCode:
```python
state = models.TextField(null=True, default=None)
```

Validate in token endpoint:
```python
if auth_code.state != request.POST.get("state"):
    raise TokenError("invalid_request")
```
