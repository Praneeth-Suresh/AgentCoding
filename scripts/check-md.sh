#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf "ERROR: %s\n" "$*" >&2
  exit 1
}

# Deterministic, dependency-free Markdown sanity checks:
# - no unclosed triple-backtick code fences
# - no TAB characters

shopt -s nullglob
md_files=("${ROOT_DIR}"/*.md)
shopt -u nullglob

if ((${#md_files[@]} == 0)); then
  printf "check-md: no *.md files found at repo root (skipping)\n"
  exit 0
fi

for f in "${md_files[@]}"; do
  # Unclosed code fences: count of ``` lines should be even.
  # This is intentionally simple and deterministic.
  fence_count="$(awk '/^```/{c++} END{print c+0}' "$f")"
  if (( fence_count % 2 != 0 )); then
    fail "check-md: Unclosed code fence in $(basename "$f") (found ${fence_count} fences)."
  fi

  # Tabs in Markdown tend to render inconsistently across viewers.
  if LC_ALL=C grep -n $'\t' "$f" >/dev/null 2>&1; then
    fail "check-md: Tab character found in $(basename "$f")."
  fi
done

printf "check-md: OK (%d files)\n" "${#md_files[@]}"

