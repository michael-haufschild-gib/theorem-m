#!/usr/bin/env bash
# Axiom + sorry audit for the Theorem M formalization.
# Fails (exit 1) if theorem_M or theorem_M_aeval depends on anything
# beyond [propext, Classical.choice, Quot.sound], or if any actual
# `sorry` term appears in the Lean tree.
set -euo pipefail

FORMAL_DIR="$(cd "$(dirname "$0")/../formal" && pwd)"
command -v lake > /dev/null 2>&1 || export PATH="$HOME/.elan/bin:$PATH"
SCRATCH="$(mktemp -t axcheck-XXXXXX).lean"
trap 'rm -f "$SCRATCH"' EXIT

cat > "$SCRATCH" << 'EOF'
import TheoremM
#print axioms TheoremM.theorem_M
#print axioms TheoremM.theorem_M_aeval
EOF

cd "$FORMAL_DIR"
OUT="$(lake env lean "$SCRATCH")"
echo "$OUT"

EXPECTED="[propext, Classical.choice, Quot.sound]"
COUNT="$(printf '%s\n' "$OUT" | grep -cF "depends on axioms: $EXPECTED")"
if [ "$COUNT" -ne 2 ]; then
  echo "FAIL: expected both theorems to depend on exactly $EXPECTED" >&2
  exit 1
fi
if printf '%s\n' "$OUT" | grep -q "sorryAx"; then
  echo "FAIL: sorryAx present" >&2
  exit 1
fi

# `sorry` as a term/tactic produces the token followed by space, EOL or
# punctuation; restrict to word boundary and exclude doc lines mentioning it.
if grep -rnE '(^|[^A-Za-z_])sorry([^A-Za-z_]|$)' --include='*.lean' TheoremM/ TheoremM.lean \
    | grep -vE '^\S+:[0-9]+:\s*(--|/-|`| \*)' \
    | grep -vF 'no `sorry`'; then
  echo "FAIL: sorry token found in tree" >&2
  exit 1
fi

echo "OK: axiom-clean ($EXPECTED), zero sorries."
