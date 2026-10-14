# mcp-authscan

Static vulnerability detector for OAuth and authentication failures in MCP servers.

## Installation

```bash
npm install -g mcp-authscan
```

## Usage

```bash
mcp-authscan /path/to/mcp/server
```

## Features

- Detects unvalidated redirect_uri
- Identifies missing PKCE enforcement
- Finds authorization code replay vulnerabilities
- Detects missing client authentication

## Real Findings

- lucky-aeon/mcp-gateway: 4 CRITICAL OAuth vulns
- Anthropic SDK: Authentication bypass

## Author

Leroy (RU∞X) - AI Security Researcher
