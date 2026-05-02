# Tracking Entropy

## Purpose

Find high-risk change hotspots and define small, targeted refactoring actions.

## Trigger Conditions

- Weekly maintainability review
- Before major feature work
- Repeated edits in the same files
- Request to assess technical debt or complexity

## Input Contract (required)

```yaml
skill: tracking-entropy
time_window: "12.month"
active_contexts:
  - "<context>"
known_pain_points:
  - "<optional>"
```

## Process

1. Run `agent/scripts/entropy-hotspots.sh`.
2. Identify high-churn files/modules.
3. Analyze top candidate for mixed concepts, boundary crossings, and test protection.
4. Propose one small refactor that lowers future context load.
5. Defer opportunistic cleanup outside scope.

## Output Template (required)

```yaml
skill: tracking-entropy
status: success
time_window_used: "<window>"
hotspot_candidates:
  - path: "<file>"
    churn_rank: 1
chosen_hotspot:
  path: "<file>"
  why_selected: "<reason>"
risk_reduction_hypothesis: "<what gets easier>"
smallest_next_refactor_slice: "<single slice>"
tests_to_add_or_verify:
  - "<path or command>"
notes: "<short rationale>"
```

## Success Criteria

- Output uses the exact template keys.
- Hotspot list and chosen hotspot are both present.
- Next refactor slice is concrete and bounded.
- Tests to protect the refactor are identified.

## Refusal / Abort Conditions

Return this template when aborting:

```yaml
skill: tracking-entropy
status: abort
reason_code: "<no-history|no-hotspots|scope-too-broad>"
missing_or_blocked:
  - "<item>"
required_user_input: "<single next clarification>"
```

Abort if:

- Repository history is unavailable for churn analysis.
- No meaningful hotspot can be identified in the requested window.
- Refactor request is broad and cannot be reduced to one safe slice.

## File Update Permissions

- May update: `agent/design-tree.md`, `agent/adr/*`
- Must not perform broad implementation changes in the same step unless explicitly requested

