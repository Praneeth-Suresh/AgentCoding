#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf "ERROR: %s\n" "$*" >&2
  exit 1
}

if [[ ! -x "${ROOT_DIR}/scripts/check-md.sh" ]]; then
  fail "Missing scripts/check-md.sh (or not executable)."
fi

if [[ ! -x "${ROOT_DIR}/scripts/check-tests-unchanged.sh" ]]; then
  fail "Missing scripts/check-tests-unchanged.sh (or not executable)."
fi

if [[ ! -x "${ROOT_DIR}/scripts/check-project.sh" ]]; then
  fail "Missing scripts/check-project.sh (or not executable)."
fi

printf "Running deterministic checks...\n"

"${ROOT_DIR}/scripts/check-md.sh"
"${ROOT_DIR}/scripts/check-tests-unchanged.sh"
"${ROOT_DIR}/scripts/check-project.sh"

printf "OK\n"
