# Tracking Entropy

## Purpose

Find high-risk change hotspots and define small, targeted refactoring actions.

## Trigger Conditions

- Weekly maintainability review
- Before major feature work
- Repeated edits in the same files
- Request to assess technical debt or complexity

## Required Inputs

1. Time window (default `12.month`).
2. Current active context(s).
3. Known pain points (optional).

## Process

1. Run `agent/scripts/entropy-hotspots.sh`.
2. Identify high-churn files/modules.
3. For top candidate, analyze:
   - Mixed concepts
   - Boundary-crossing imports
   - Existing tests around the hotspot
4. Propose one small refactor that reduces future context load.
5. Defer opportunistic cleanup outside scope.

## Required Output

- Hotspot list (top entries)
- Chosen hotspot and why
- Expected risk reduction
- Smallest next refactor slice
- Tests to add or verify

## File Update Permissions

- May update: `agent/design-tree.md` and `agent/adr/*` for refactor rationale
- Must not perform broad implementation changes in the same step unless explicitly requested

