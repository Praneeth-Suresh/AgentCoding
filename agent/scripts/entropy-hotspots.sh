#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SINCE="${1:-12.month}"

cd "${ROOT_DIR}"

git log --format=format: --name-only --since="${SINCE}" \
  | sed '/^$/d' \
  | sort \
  | uniq -c \
  | sort -nr \
  | head -20

