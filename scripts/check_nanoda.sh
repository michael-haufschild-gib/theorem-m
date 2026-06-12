#!/usr/bin/env bash
# Export the Theorem M proof with lean4export, then check the exported
# declarations with nanoda_lib's independent Lean type checker.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FORMAL_DIR="$REPO_DIR/formal"

LEAN_TOOLCHAIN="$(tr -d '[:space:]' < "$FORMAL_DIR/lean-toolchain")"
LEAN_VERSION="${LEAN_TOOLCHAIN#leanprover/lean4:}"
LEAN4EXPORT_REF="${LEAN4EXPORT_REF:-$LEAN_VERSION}"

# Pin nanoda_lib to a commit whose README and parser target upstream
# leanprover/lean4export JSON NDJSON output. The v0.3.2 tag still targets
# an older ammkrn/lean4export fork on Lean v4.20.0-rc5.
NANODA_REF="${NANODA_REF:-f58f2f6d535e189a40fcb02ede8eb95f97a92d37}"

CACHE_DIR="${NANODA_CACHE_DIR:-$REPO_DIR/.cache/nanoda-check}"
LEAN4EXPORT_REPO="${LEAN4EXPORT_REPO:-https://github.com/leanprover/lean4export.git}"
NANODA_REPO="${NANODA_REPO:-https://github.com/ammkrn/nanoda_lib.git}"
LEAN4EXPORT_DIR="$CACHE_DIR/lean4export"
NANODA_DIR="$CACHE_DIR/nanoda_lib"
EXPORT_FILE="${NANODA_EXPORT_FILE:-$CACHE_DIR/theoremM.ndjson}"
CONFIG_FILE="$CACHE_DIR/nanoda_config.json"

EXPORT_MODULES_STRING="${NANODA_EXPORT_MODULES:-TheoremM}"
EXPORT_DECLS_STRING="${NANODA_EXPORT_DECLS:-TheoremM.theorem_M TheoremM.theorem_M_aeval}"
read -r -a EXPORT_MODULES <<< "$EXPORT_MODULES_STRING"
read -r -a EXPORT_DECLS <<< "$EXPORT_DECLS_STRING"

if command -v lake >/dev/null 2>&1; then
  LAKE="${LAKE:-lake}"
else
  LAKE="${LAKE:-$HOME/.elan/bin/lake}"
fi
CARGO="${CARGO:-cargo}"
NUM_THREADS="${NANODA_NUM_THREADS:-1}"

if [ ! -x "$LAKE" ] && ! command -v "$LAKE" >/dev/null 2>&1; then
  echo "FAIL: lake not found; install elan or set LAKE=/path/to/lake" >&2
  exit 1
fi
if ! command -v "$CARGO" >/dev/null 2>&1; then
  echo "FAIL: cargo not found; install Rust or set CARGO=/path/to/cargo" >&2
  exit 1
fi

fetch_ref() {
  local repo="$1"
  local dir="$2"
  local ref="$3"

  mkdir -p "$(dirname "$dir")"
  if [ ! -d "$dir/.git" ]; then
    git clone --filter=blob:none --no-checkout "$repo" "$dir"
  fi

  git -C "$dir" remote set-url origin "$repo"
  if git -C "$dir" fetch --depth 1 origin "$ref"; then
    :
  elif git -C "$dir" fetch --depth 1 origin "refs/tags/$ref"; then
    :
  elif git -C "$dir" fetch --depth 1 origin "refs/heads/$ref"; then
    :
  else
    echo "FAIL: could not fetch $ref from $repo" >&2
    exit 1
  fi
  git -C "$dir" checkout --detach FETCH_HEAD
}

abs_file_path() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  local dir
  dir="$(cd "$(dirname "$path")" && pwd)"
  printf '%s/%s' "$dir" "$(basename "$path")"
}

EXPORT_FILE_ABS="$(abs_file_path "$EXPORT_FILE")"
CONFIG_FILE_ABS="$(abs_file_path "$CONFIG_FILE")"

echo "==> Fetching lean4export $LEAN4EXPORT_REF"
fetch_ref "$LEAN4EXPORT_REPO" "$LEAN4EXPORT_DIR" "$LEAN4EXPORT_REF"
echo "==> Fetching nanoda_lib $NANODA_REF"
fetch_ref "$NANODA_REPO" "$NANODA_DIR" "$NANODA_REF"

echo "==> Building lean4export"
(cd "$LEAN4EXPORT_DIR" && "$LAKE" build)

echo "==> Building nanoda_bin"
(cd "$NANODA_DIR" && "$CARGO" build --locked --release --bin nanoda_bin)

echo "==> Exporting ${EXPORT_DECLS[*]} from module(s): ${EXPORT_MODULES[*]}"
EXPORT_CMD=("$LEAN4EXPORT_DIR/.lake/build/bin/lean4export" "${EXPORT_MODULES[@]}")
if [ "${#EXPORT_DECLS[@]}" -gt 0 ] && [ -n "${EXPORT_DECLS[0]}" ]; then
  EXPORT_CMD+=(-- "${EXPORT_DECLS[@]}")
fi
(cd "$FORMAL_DIR" && "$LAKE" env "${EXPORT_CMD[@]}" > "$EXPORT_FILE_ABS")

cat > "$CONFIG_FILE_ABS" << JSON
{
  "export_file_path": "$EXPORT_FILE_ABS",
  "use_stdin": false,
  "permitted_axioms": [
    "propext",
    "Classical.choice",
    "Quot.sound"
  ],
  "unpermitted_axiom_hard_error": true,
  "nat_extension": true,
  "string_extension": true,
  "num_threads": $NUM_THREADS,
  "print_axioms": false,
  "print_success_message": true
}
JSON

echo "==> Checking export with nanoda"
"$NANODA_DIR/target/release/nanoda_bin" "$CONFIG_FILE_ABS"

echo "OK: nanoda checked exported Theorem M declarations."
