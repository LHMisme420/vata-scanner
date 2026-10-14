#!/usr/bin/env bash
# Usage: ./capture-provenance.sh /path/to/target/repo [file-to-diff ...]
# Pins HEAD to artifacts/commit.txt and captures working-tree diffs as layers.
set -uo pipefail
SRC="${1:?usage: capture-provenance.sh <repo> [files...]}"; shift || true
A="$(cd "$(dirname "$0")/artifacts" && pwd)"
git -C "$SRC" rev-parse HEAD > "$A/commit.txt"
git -C "$SRC" log -1 --format='%H %ci %s' >> "$A/commit.txt"
echo "baseline pinned: $(head -1 "$A/commit.txt")"
if [ "$#" -gt 0 ]; then
  git -C "$SRC" diff -- "$@" > "$A/working_tree.patch"
  echo "layer diff: $(wc -l < "$A/working_tree.patch") lines over: $*"
fi
echo "--- dirty files (confirm only expected files) ---"
git -C "$SRC" status --short
