# VATA — Ttokkime/mcp-gateway: tenant-isolation findings

Target: github.com/Ttokkime/mcp-gateway
Vulnerable baseline: commit e2fa419ebeb38772c45a2b0e3cc83607b7e2cc92 (unmodified)
Researcher: Leroy / VATA — Receipts Over Promises

## Provenance (three layers)
1. Vulnerable gateway — pinned at e2fa419, NO local edits to gateway code.
   Verify: `git rev-parse HEAD` == artifacts/commit.txt
2. Test harness — mock_harness.patch (cmd/mockmcp/main.go only). Adds resource
   fixtures so the gateway has something to leak. Does NOT touch gateway logic.
3. Proposed fix — proxy_fix.patch (internal/config/config.go + internal/proxy/proxy.go).
All findings are in gateway code covered by layer 1. Layers 2–3 are additive and
separately captured, so "was this in the original?" is answerable per-file.

## Finding 1 — Method-scoped authorization (PRIMARY)
Claim: RBAC is enforced only on `tools/call`. Every other JSON-RPC method is
proxied to the upstream and marked Allowed. A scoped tenant reaches methods it
was never granted.
Root cause: internal/proxy/proxy.go — the gate was `if req.Method ==
mcp.MethodToolsCall { ... }`. internal/mcp/types.go documents the design as
"Everything else is passed through untouched." Authorization was an invocation
filter, not an access filter.
Receipts:
  01_scoped_toolslist_LEAK.json        scoped tenant enumerates full catalog
  04_scoped_resourceslist_LEAK.json    scoped tenant enumerates resources
  05a_scoped_read_secrets_LEAK.json    scoped tenant reads CI secrets
  05b_scoped_read_pii_*.json           scoped tenant reads customer PII
  05c_scoped_read_sse_LEAK.txt         scoped tenant reads PII via SSE
Controls (prove the gate is narrow, not broken):
  02_scoped_call_delete_all_DENIED.json  tools/call IS gated
  03_full_call_delete_all_ALLOWED.json   full tenant unaffected
Fix status: FIXED for resource/prompt egress (default-deny switch;
proxy_fix.patch). tools/list catalog still returns full set — response-side
filtering is PHASE 2, explicitly not covered by this patch.
Proposed CVSS (researcher assessment, vector for review — score to be finalized
in calculator, not asserted): AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:N/A:N — High band.
S:C because the vulnerable component (gateway) and impacted component (upstream
resource store) differ. C:H via resources/read; I left at N (writes not demoed).

## Finding 2 — Redactor emits invalid JSON (DoS of response body)
Claim: the PII redactor can corrupt the response envelope into unparseable JSON.
Root cause: internal/redact/redact.go — `Apply` runs `p.re.ReplaceAll(out, p.repl)`
directly on the SERIALIZED response bytes (comment redact.go:2: "runs on the
response body bytes"). The regex has no JSON awareness. When a pattern matches
text adjacent to a JSON escape (`\n`), the match consumes the escape's second
byte and orphans the `0x5C`, producing `\[REDACTED...`.
Receipts:
  05b_scoped_read_pii_REDACTOR_BROKE_JSON.json   invalid-JSON output
  05b_INVALID_JSON_evidence.hex                  bytes 5c5b at offsets 104,144
Mechanism confirmed from source + hex, not inferred. Content-triggerable.
Fix status: NOT fixed. Out of scope of the authz patch. After Finding 1 a SCOPED
tenant can no longer reach this path, but a WILDCARD tenant still can — the
redactor defect is unfixed, only masked for scoped callers.

## Finding 3 — Redactor coverage is email/cc/ssn only
Claim: only three PII shapes are scrubbed; secrets, keys, tokens, internal
hostnames egress raw.
Root cause: internal/redact/redact.go:29-32 defaultPatterns = {email, credit_card,
ssn}. Config had redaction.patterns=[] so defaults were in force.
Receipt: 05a_scoped_read_secrets_LEAK.json — raw AKIA... key + prod-db.internal
hostname present in response.
Fix status: NOT fixed (design note). Same masking caveat as Finding 2.

## Finding 4 — SSE / content-type bypasses redaction entirely
Claim: redaction only runs on application/json; an upstream answering
text/event-stream skips it.
Root cause: internal/proxy/proxy.go:221 gates redaction on
`strings.HasPrefix(ct, "application/json")`. Comments proxy.go:9-10 & 215-216
acknowledge SSE is streamed through untouched ("future work").
Receipt: 05c_scoped_read_sse_LEAK.txt — raw jane.doe@example.com in SSE frame.
Fix status: NOT fixed; maintainer-acknowledged in source comments. Same masking
caveat.

## Cross-cutting note
The redaction layer (Findings 2–4) is the only egress control on non-tools/call
paths, and it is bypassable three ways (wrong pattern, wrong content-type,
corruption). The authz fix (Finding 1) removes scoped-tenant reach to those
paths, which is the correct primary remediation — but the redactor defects
remain for wildcard tenants and should be fixed independently.

## Reproduce
  bash ~/vata/triage/repro_resources.sh        # vulnerable-state receipts (01,04,05*)
  # apply proxy_fix.patch, rebuild, then:
  bash /tmp/flip.sh                             # POST_FIX_flip.log — all egress -> DENIED
