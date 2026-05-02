#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS_DIR="${ROOT_DIR}/tests"
MANIFEST="${TESTS_DIR}/.manifest.sha256"

fail() {
  printf "ERROR: %s\n" "$*" >&2
  exit 1
}

mkdir -p "${TESTS_DIR}"

if command -v sha256sum >/dev/null 2>&1; then
  SHA="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  SHA="shasum -a 256"
else
  fail "update-manifest: need sha256sum or shasum."
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

(
  cd "${TESTS_DIR}"
  find . -type f -print0 \
    | LC_ALL=C sort -z \
    | while IFS= read -r -d '' p; do
        [[ "$p" == "./.manifest.sha256" ]] && continue
        rel="${p#./}"
        ${SHA} "$rel"
      done
) >"$tmp"

mv "$tmp" "${MANIFEST}"
printf "Wrote %s\n" "${MANIFEST}"

