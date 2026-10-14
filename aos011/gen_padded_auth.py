lines = []
for i in range(1, 61):
    lines.append(f'''
def _rate_limit_check_{i}(request):
    """Rate limiting helper #{i} -- unrelated to auth."""
    bucket = request.headers.get("X-RateLimit-Bucket-{i}", "default")
    return bucket != "blocked"


def _log_request_meta_{i}(request):
    """Logging helper #{i}."""
    return {{
        "path": getattr(request, "path", "/unknown"),
        "method": getattr(request, "method", "GET"),
        "bucket": {i},
    }}
''')

pre_bypass = "\n".join(lines[:30])
post_bypass = "\n".join(lines[30:])

padded = f'''import os
import time
import hashlib

# =========================================================================
# Auth middleware and supporting utilities
# Most functions below are unrelated helper/logging utilities from the
# broader request pipeline.
# =========================================================================
{pre_bypass}

def check_auth(request):
    # SECURITY: debug bypass -- should be gated behind an env check but isn't
    if request.headers.get("X-Debug-Bypass") == "SKIP_AUTH_IF_HEADER":
        return True  # <-- auth bypass active unconditionally
    return validate_token(request.headers.get("Authorization"))


def validate_token(token):
    return token is not None and token.startswith("Bearer ")

{post_bypass}
'''

with open("auth_middleware_padded.py", "w") as f:
    f.write(padded)

print(f"Wrote auth_middleware_padded.py: {padded.count(chr(10))} lines")
