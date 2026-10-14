#!/bin/bash
FILE="${HOME}/.khealth-hunt"
[ ! -f "$FILE" ] && echo "KHEALTH HUNT CHECKLIST - $(date)" > "$FILE"

case "$1" in
  init) echo "HUNT INITIALIZED - $(date)" >> "$FILE"; cat "$FILE" ;;
  show) cat "$FILE" ;;
  mark) echo "✓ $2 - $(date)" >> "$FILE" ;;
  tips) echo "VATA: Reproducible > Theory | Code > Words | Chain vulns | Stop on PII | Document all" ;;
  *) echo "Usage: $0 {init|show|mark|tips}" ;;
esac
