#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: new-finding.sh <finding-slug>"
  echo "Example: new-finding.sh metamcp-admin-scope"
  exit 1
fi

SLUG="$1"
BASE=~/vata/dual-repro/"$SLUG"

if [ -d "$BASE" ]; then
  echo "Directory already exists: $BASE"
  exit 1
fi

mkdir -p "$BASE"/{human,model,artifacts}
cd "$BASE"

touch human/repro.sh
chmod +x human/repro.sh

cat > model/repro_prompt.md << 'EOF'
You are given a claimed vulnerability. Do not assume it is real.

CLAIM: [paste claim here]

CODE: [paste relevant code here]

TASKS:
1. State whether the code as shown supports the claim. Quote the
   specific lines that do or don't.
2. Classify: does this require attacker-controlled input, or does
   simply owning ANY endpoint/resource trigger it?
3. Assign a CWE and a rough severity band, with reasoning.
4. Note anything that would prevent exploitation in practice
   (auth middleware upstream, tenant isolation elsewhere, etc.)
   that isn't shown in this snippet.
5. State your confidence (low/med/high) and what evidence would
   raise it.

Answer only from the code given. Do not speculate beyond it.
EOF

touch model/model_output.md
touch artifacts/sha256sums.txt

cat > DISCLOSURE.md << EOF
# $SLUG

## Summary


## Technical Detail


## Impact


## Independent Verification

**Human repro:** [pass/fail], see human/repro.sh
**Model repro:** [agree/disagree with claim], confidence: [x]

Model's stated reasoning: [1-2 sentence paraphrase, link to model/model_output.md]

Where human and model assessments diverge: [note plainly]

Artifact hashes: see artifacts/sha256sums.txt (anchored tx: [sepolia tx hash])
EOF

git init -q
git add .
git commit -q -m "dual-repro: $SLUG scaffold"

echo "Scaffolded: $BASE"
echo "Next: fill in human/repro.sh and model/repro_prompt.md, then run hash-finding.sh $SLUG"
