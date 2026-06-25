# ADR 0002: Use Affected Test Gate For Commit Feedback

## Status

Accepted

## Context

Developers should get test feedback on each commit without manually choosing test subsets. The repository already has a deterministic check entrypoint in `scripts/check.sh` and a Git hook under `githooks/pre-commit`.

Adding Husky would improve hook installation for Node-based projects, but this repository does not currently have Node package metadata. Husky also does not select affected tests by itself; it only runs hook commands.

## Decision

Keep the existing Git hook path and add `scripts/check-affected.sh` as the affected test gate.

The pre-commit hook runs `scripts/check.sh` with `CHECK_AFFECTED_MODE=staged`. Manual `scripts/check.sh` uses worktree mode by default. The affected test gate reads `agent/affected-tests.conf` to choose between related-test commands and full-test fallback commands.

## Consequences

- Developers enable hooks once with `git config core.hooksPath githooks`.
- Commit-time checks run against staged changes without extra developer input.
- Broad changes such as dependency, hook, and test-strategy edits can force full tests.
- Projects can adopt Jest, pytest-testmon, or another runner by editing `agent/affected-tests.conf`.
- If no project runner is configured, the gate remains a no-op and the existing deterministic checks still run.
