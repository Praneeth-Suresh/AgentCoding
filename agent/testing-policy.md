# Testing Policy

## Command Matrix

| Check | Command | Status | Notes |
| --- | --- | --- | --- |
| Markdown sanity | `./scripts/check-md.sh` | available | Unclosed fences and tabs |
| Test manifest immutability check | `./scripts/check-tests-unchanged.sh` | available | Detects changes in configured test scope from `agent/test-manifest.conf` |
| Aggregate deterministic gate | `./scripts/check.sh` | available | Runs all deterministic checks |
| Format | `not available yet` | unavailable | No formatter configured yet |
| Lint | `not available yet` | unavailable | No linter configured yet |
| Typecheck | `not available yet` | unavailable | No typed code configured yet |
| Unit tests | `not available yet` | unavailable | No test runner configured yet |
| Integration tests | `not available yet` | unavailable | No integration harness yet |
| E2E smoke | `not available yet` | unavailable | When web runtime exists, use Microsoft Playwright MCP for deterministic browser feedback |

## Default Loop

1. Identify or add the failing behavior.
2. Select the smallest useful test level.
3. Implement one vertical slice.
4. Run narrow checks first, then broader checks.
5. Repair from actual tool output.
6. For web UI or HTML/CSS work, include a Playwright MCP browser verification step.

## Test Modification Rule

Existing tests may not be weakened to make implementation pass.

Intentional test changes are allowed only when all conditions are met:

1. The behavior change is explicit in the task or design artifact.
2. `./scripts/update-test-manifest.sh` is run after the intentional change.
3. The manifest update is committed with the test change.
4. The final response explains why tests changed.
5. `agent/test-manifest.conf` is updated if new test locations/patterns are introduced.

## Immutability Enforcement Scope

- The SHA manifest mechanism provides deterministic **change detection**, not cryptographic immutability guarantees against privileged users.
- Enforce stronger controls in CI/review policy (branch protection, required status checks, code review).

## Mocking Rules

- Mock external systems (network, clocks, randomness, payment/email providers).
- Do not mock domain logic in the same bounded context.
