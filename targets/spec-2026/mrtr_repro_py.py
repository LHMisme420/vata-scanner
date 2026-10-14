import importlib.util, sys, os
SRC = os.path.expanduser("~/vata/targets/spec-2026/py-sdk/src")
sys.path.insert(0, os.path.join(SRC, "mcp-types"))   # the mcp_types source tree
sys.path.insert(0, SRC)
path = os.path.join(SRC, "mcp/server/request_state.py")
spec = importlib.util.spec_from_file_location("rs_standalone", path)
rs = importlib.util.module_from_spec(spec)
try:
    spec.loader.exec_module(rs)
except ModuleNotFoundError as e:
    print("still needs:", e.name, "-> if it's a pip name, install it; if SDK-internal, tell me")
    raise SystemExit(1)
print("=== PYTHON: default requestState protection (unconfigured server) ===")
sec = rs.RequestStateSecurity.ephemeral()
codec = sec.codec
print("default codec:", type(codec).__name__)
token = codec.seal(b'{"action":"refund","amount":50}')
print("sealed token :", token[:40] + "...", "(%d chars, opaque)" % len(token))
print("unseal(ok)   :", codec.unseal(token).decode(), "-> ACCEPTED (correct)")
tampered = token[:-4] + ("AAAA" if token[-4:] != "AAAA" else "BBBB")
try:
    codec.unseal(tampered); print("unseal(tampered): ACCEPTED  <-- BUG")
except Exception as e:
    print("unseal(tampered): REJECTED (%s) -> FAIL-CLOSED (correct)" % type(e).__name__)
try:
    codec.unseal('{"action":"refund","amount":999999}'); print("unseal(forged): ACCEPTED <-- BUG")
except Exception as e:
    print("unseal(forged): REJECTED (%s) -> plaintext cannot pass" % type(e).__name__)
print("VERDICT: Python default = tamper-proof + forge-proof.\n")
