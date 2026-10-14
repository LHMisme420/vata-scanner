import crypto from 'crypto';
import fs from 'fs';

const finding = {
  target: "@modelcontextprotocol/server-everything",
  maintainer: "Anthropic (MCP reference implementation)",
  version_tested: "2.0.0",
  vulnerability_class: "CWE-200: Exposure of Sensitive Information to an Unauthorized Actor",
  component: "get-env tool, registerGetEnvTool() in dist/tools/get-env.js",
  root_cause: "The get-env tool returns the entire process.env verbatim via JSON.stringify(process.env, null, 2) with no filtering, redaction, or allowlist of safe-to-expose variable names. Tool is labeled readOnlyHint:true and described only as 'helpful for debugging MCP server configuration', giving no indication to an LLM or operator that it exposes full credential material.",
  impact: "Any agent connected to this server can retrieve the complete host process environment in a single unauthenticated tool call, including API keys, tokens, and other credentials present in the process environment. Live-repro confirmed: a planted canary secret (VATA_CANARY_SECRET) was returned verbatim via a single get-env tool call over real MCP JSON-RPC/stdio transport. The live repro also incidentally confirmed real production credentials present in the test operator's environment were returned in full -- underscoring that this is not a theoretical risk but a practical one for any deployment where the server process environment contains live secrets, which is the common case for developer and CI environments running MCP servers.",
  repro_method: "Live process spawn of installed package (node dist/index.js), real MCP initialize handshake, real get-env tool call via JSON-RPC over stdio. Canary secret planted in process environment prior to spawn; confirmed returned verbatim in tool response.",
  secondary_finding: "gzip-file-as-resource tool (SSRF-adjacent): GZIP_ALLOWED_DOMAINS env var defaults to empty string, meaning domain/IP allowlisting is opt-in rather than default-on. In default configuration, the tool will fetch any http/https URL on the server's behalf with no restriction on private IP ranges, localhost, or cloud metadata endpoints (e.g. 169.254.169.254). Fetch itself is otherwise well-hardened (size cap, timeout, protocol restriction to http/https/data). Not yet live-repro confirmed against a metadata-endpoint stand-in; flagged for follow-up.",
  recommended_remediation: "get-env: remove the tool entirely, or restrict output to a fixed allowlist of non-sensitive variable names relevant to server configuration debugging (e.g. NODE_ENV, PORT) rather than the full environment. gzip-file-as-resource: default GZIP_ALLOWED_DOMAINS to a safe restrictive value, or block private/link-local IP ranges and cloud metadata addresses by default regardless of allowlist configuration.",
  timestamp: new Date().toISOString(),
};

fs.writeFileSync('dsc_server_everything_getenv_finding.json', JSON.stringify(finding, null, 2));
const hash = crypto.createHash('sha256').update(JSON.stringify(finding, Object.keys(finding).sort())).digest('hex');
console.log(JSON.stringify(finding, null, 2));
console.log(`\nManifest SHA-256: ${hash}`);
console.log(`Length: ${hash.length}`);
