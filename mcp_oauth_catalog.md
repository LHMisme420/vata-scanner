# VATA MCP OAuth Issuer Binding Vulnerability Catalog
**Status:** Building evidence base during disclosure period
**Updated:** 2026-10-15

## CONFIRMED VULNERABLE (Reported)

| Project | Status | Impact | Files | Issuer Binding |
|---------|--------|--------|-------|-----------------|
| AWS Strands Agents SDK | ✅ Reported to AWS VDP (Oct 6) | HIGH | strands-py, strands-ts | ❌ Missing |
| PrefectHQ/fastmcp | ✅ Reported to GitHub (Oct 15) | HIGH | client_credentials.py | ❌ Missing |
| LangChain (cascading) | Via fastmcp dependency | HIGH | MCPAdapter uses fastmcp | ❌ Inherited |

## SCANNING STRATEGY

**Phase 1: Direct implementations** (searching now)
- Repos that import `from mcp.client.auth.extensions.client_credentials`
- These are custom OAuth wrappers similar to Strands/fastmcp

**Phase 2: Dependent frameworks** (once we know what depends on fastmcp)
- All LangChain users
- Any framework using fastmcp.Client

**Phase 3: Ecosystem analysis**
- Count total affected users
- Document the vulnerability class
- Prepare ecosystem disclosure

## Findings Queue
- [ ] Anthropic SDK
- [ ] OpenAI SDK (✓ checked - no MCP code yet)
- [ ] Azure SDK
- [ ] Mistral client
- [ ] Other high-profile targets

