#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE="${ROOT_DIR}/agent/tool-instruction-template.md"

fail() {
  printf "ERROR: %s\n" "$*" >&2
  exit 1
}

if [[ ! -f "${SOURCE}" ]]; then
  fail "missing source template: ${SOURCE}"
fi

if [[ -e "${ROOT_DIR}/.codex" && ! -d "${ROOT_DIR}/.codex" ]]; then
  fail ".codex exists as a file. Remove or rename it, then rerun."
fi

targets=(
  "${ROOT_DIR}/AGENTS.md"
  "${ROOT_DIR}/CLAUDE.md"
  "${ROOT_DIR}/.cursor/rules/agent-rules.md"
  "${ROOT_DIR}/.github/copilot-instructions.md"
  "${ROOT_DIR}/.codex/AGENTS.md"
)

for target in "${targets[@]}"; do
  mkdir -p "$(dirname "${target}")"
  cp "${SOURCE}" "${target}"
  chmod 0644 "${target}"
  printf "synced: %s\n" "${target#${ROOT_DIR}/}"
done

printf "Sync complete. Canonical source: agent/tool-instruction-template.md\n"

