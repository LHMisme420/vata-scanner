import crypto from 'crypto';
import fs from 'fs';

const finding = {
  target: "@modelcontextprotocol/server-everything",
  maintainer: "Anthropic (MCP reference implementation)",
  version_tested: "2.0.0",
  vulnerability_class: "CWE-918: Server-Side Request Forgery (SSRF)",
  component: "gzip-file-as-resource tool, validateDataURI() in dist/tools/gzip-file-as-resource.js",
  root_cause: "GZIP_ALLOWED_DOMAINS env var defaults to an empty string. The domain allowlist check is only applied when GZIP_ALLOWED_DOMAINS.length > 0, meaning in the default/unconfigured deployment case, no domain, hostname, or IP restriction is applied to fetch targets. Only URL protocol (http/https/data) is restricted. No block on private/link-local/loopback IP ranges or cloud metadata addresses (e.g. 169.254.169.254) exists at any configuration level.",
  impact: "Any agent connected to this server with default configuration can direct the server to fetch arbitrary internal or private-network URLs on its behalf via the gzip-file-as-resource tool, and receive the fetched content back as a gzip-compressed, base64-encoded resource. This is a classic SSRF primitive: in real deployments this could be used to reach cloud instance metadata services, internal admin panels, or other services intended to be reachable only from the host's local network.",
  repro_method: "Live process spawn of installed package (node dist/index.js) with minimal explicit environment (PATH, HOME only -- no inherited secrets, no GZIP_ALLOWED_DOMAINS set), real MCP initialize handshake, real gzip-file-as-resource tool call via JSON-RPC over stdio targeting a local HTTP stub standing in for a sensitive internal-only endpoint (never targeted real cloud infrastructure). Confirmed the stub's canary content was fetched, gzip-compressed, and returned verbatim in the tool response; decompressed and verified content match.",
  related_finding: "Filed alongside DSC-038 (CWE-200, get-env tool, same package) as a secondary finding originally flagged during that investigation; this advisory completes the live-repro confirmation that was pending at time of DSC-038 submission.",
  recommended_remediation: "Default GZIP_ALLOWED_DOMAINS to a restrictive value requiring explicit opt-in for any fetch target, rather than defaulting to unrestricted. Independently of domain allowlisting, block private/link-local/loopback IP ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 127.0.0.0/8, 169.254.0.0/16) and known cloud metadata addresses by default, regardless of allowlist configuration, consistent with standard SSRF mitigation guidance.",
  timestamp: new Date().toISOString(),
};

fs.writeFileSync('dsc_server_everything_ssrf_finding.json', JSON.stringify(finding, null, 2));
const hash = crypto.createHash('sha256').update(JSON.stringify(finding, Object.keys(finding).sort())).digest('hex');
console.log(JSON.stringify(finding, null, 2));
console.log(`\nManifest SHA-256: ${hash}`);
console.log(`Length: ${hash.length}`);
