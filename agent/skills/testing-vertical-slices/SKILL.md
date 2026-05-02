# Testing Vertical Slices

## Purpose

Select and enforce the smallest useful behavior test before implementation.

## Trigger Conditions

- Feature implementation
- Bug fixes with behavior impact
- Refactors that risk boundary behavior

## Required Inputs

1. Behavior to prove (domain language).
2. Bounded context.
3. Existing tests (if any).
4. Risky edge case.

## Process

1. Define behavior in domain terms.
2. Choose minimal useful test level:
   - Unit for pure rules
   - Integration for adapter/persistence behavior
   - E2E smoke for critical user workflow
   - Property-based for invariants
3. Write or identify failing test/check first.
4. Implement only enough to pass.
5. Refactor after green.
6. Add one edge-case test.

## Required Output

- Chosen test level and reason
- Behavior under test
- Edge case targeted
- Narrow command(s) to run first
- Broader command(s) to run after

## File Update Permissions

- May update: test files and related test fixtures
- Must update `tests/.manifest.sha256` with `./scripts/update-test-manifest.sh` when test files change intentionally
- Must not weaken existing assertions without explicit behavior change rationale

