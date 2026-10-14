---
name: mcp-authscan
description: Static vulnerability scanner for OAuth/auth failures in MCP servers
version: 1.0.0
author: Leroy (RU∞X)
---

# mcp-authscan

OAuth vulnerability detector for MCP servers.

- Unvalidated redirect_uri
- Missing PKCE enforcement  
- Authorization code replay
- Missing client authentication

## Install

npm install -g mcp-authscan

## Usage

mcp-authscan /path/to/server
