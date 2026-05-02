#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/test-manifest-lib.sh"
tm_load_manifest_config "${ROOT_DIR}"
tm_detect_hash_cmd

mkdir -p "$(dirname "${TM_MANIFEST_ABS}")"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

while IFS= read -r rel; do
  [[ -z "${rel}" ]] && continue
  printf "%s  %s\n" "$(tm_hash_only "${ROOT_DIR}/${rel}")" "${rel}"
done < <(tm_collect_manifest_files "${ROOT_DIR}") >"$tmp"

mv "$tmp" "${TM_MANIFEST_ABS}"
printf "Wrote %s\n" "${TM_MANIFEST_REL}"
