#!/usr/bin/env bash
# Usage: vata-new <slug> <repo-url>  -> creates ~/vata/triage/<slug> from template
set -uo pipefail
SLUG="${1:?usage: vata-new <slug> <repo-url>}"; REPO="${2:?need repo url}"
T=/home/lhmisme/vata/_template
DEST="/home/lhmisme/vata/triage/$SLUG"
[ -e "$DEST" ] && { echo "exists: $DEST"; exit 1; }
cp -r "$T" "$DEST"
rm -f "$DEST/vata-new.sh"
mv "$DEST/repro.sh.tmpl" "$DEST/repro.sh"; chmod +x "$DEST/repro.sh"
mv "$DEST/artifacts/FINDINGS.md.tmpl" "$DEST/artifacts/FINDINGS.md"
mv "$DEST/artifacts/TIMELINE.md.tmpl" "$DEST/artifacts/TIMELINE.md"
sed -i "s|__REPO_URL__|$REPO|g; s|__TARGET__|$SLUG|g" \
  "$DEST/artifacts/FINDINGS.md" "$DEST/artifacts/TIMELINE.md"
echo "scaffolded: $DEST"
echo "next: edit repro.sh (TARGET_REPO, build, flags, probes), then ./capture-provenance.sh <repo>"
