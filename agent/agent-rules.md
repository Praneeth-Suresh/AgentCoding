# Agent Rules

## Before Coding

1. Read the minimum relevant canonical files in `agent/`.
2. Identify the bounded context and intended public interface.
3. For non-trivial or ambiguous work, run `grill-me` (the `grill-me` review alias).
4. Choose the smallest deterministic check that can prove behavior.

## While Coding

1. Work in one vertical slice at a time.
2. Prefer existing patterns over new abstractions.
3. Define types/interfaces before implementation where possible.
4. Keep public interfaces small; hide detail behind boundaries.
5. Do not reach into another bounded context's internals.
6. Do not weaken tests to pass implementation.
7. For web app or HTML/CSS tasks, use Microsoft Playwright MCP for browser verification instead of screenshot-only assumptions.

## Before Finishing

1. Run `./scripts/check.sh`.
2. Run any task-specific checks defined in `agent/testing-policy.md`.
3. Update glossary/design tree/architecture/ADRs if durable design changed.

## Final Response Contract

Final response must include:

- What changed.
- Which checks ran.
- Which checks were skipped or unavailable.
- Whether tests changed.
- Whether `tests/.manifest.sha256` changed.
- Which skill(s) were used.
