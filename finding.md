# HorizonShield Zero-Auth

Target: https://gate.horizonshield.dev/mcp
Severity: CRITICAL
Date: 2026-10-09

## Finding
MCP endpoint returns full tool list without authentication.

## Proof
GET https://gate.horizonshield.dev/mcp → HTTP 200 (no auth required)
Exposes 6 tools: get_conditions, check_conformance, verify_verdict, lookup_server, is_verified, preflight_agent

## Timeline
Vendor contacted: 2026-10-09
Deadline: 2026-10-39 (30 days)
Public: 2026-12-09 (90 days)
