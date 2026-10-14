## Summary

Activepieces ships a well-designed, defense-in-depth SSRF protection system (ssrfGuard in packages/server/engine/src/lib/network/) that monkey-patches both dns.lookup/dns.promises.lookup and Socket.prototype.connect to block piece/flow HTTP requests from reaching internal, loopback, and link-local/metadata addresses. Two independent problems undermine it:

1. It is disabled by default. packages/server/api/src/app/helper/system/system.ts sets the default of AppSystemProp.NETWORK_MODE to NetworkMode.UNRESTRICTED, and no docker-compose.yml or helm chart in the repo overrides this to STRICT. ssrfGuard.install() (called once, unconditionally, in packages/server/engine/src/main.ts) only activates protection when AP_NETWORK_MODE === 'STRICT'. A standard, unmodified self-hosted deployment ships with zero SSRF protection.

2. Even when an operator explicitly sets AP_NETWORK_MODE=STRICT, the socket-level guard has a scope gap that lets literal-IP-address targets bypass it entirely. The guard patches Socket.prototype.connect, which correctly intercepts the pattern new net.Socket(); s.connect(...). But it does NOT intercept net.connect() / net.createConnection() -- the module-level convenience function that Node's own http and https modules use internally for every outbound request. This means http.get, https.request, global fetch(), axios, node-fetch, undici -- the entire realistic set of HTTP client patterns a piece would actually use -- routes through the one entry point the guard doesn't cover. Literal-IP SSRF (e.g. http://169.254.169.254/, http://127.0.0.1/) succeeds even in STRICT mode. The DNS-lookup guard, by contrast, works correctly, since dns.lookup patching is a genuinely global override regardless of which higher-level API calls it -- domain-name-based DNS rebinding is properly blocked.

## Affected version

0.86.3 (commit a452b7e67a58c7c3ee57ccedb3b1c678ac4a4c35, 2026-07-14)

## Live proof of concept

Ran the real, unmodified ssrf-guard.ts (plus its real dns-lookup-guard.ts, socket-connect-guard.ts, and ssrf-ip-classifier.ts) bundled directly from the cloned source, on the exact Node version Activepieces ships in its Dockerfile (node:24.14.0-bullseye-slim), using real http.get() calls (not raw socket calls) against a local marker service.

Scenario 1 -- default config, AP_NETWORK_MODE unset:
ssrfGuard.isEnabled(): false
http.get(http://127.0.0.1:8937/): { ok: true, body: 'DSC036_INTERNAL_SERVICE_REACHED_5c8d2e91' }

Scenario 2 -- AP_NETWORK_MODE=STRICT, domain-name target simulating DNS rebind:
ssrfGuard.isEnabled(): true
http.get(http://dsc036-rebind-test.invalid:8937/): { ok: false, error: 'SSRFBlockedError: SSRF blocked: dsc036-rebind-test.invalid (127.0.0.1)' }

Scenario 3 -- AP_NETWORK_MODE=STRICT, literal-IP target, same guard installation as Scenario 2:
ssrfGuard.isEnabled(): true
http.get(http://127.0.0.1:8937/): { ok: true, body: 'DSC036_INTERNAL_SERVICE_REACHED_5c8d2e91' }

Scenario 2 confirms the DNS-based protection genuinely works when enabled. Scenario 3, run immediately after with the identical guard state, confirms the literal-IP bypass is real and not a configuration or ordering artifact.

## Root cause

packages/server/engine/src/lib/network/socket-connect-guard.ts patches Socket.prototype.connect. Node's net.connect()/net.createConnection() -- used internally by http.request()/https.request() for every real HTTP client call -- does not dispatch through this patched prototype method for the connection-establishment path exercised here, so the guard's check (isBlockedRawIpTarget) never runs for that call pattern. Confirmed directly: new net.Socket() + .connect() is correctly blocked; net.connect() with identical target/guard state is not.

Separately, packages/server/api/src/app/helper/system/system.ts sets NETWORK_MODE's default to NetworkMode.UNRESTRICTED, and no shipped deployment config overrides it.

## Impact

Any piece or flow that fetches a user/flow-supplied URL (HTTP Request piece, webhook-triggered calls, any piece performing outbound HTTP as part of its normal function) can reach internal services, loopback, and link-local/metadata addresses:
- By default, unconditionally.
- Even with STRICT mode explicitly configured, via literal IP addresses in the target URL.

Only DNS-name-based targets are actually protected when STRICT mode is enabled.

## Suggested remediation

1. Default NETWORK_MODE to STRICT (or otherwise ship the SSRF guard enabled by default), documenting the opt-out for legitimate internal-network use cases instead of opt-in.
2. Extend socket-connect-guard.ts to intercept net.connect()/net.createConnection(), not only Socket.prototype.connect via direct instantiation -- or replace the prototype-patch approach with a lower-level hook (e.g. wrapping the internal connection-establishment function Node's net module actually calls) that covers both patterns.
