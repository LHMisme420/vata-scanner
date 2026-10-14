#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: hash-finding.sh <finding-slug>"
  exit 1
fi

BASE=~/vata/dual-repro/"$1"
if [ ! -d "$BASE" ]; then
  echo "Not found: $BASE"
  exit 1
fi

cd "$BASE"
find . -type f \( -name "*.sh" -o -name "*.md" \) -exec sha256sum {} \; > artifacts/sha256sums.txt
cat artifacts/sha256sums.txt
git add -A
git commit -q -m "hash update: $1" || echo "nothing new to commit"
