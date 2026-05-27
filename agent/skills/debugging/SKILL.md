# Debugging

## Purpose

Find and fix a failing behavior using evidence from deterministic checks.

## Process

1. Restate the failing behavior and expected behavior.
2. Load only the canonical files needed for the affected bounded context.
3. Reproduce or inspect the failure with the narrowest command available.
4. Identify the smallest behavior test/check that proves the bug.
5. Run `grill-me` locally if ownership, expected behavior, or boundary impact is ambiguous.
6. Apply the smallest fix that addresses the root cause.
7. Run the narrow check first, then broader relevant checks.
8. Update design files only if the bug reveals durable behavior, boundary, or language knowledge.

## Rules

- Treat tool output as the source of truth.
- Do not rewrite broad areas while debugging a narrow failure.
- Do not weaken existing tests unless a ratified design change explains why expected behavior changed.
- Do not use sub-agents unless the user explicitly asks for them.

## Final Response

- Root cause
- Fix made
- Checks run
- Checks skipped or unavailable
- Whether tests changed
- Design files or ADRs updated
