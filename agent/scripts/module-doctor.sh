#!/usr/bin/env bash
set -euo pipefail

# Finds all sub-module agent/ directories and validates their required files.
# Usage: ./agent/scripts/module-doctor.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

fail() { printf "ERROR: %s\n" "$*" >&2; ERRORS=$((ERRORS + 1)); }

ERRORS=0
MODULES=0

# Find module-level agent dirs (any agent/ that is NOT the root agent/)
while IFS= read -r -d '' module_agent; do
  module_dir="$(dirname "$module_agent")"
  rel="${module_dir#${ROOT_DIR}/}"
  MODULES=$((MODULES + 1))

  printf "Checking module: %s\n" "$rel"

  required=(
    "module-context.md"
    "project-brief.md"
    "design-tree.md"
    "architecture.md"
    "ubiquitous-language.md"
    "testing-policy.md"
  )

  for file in "${required[@]}"; do
    [[ -f "${module_agent}/${file}" ]] || fail "${rel}/agent/${file} missing"
  done

done < <(find "$ROOT_DIR" -path "$ROOT_DIR/agent" -prune -o -path "*/node_modules" -prune -o -path "*/.git" -prune -o -type d -name "agent" -print0 2>/dev/null | grep -z -v "^${ROOT_DIR}/agent$" || true)

if [[ $MODULES -eq 0 ]]; then
  printf "No sub-module agent/ directories found.\n"
  exit 0
fi

if [[ $MODULES -gt 0 && $MODULES -lt 3 ]]; then
  printf "WARNING: Only %d module agent(s) found. Sub-module agents are intended for projects with 3+ complex bounded contexts. Consider whether the root agent/ is sufficient.\n" "$MODULES" >&2
fi

if [[ $ERRORS -gt 0 ]]; then
  printf "\n%d error(s) in %d module(s).\n" "$ERRORS" "$MODULES" >&2
  exit 1
fi

printf "\nAll %d module(s) healthy.\n" "$MODULES"
