import re, sys
p = "/home/lhmisme/vata/triage/mcp-gateway/cmd/mockmcp/main.go"
s = open(p).read()

# Remove any prior resources/list + resources/read handlers (clean re-patch).
for meth in ("resources/list", "resources/read"):
    pat = re.compile(r'\s*if req\.Method == "' + re.escape(meth) + r'" \{.*?\n {8}\}\n', re.S)
    s = pat.sub("\n        ", s, count=1)

anchor = 'if req.Method == "tools/list" {'
assert anchor in s, "tools/list anchor missing"

branch = r'''if req.Method == "resources/list" {
            _ = json.NewEncoder(w).Encode(map[string]any{
                "jsonrpc": "2.0", "id": req.ID,
                "result": map[string]any{"resources": []map[string]any{
                    {"uri": "file:///vault/customer-pii.txt", "name": "customer-pii",
                     "description": "Customer PII export (RESTRICTED)", "mimeType": "text/plain"},
                    {"uri": "file:///vault/deploy-secrets.env", "name": "deploy-secrets",
                     "description": "CI deploy secrets (RESTRICTED)", "mimeType": "text/plain"},
                }},
            })
            return
        }
        if req.Method == "resources/read" {
            var pr struct{ Params struct{ URI string ` + "`json:\"uri\"`" + ` } ` + "`json:\"params\"`" + ` }
            _ = json.Unmarshal(body, &pr)
            // SSE variant: if caller asks for the .env, stream it as text/event-stream
            // to demonstrate the redaction content-type bypass.
            if pr.Params.URI == "file:///vault/deploy-secrets.env" {
                w.Header().Set("Content-Type", "text/plain")
                secret := ` + "`" + `AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
DB_HOST=prod-db.internal.acme.corp` + "`" + `
                _ = json.NewEncoder(w).Encode(map[string]any{
                    "jsonrpc": "2.0", "id": req.ID,
                    "result": map[string]any{"contents": []map[string]any{
                        {"uri": pr.Params.URI, "mimeType": "text/plain", "text": secret},
                    }},
                })
                return
            }
            pii := ` + "`" + `ACME Corp customer export
jane.doe@example.com,4111-1111-1111-1111
john.roe@example.com,5555-5555-5555-4444` + "`" + `
            _ = json.NewEncoder(w).Encode(map[string]any{
                "jsonrpc": "2.0", "id": req.ID,
                "result": map[string]any{"contents": []map[string]any{
                    {"uri": "file:///vault/customer-pii.txt", "mimeType": "text/plain", "text": pii},
                }},
            })
            return
        }
        '''
s = s.replace(anchor, branch + anchor, 1)
open(p, "w").write(s)
print("re-patched clean:", p)
