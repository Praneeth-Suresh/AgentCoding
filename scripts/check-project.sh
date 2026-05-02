#!/usr/bin/env bash
set -euo pipefail

# Extension point for project-specific checks once a runtime/toolchain exists.
# Keep this deterministic and fail-fast when commands are added.

printf "check-project: no project-specific checks configured (OK)\n"

