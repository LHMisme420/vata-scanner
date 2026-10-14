#!/bin/bash
TARGET="$1"
ATTACK="${2:-enumerate}"

[[ -z "$TARGET" ]] && echo "Usage: $0 <target> [enumerate|read-config|dump-users|full-chain]" && exit 1

case "$ATTACK" in
    enumerate)
        echo "[*] Enumerating endpoints on $TARGET"
        for ep in / /api /api/v1 /api/workspaces /api/projects /api/users /api/credentials /admin /config /settings; do
            code=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET$ep")
            [[ "$code" != "404" ]] && echo "[+] $ep: $code"
        done
        ;;
    *)
        echo "[-] Unknown attack"
        ;;
esac
