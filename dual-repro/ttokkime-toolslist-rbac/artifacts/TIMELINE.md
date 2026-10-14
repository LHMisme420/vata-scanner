# Disclosure timeline — Ttokkime/mcp-gateway tenant-isolation findings

All times America/Chicago. Factual events below are fixed. Disclosure posture
(coordinated vs. self-published) is UNDECIDED — see DECISION block.

## Events (fixed)
2026-09-29  Initial finding: tools/list catalog leak for scoped tenant (01).
            tools/call gate confirmed working (02/03). Root cause isolated to
            proxy.go method-scoped RBAC gate. Snapshots + commit.txt captured
            at e2fa419.
2026-09-30  Confirmed same root reaches resources/read: secret egress (05a),
            PII + redactor-JSON-corruption (05b), SSE redaction bypass (05c),
            resource enumeration (04). Findings 2–4 identified and root-caused.
            Proposed fix authored (proxy_fix.patch); POST_FIX_flip.log shows all
            egress paths -> DENIED with controls intact. Provenance three-layer.

## DECISION — required before any external step
[ ] Posture: COORDINATED  or  SELF-PUBLISHED
    - Coordinated: notify maintainer, private detail, embargo window, public on
      fix-or-timeout. Aligns with "Receipts Over Promises."
    - Self-published: Zenodo DOI now, maintainer notified in parallel.
[ ] If coordinated: contact channel identified? (repo SECURITY.md / email / issue)
[ ] Embargo length decided? (e.g. 90 days or fix-first)

## Pending (fill as they happen)
____-__-__  Maintainer notified via ____________
____-__-__  Maintainer acknowledged
____-__-__  Fix released / advisory published
____-__-__  Public disclosure (Zenodo DOI: __________)
____-__-__  VATA dashboard updated
