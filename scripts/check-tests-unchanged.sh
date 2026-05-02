#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${ROOT_DIR}/scripts/test-manifest-lib.sh"
tm_load_manifest_config "${ROOT_DIR}"
tm_detect_hash_cmd

if [[ ! -f "${TM_MANIFEST_ABS}" ]]; then
  tm_fail "check-tests: missing ${TM_MANIFEST_REL}. Run scripts/update-test-manifest.sh to create it."
fi

# Ensure the manifest matches the current configured test scope.
# This doesn't prevent edits; it detects them deterministically.
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

while IFS= read -r rel; do
  [[ -z "${rel}" ]] && continue
  printf "%s  %s\n" "$(tm_hash_only "${ROOT_DIR}/${rel}")" "${rel}"
done < <(tm_collect_manifest_files "${ROOT_DIR}") >"$tmp"

if ! diff -u <(tm_normalize_manifest "${TM_MANIFEST_ABS}") <(tm_normalize_manifest "$tmp") >/dev/null; then
  tm_fail "check-tests: configured test scope differs from ${TM_MANIFEST_REL}. If intentional, run scripts/update-test-manifest.sh and commit the updated manifest."
fi

printf "check-tests: OK (%s matches configured scope)\n" "${TM_MANIFEST_REL}"
