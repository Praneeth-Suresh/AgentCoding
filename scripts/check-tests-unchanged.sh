#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS_DIR="${ROOT_DIR}/tests"
MANIFEST="${TESTS_DIR}/.manifest.sha256"

fail() {
  printf "ERROR: %s\n" "$*" >&2
  exit 1
}

if [[ ! -d "${TESTS_DIR}" ]]; then
  printf "check-tests: no tests/ directory (skipping)\n"
  exit 0
fi

if [[ ! -f "${MANIFEST}" ]]; then
  fail "check-tests: missing ${MANIFEST}. Run scripts/update-test-manifest.sh to create it."
fi

if command -v sha256sum >/dev/null 2>&1; then
  SHA="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  # macOS fallback
  SHA="shasum -a 256"
else
  fail "check-tests: need sha256sum or shasum."
fi

hash_only() {
  local out
  out="$(${SHA} "$1")"
  printf "%s" "${out%% *}"
}

# Ensure the manifest matches the current contents of tests/.
# This doesn't prevent edits; it detects them deterministically.
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

(
  cd "${TESTS_DIR}"
  # Only track normal files, stable order, relative paths.
  # Exclude the manifest itself.
  find . -type f -print0 \
    | LC_ALL=C sort -z \
    | while IFS= read -r -d '' p; do
        [[ "$p" == "./.manifest.sha256" ]] && continue
        # Strip leading ./ for prettier manifest lines
        rel="${p#./}"
        printf "%s  %s\n" "$(hash_only "$rel")" "$rel"
      done
) >"$tmp"

# Normalize both sides for robust comparison (sha tool output formats differ).
normalize() {
  # Output: "<hash>  <path>", preserving spaces in paths.
  awk '{h=$1; $1=""; sub(/^ +/, ""); print h"  "$0}' "$1"
}

if ! diff -u <(normalize "${MANIFEST}") <(normalize "$tmp") >/dev/null; then
  fail "check-tests: tests/ contents differ from manifest. If intentional, run scripts/update-test-manifest.sh and commit the updated manifest."
fi

printf "check-tests: OK (manifest matches)\n"
