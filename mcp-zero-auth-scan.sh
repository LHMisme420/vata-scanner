#!/bin/bash
set -euo pipefail

TARGET_URL="${1}"
VATA_FINDINGS_DIR="${VATA_FINDINGS_DIR:-.}"
TIMEOUT=10
INCLUDE_SENSITIVE=false
VERBOSE=false
AUTH_BYPASS=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_success() { echo -e "${GREEN}[+]${NC} $*"; }
log_info() { echo -e "${BLUE}[*]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $*"; }

[[ -z "$TARGET_URL" ]] && echo "Usage: $0 <target_url>" && exit 1

TARGET_URL="${TARGET_URL%/}"
[[ ! "$TARGET_URL" =~ ^https?:// ]] && TARGET_URL="http://$TARGET_URL"

log_info "Scanning: $TARGET_URL"

endpoints=(
    "/" "/api" "/api/resources" "/api/tools" "/api/credentials" 
    "/api/config" "/api/admin" "/health" "/status" "/api/prompts"
    "/list-resources" "/api/list-resources" "/read-resource" "/api/read-resource"
    "/call-tool" "/api/call-tool" "/users" "/api/users"
)

> zero-auth-findings.txt

for ep in "${endpoints[@]}"; do
    url="$TARGET_URL$ep"
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT "$url" 2>/dev/null || echo "000")
    
    if [[ "$code" == "200" ]]; then
        log_success "ZERO-AUTH: $ep (HTTP $code)"
        echo "URL: $url" >> zero-auth-findings.txt
        echo "CODE: $code" >> zero-auth-findings.txt
        echo "---" >> zero-auth-findings.txt
    fi
done

log_info "Done. Results in zero-auth-findings.txt"
