# Putting it together

The goal is not to make agents write more code. The goal is to make agents produce code that remains understandable, testable, and easy to change after the first generation.

This is the practical gameplan for building a sophisticated working application with agents. We use the idea of shared design concept, skills, ubiquitous language, feedback loops, entropy control, modularity, TDD, coupling management, and DDD.

## The Core Operating Rule

Agents are fast, but speed only helps when the feedback loops are stronger than the generation loop.

Every agent task should therefore follow this shape:

1. Clarify the design concept.
2. Write or update the smallest useful design artifact.
3. Implement one vertical slice.
4. Run deterministic checks.
5. Repair based on tool output.
6. Record the design decision if it changes architecture or language.

Do not ask the agent to "build the app" in one large pass. Ask it to build one behavior, through one module boundary, with one testable outcome.

## Step 1: Create The Agent Control Plane

Add an `agent/` directory to the repo. This becomes the shared source of truth for all coding agents.

Recommended structure:

```text
agent/
  README.md
  project-brief.md
  design-tree.md
  ubiquitous-language.md
  architecture.md
  testing-policy.md
  security-policy.md
  agent-rules.md
  tool-instruction-template.md
  mcp.json
  skills/
    grilling-design/
      SKILL.md
    testing-vertical-slices/
      SKILL.md
    improving-architecture/
      SKILL.md
    tracking-entropy/
      SKILL.md
  scripts/
    agent-doctor.sh
    sync-agent-env.sh
    entropy-hotspots.sh
  adr/
    0001-record-architecture-decisions.md
```

Why this matters: agents need a stable memory layer that lives in the repo, not in one person's chat history or local tool configuration.

Keep these files short enough to be loaded frequently. Move long references, examples, schemas, and checklists into separate files that agents load only when needed.

Then generate tool-specific instruction files from the canonical `agent/` files. Common targets:

```text
AGENTS.md
CLAUDE.md
.cursor/rules/agent-rules.md
.github/copilot-instructions.md
.codex/AGENTS.md
```

Treat these as generated shims. The real source of truth stays in `agent/`.

### Tool-Specific Instruction Prompt

Add this exact prompt to `agent/tool-instruction-template.md`, then copy it into each tool-specific instruction file, including `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/agent-rules.md`, `.github/copilot-instructions.md`, and `.codex/AGENTS.md`.

The prompt is deliberately short. Its job is not to repeat every rule. Its job is to make each agent load the canonical repo files, obey their precedence, and keep its work inside deterministic feedback loops.

```md
# Agent Operating Instructions

This tool-specific instruction file is a generated shim. Do not edit this copy manually. Update `agent/tool-instruction-template.md` and rerun `agent/scripts/sync-agent-env.sh`.

You are working in this repository as an implementation agent. Treat the repository files as the source of truth. Do not rely on hidden chat history, memory, or assumptions when a repo-owned instruction file answers the question.

## Instruction Precedence

1. Follow explicit user instructions for the current task.
2. Follow the canonical files in `agent/`.
3. Follow this tool-specific shim.
4. Follow existing code, tests, and local conventions.

If this shim conflicts with files under `agent/`, treat this shim as stale, follow the `agent/` files, and mention the conflict in your final response.

## Required Context Before Editing

Before changing code or tests, read the smallest relevant set of canonical files:

- `agent/project-brief.md` for product goals, users, workflows, non-goals, and definition of done.
- `agent/design-tree.md` for the current design concept, open decisions, settled decisions, and pressure points.
- `agent/architecture.md` for bounded contexts, module ownership, public interfaces, adapters, and forbidden imports.
- `agent/ubiquitous-language.md` for domain terms, technical symbols, definitions, constraints, and names to avoid.
- `agent/testing-policy.md` for required test levels, mocking rules, and when tests may change.
- `agent/agent-rules.md` for the day-to-day implementation workflow.

Load additional files only when they are relevant to the task. Keep context focused.

## Skill Use

Skills live under `agent/skills/<skill-name>/SKILL.md`. Use a skill when its name or purpose matches the task.

Default triggers:

- Use `grilling-design` before non-trivial features, architecture changes, cross-context changes, or ambiguous bug fixes.
- Use `testing-vertical-slices` for feature work and bug fixes that need behavior verification.
- Use `improving-architecture` when a change exposes shallow modules, unclear ownership, repeated coupling, or hard-to-test structure.
- Use `tracking-entropy` when asked to assess maintainability, hotspots, churn, complexity, or refactoring priority.

When using a skill, read its `SKILL.md`, follow its process, and load only the referenced supporting files needed for the current task.

## Default Work Loop

For every implementation task:

1. Restate the requested behavior and identify the bounded context.
2. Identify the intended public interface and the files likely to change.
3. Add or identify the smallest test or deterministic check that proves the behavior.
4. Implement one vertical slice at a time.
5. Run the narrowest relevant check first, then the broader relevant suite.
6. Repair based on actual tool output, not guesswork.
7. Update `agent/ubiquitous-language.md`, `agent/design-tree.md`, `agent/architecture.md`, or `agent/adr/` if the change alters domain language, boundaries, or durable design decisions.

## Engineering Rules

- Prefer existing project patterns over new abstractions.
- Keep public interfaces small and explicit.
- Do not import another bounded context's internals.
- Put external systems behind adapters; do not leak API clients, ORM records, HTTP objects, or UI state into domain logic.
- Use domain names from `agent/ubiquitous-language.md`; add new domain terms when needed.
- Write types or interfaces before implementation when the language supports it.
- Do not weaken tests to make implementation pass.
- Do not edit unrelated files.
- Do not store secrets in code, tests, logs, prompts, or instruction files.

## Verification

Run the checks required by `agent/testing-policy.md` and the local toolchain. If a required check cannot run, explain why and state the risk.

Your final response must include:

- What changed.
- Which checks ran.
- Which checks were skipped or unavailable.
- Any design files, glossary entries, or ADRs updated.
```

## Step 2: Write The Minimum Useful Instruction Files

Create these files before serious implementation starts.

### `agent/project-brief.md`

Purpose: define what the application is trying to become.

Include:

- Product goal.
- Primary users.
- The 3 to 5 workflows that must feel excellent.
- Non-goals.
- External systems the app depends on.
- What "done" means for a feature.

Template:

```md
# Project Brief

## Product Goal

Build [application] for [users] so they can [core outcome].

## Primary Workflows

1. [Workflow name]: [user goal]
2. [Workflow name]: [user goal]
3. [Workflow name]: [user goal]

## Non-Goals

- [Explicit thing not being built yet]

## External Systems

- [API/database/service] used for [reason]

## Definition Of Done

A feature is complete only when it has:

- A small design note or updated design artifact.
- Types/interfaces for the new boundary.
- Tests for the intended behavior and at least one edge case.
- Passing formatter, linter, typecheck, and relevant tests.
- No new illegal imports across bounded contexts.
```

### `agent/design-tree.md`

Purpose: keep the shared design concept visible.

This is not a giant upfront plan. It is a living decision tree that improves through implementation.

Use this format:

```md
# Design Tree

## Current Design Concept

[One paragraph describing the organizing idea of the system.]

## Open Decisions

| Decision | Options | Current Lean | Why |
| --- | --- | --- | --- |
| [Question] | [A, B, C] | [A] | [Reason] |

## Settled Decisions

| Decision | Choice | Date | ADR |
| --- | --- | --- | --- |
| [Question] | [Choice] | [YYYY-MM-DD] | [ADR link] |

## Pressure Points

- [Constraint, ambiguity, or tradeoff that keeps affecting implementation.]
```

Agent rule: before making architectural changes, the agent must update `Open Decisions` or create an ADR.

### `agent/ubiquitous-language.md`

Purpose: make domain vocabulary explicit so agents do not invent sloppy names.

Use this table:

```md
# Ubiquitous Language

| Business Term | Technical Symbol | Definition | Constraints | Avoid |
| --- | --- | --- | --- | --- |
| Account | `Account` | Organization or person that owns work in the app. | Has stable identity. | `UserAccount`, `CustomerData` |
| Member | `Member` | Human user inside an account. | Belongs to exactly one account. | `User`, unless auth-specific |
```

Practical rule: if a new domain noun appears in code, it should be added here in the same PR.

### `agent/architecture.md`

Purpose: tell agents where code belongs.

Include:

- Bounded contexts.
- Module responsibilities.
- Public interfaces.
- Forbidden imports.
- Where adapters live.
- Where domain logic must not leak.

Example:

```md
# Architecture

## Bounded Contexts

| Context | Owns | Does Not Own |
| --- | --- | --- |
| Billing | Plans, invoices, subscription state | Authentication, notification delivery |
| Identity | Login, sessions, members, roles | Product billing rules |

## Boundary Rules

- Contexts may import from their own public entry point.
- Contexts must not import another context's internal files.
- External APIs are accessed through adapters, not directly from domain logic.
- Domain objects must not depend on HTTP request objects, ORM records, or UI state.

## Public Interface Rule

Each context exposes one public entry point:

- TypeScript: `src/<context>/index.ts`
- Python: `src/<context>/__init__.py`
- Go: `internal/<context>` plus explicit exported symbols
```

### `agent/testing-policy.md`

Purpose: prevent agents from treating tests as optional or moving the goal posts.

Include:

- Test pyramid expectations.
- What counts as a unit.
- What to mock.
- What not to mock.
- When integration and E2E tests are required.
- Whether tests may be edited during a bug fix.

Recommended policy:

```md
# Testing Policy

## Default Loop

1. Add or identify the failing behavior.
2. Write the smallest test that captures it.
3. Implement the fix.
4. Run the narrow test.
5. Run the broader relevant suite.

## Test Modification Rule

Existing tests may not be weakened to make implementation pass.

During bug fixes, tests can be added. Existing test assertions can be changed only if the design artifact or ADR explains why the expected behavior changed.

## What To Mock

- Mock external services, clocks, randomness, payment providers, email, and network calls.
- Do not mock domain logic inside the same bounded context.

## Required Checks

- Formatter
- Linter
- Typecheck
- Unit tests
- Relevant integration tests
- E2E smoke test for user-facing workflow changes
```

### `agent/agent-rules.md`

Purpose: make the agent's day-to-day behavior explicit.

Recommended rules:

```md
# Agent Rules

## Before Coding

- Read `agent/project-brief.md`, `agent/design-tree.md`, `agent/architecture.md`, and `agent/ubiquitous-language.md`.
- Identify the bounded context being changed.
- State the intended public interface.
- Run the `grilling-design` skill for non-trivial changes.

## While Coding

- Work in one vertical slice at a time.
- Prefer existing project patterns over new abstractions.
- Define types and interfaces before implementation.
- Keep public interfaces small.
- Do not reach into another context's internals.
- Do not weaken tests to pass implementation.

## Before Finishing

- Run formatter, linter, typecheck, and relevant tests.
- Explain which checks ran and which did not.
- Update the glossary, design tree, or ADRs if the design changed.
```

## Step 3: Add Skills That Encode Repeatable Work

Skills should be small, named by capability, and loaded only when relevant. Do not make one giant "coding" skill.

### Skill 1: `grilling-design`

Create `agent/skills/grilling-design/SKILL.md`.

```md
# Grilling Design

Use before implementation of non-trivial features, architecture changes, or ambiguous bug fixes.

## Process

1. Restate the requested outcome in one paragraph.
2. Identify the bounded context and public interface.
3. List the main design options.
4. Critique the current plan for:
   - Reliability
   - Context management
   - Security
   - Scalability
   - Testability
   - Coupling
5. Ask: "What assumption would make this implementation wrong?"
6. Revise the plan.
7. Write the final implementation slice.

## Output

- Chosen approach
- Rejected alternatives
- Risks
- Checks to run
- Files likely to change
```

Actionable insight: make the agent argue against its own first plan before it edits files. This catches vague boundaries and hidden coupling early.

### Skill 2: `testing-vertical-slices`

Create `agent/skills/testing-vertical-slices/SKILL.md`.

```md
# Testing Vertical Slices

Use when implementing a feature or bug fix.

## Process

1. Define the behavior in domain language.
2. Pick the smallest useful test level:
   - Unit for pure domain rules.
   - Integration for persistence, adapters, or cross-module behavior.
   - E2E for critical user workflows.
3. Write or identify the failing test first.
4. Implement only enough code to pass it.
5. Refactor after the test is green.
6. Add one edge-case test for the behavior the agent was most likely to miss.

## Rules

- Do not mock code from the same bounded context.
- Do mock external systems.
- Do not weaken existing tests without updating a design artifact.
```

Actionable insight: agents behave better when the unit of work is a tested behavior, not a file list.

### Skill 3: `improving-architecture`

Create `agent/skills/improving-architecture/SKILL.md`.

```md
# Improving Architecture

Use when code feels hard to change, a feature crosses too many files, or a module boundary is unclear.

## Process

1. Identify the friction point.
2. Name the domain concept being hidden by the current structure.
3. Find shallow modules that only pass arguments through.
4. Propose a smaller public interface.
5. Move implementation detail behind that interface.
6. Add or update boundary tests.
7. Record the decision in an ADR if the boundary changes.

## Output

- Current problem
- Proposed boundary
- Public API
- Internal files
- Tests protecting the boundary
```

Actionable insight: the best refactors for agents are boundary refactors. They reduce the amount of context future agents need.

### Skill 4: `tracking-entropy`

Create `agent/skills/tracking-entropy/SKILL.md`.

```md
# Tracking Entropy

Use weekly, before large features, or when a file keeps getting changed by unrelated tasks.

## Process

1. Run `agent/scripts/entropy-hotspots.sh`.
2. Identify files with both high churn and high complexity.
3. For the top hotspot, ask:
   - Which concepts are mixed together?
   - Which imports reveal illegal coupling?
   - Which tests would protect a split?
4. Create one small refactoring issue.
5. Do not refactor opportunistically inside unrelated feature work.
```

Actionable insight: AI increases entropy when every feature touches the same central files. Track churn so refactoring work is aimed at the real risk.

## Step 4: Connect Deterministic Tools And MCP Servers

Agents need deterministic tools more than they need longer prompts.

Create `agent/mcp.json` as the desired MCP inventory. Exact server names vary by agent platform, but this is the target capability set:

```json
{
  "required": [
    {
      "name": "filesystem",
      "purpose": "Read and edit repository files with explicit workspace limits"
    },
    {
      "name": "git",
      "purpose": "Inspect diffs, history, branches, and changed files"
    },
    {
      "name": "fetch",
      "purpose": "Fetch external documentation as markdown when current docs are required"
    },
    {
      "name": "browser",
      "purpose": "Run Playwright or Puppeteer checks for web UI behavior"
    }
  ],
  "optional": [
    {
      "name": "database-readonly",
      "purpose": "Inspect schemas and safe sample data without mutation"
    },
    {
      "name": "logs-readonly",
      "purpose": "Read production errors from Sentry, Datadog, CloudWatch, or equivalent"
    },
    {
      "name": "docs-search",
      "purpose": "Search internal docs, ADRs, runbooks, and product specs"
    }
  ]
}
```

Practical security rules:

- Give agents read-only access by default.
- Use separate credentials for agent tooling.
- Never place secrets in instruction files.
- Prefer local `.env.example` plus a secret manager over shared `.env` files.
- For database MCP access, start with schema-only or read-only mode.
- Require human approval for migrations, destructive shell commands, production writes, and dependency upgrades.

## Step 5: Standardize Local Commands

Agents need one obvious command for each feedback loop.

Add these package scripts, Make targets, or task runner commands:

```text
format
lint
typecheck
test
test:unit
test:integration
test:e2e
check
dev
build
```

`check` should run the normal pre-PR gate:

```text
format -> lint -> typecheck -> unit tests -> relevant integration tests
```

For web apps, add a Playwright smoke test for the most important workflow. This gives agents visual/runtime feedback instead of relying only on static code.

## Step 6: Add Practical Scripts

### `agent/scripts/agent-doctor.sh`

Purpose: quickly tell whether an environment is ready for agent work.

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Checking agent workspace..."

test -f agent/project-brief.md
test -f agent/design-tree.md
test -f agent/ubiquitous-language.md
test -f agent/architecture.md
test -f agent/testing-policy.md
test -f agent/agent-rules.md
test -f agent/tool-instruction-template.md

command -v git >/dev/null

echo "Agent instruction files present."
echo "Git available."
echo "Now run the project-specific check command."
```

### `agent/scripts/sync-agent-env.sh`

Purpose: sync repo-owned instructions into local agent-specific locations.

Keep the source of truth in `agent/`. The script should copy from the repo into each tool's expected config directory, never the other way around.

Example:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SHIM="$ROOT/agent/tool-instruction-template.md"

mkdir -p "$ROOT/.codex"
mkdir -p "$ROOT/.cursor/rules"
mkdir -p "$ROOT/.github"

cp "$SHIM" "$ROOT/AGENTS.md"
cp "$SHIM" "$ROOT/CLAUDE.md"
cp "$SHIM" "$ROOT/.codex/AGENTS.md"
cp "$SHIM" "$ROOT/.cursor/rules/agent-rules.md"
cp "$SHIM" "$ROOT/.github/copilot-instructions.md"

echo "Synced generated tool instruction shims from agent/ into local agent config files."
```

Practical note: if multiple tools need small format differences, keep `agent/tool-instruction-template.md` as the shared shim and generate tool-specific versions from it. Do not manually maintain five divergent instruction files.

### `agent/scripts/entropy-hotspots.sh`

Purpose: find files that deserve architectural attention.

```bash
#!/usr/bin/env bash
set -euo pipefail

SINCE="${1:-12.month}"

git log --format=format: --name-only --since="$SINCE" \
  | sed '/^$/d' \
  | sort \
  | uniq -c \
  | sort -nr \
  | head -20
```

Start with churn. Add complexity tooling later only if the churn list is too noisy.

### `scripts/check-tests-unchanged.sh`

Purpose: detect whether the test suite changed since the last approved test manifest.

This does not make tests impossible to edit. It makes test changes explicit, deterministic, and easy to review. The check compares files under `tests/` against a committed SHA-256 manifest at `tests/.manifest.sha256`.

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS_DIR="${ROOT_DIR}/tests"
MANIFEST="${TESTS_DIR}/.manifest.sha256"

fail() {
  printf "ERROR: %s\n" "$*" >&2
  exit 1
}

if [[ ! -d "${TESTS_DIR}" ]]; then
  printf "check-tests: no tests/ directory (skipping)\n"
  exit 0
fi

if [[ ! -f "${MANIFEST}" ]]; then
  fail "check-tests: missing ${MANIFEST}. Run scripts/update-test-manifest.sh to create it."
fi

if command -v sha256sum >/dev/null 2>&1; then
  SHA="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  SHA="shasum -a 256"
else
  fail "check-tests: need sha256sum or shasum."
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

(
  cd "${TESTS_DIR}"
  find . -type f -print0 \
    | LC_ALL=C sort -z \
    | while IFS= read -r -d '' p; do
        [[ "$p" == "./.manifest.sha256" ]] && continue
        rel="${p#./}"
        ${SHA} "$rel"
      done
) >"$tmp"

normalize() {
  awk '{print $1" "$2}' "$1"
}

if ! diff -u <(normalize "${MANIFEST}") <(normalize "$tmp") >/dev/null; then
  fail "check-tests: tests/ contents differ from manifest. If intentional, run scripts/update-test-manifest.sh and commit the updated manifest."
fi

printf "check-tests: OK (manifest matches)\n"
```

Pair it with `scripts/update-test-manifest.sh`, which is only run when a test change is intentional:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS_DIR="${ROOT_DIR}/tests"
MANIFEST="${TESTS_DIR}/.manifest.sha256"

fail() {
  printf "ERROR: %s\n" "$*" >&2
  exit 1
}

mkdir -p "${TESTS_DIR}"

if command -v sha256sum >/dev/null 2>&1; then
  SHA="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  SHA="shasum -a 256"
else
  fail "update-manifest: need sha256sum or shasum."
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

(
  cd "${TESTS_DIR}"
  find . -type f -print0 \
    | LC_ALL=C sort -z \
    | while IFS= read -r -d '' p; do
        [[ "$p" == "./.manifest.sha256" ]] && continue
        rel="${p#./}"
        ${SHA} "$rel"
      done
) >"$tmp"

mv "$tmp" "${MANIFEST}"
printf "Wrote %s\n" "${MANIFEST}"
```

Expose all deterministic checks through one manual command:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"${ROOT_DIR}/scripts/check-md.sh"
"${ROOT_DIR}/scripts/check-tests-unchanged.sh"

printf "OK\n"
```

Run this command whenever you want assurance that the repo still satisfies the deterministic checks:

```bash
./scripts/check.sh
```

## Step 7: Enforce Boundaries With Tooling

Use the lightest tool that catches real mistakes.

For TypeScript:

- `strict: true` in `tsconfig.json`.
- `eslint-plugin-import` or `dependency-cruiser` to block imports into another context's internals.
- `eslint` naming rules for banned vague names like `Data`, `Manager`, `Helper`, `Util`, and `Base`.
- `fast-check` for property-based tests where invariants matter.

For Python:

- `pyright` or `mypy` in strict mode where practical.
- `ruff` for linting and import rules.
- `pytest` for tests.
- `hypothesis` for property-based tests.
- package `__init__.py` files that expose public APIs deliberately.

For Go:

- `go test ./...`.
- `internal/` packages for hidden implementation.
- `golangci-lint`.
- interfaces at boundaries where substitution is actually needed.

Do not add complex governance before the app has real shape. Start with typecheck, tests, and import boundaries. Add custom lint rules only after you see repeated naming or coupling failures.

## Step 8: Use The Feature Workflow Every Time

This is the default agent workflow for building one feature.

### 1. Intake

The human or lead agent writes a small feature brief:

```md
## Feature

[What user can now do.]

## Domain Language

[Terms from `agent/ubiquitous-language.md`.]

## Bounded Context

[Context being changed.]

## Expected Behavior

- [Behavior]
- [Edge case]

## Checks

- [Relevant test command]
- [Relevant typecheck/lint command]
```

### 2. Pre-flight Design Review

Run the `grilling-design` skill.

Required output:

- Chosen design.
- Rejected alternatives.
- Main risk.
- Public interface.
- Test strategy.

For small changes, this can be five bullets. For architectural changes, it should update `agent/design-tree.md` or create an ADR.

### 3. Type And Interface First

Before implementation, define:

- Domain types.
- Value objects for important primitives.
- Public function/class/component boundary.
- Adapter interface for external systems.

This narrows the agent's search space and gives the compiler something useful to check.

### 4. Test The Behavior

Use the smallest test that proves the behavior.

Testing choice:

- Pure rule: unit test.
- Database or adapter behavior: integration test.
- User workflow: E2E smoke test.
- Invariant-heavy logic: property-based test.

Add one edge case that targets the easiest agent mistake.

### 5. Implement The Slice

Rules:

- Touch the fewest bounded contexts possible.
- Keep external systems behind adapters.
- Keep domain logic away from UI, HTTP, ORM, and vendor SDK details.
- Do not create generic helpers until two or three real call sites prove the shape.
- Prefer deep modules with small public APIs.

### 6. Run Generate-Check-Fix

The agent runs:

```text
format
lint
typecheck
targeted test
broader relevant test
```

The agent should paste the failing output back into its reasoning and fix the actual cause. It should not guess from memory when deterministic output is available.

### 7. Close The Loop

Before finishing, update:

- `agent/ubiquitous-language.md` if new domain terms were introduced.
- `agent/design-tree.md` if a design decision moved from open to settled.
- `agent/architecture.md` if a boundary changed.
- `agent/adr/` if the change affects future implementation choices.

## Step 9: Use ADRs For Decisions That Future Agents Must Remember

Create ADRs only for decisions that will matter later. Do not write an ADR for every tiny implementation detail.

Template:

```md
# ADR N: [Decision Name]

## Status

Accepted

## Context

[What forced this decision?]

## Decision

[What did we choose?]

## Consequences

- [Benefit]
- [Tradeoff]
- [Follow-up]
```

Good ADR triggers:

- Choosing a bounded context boundary.
- Choosing where domain logic lives.
- Introducing a new adapter.
- Changing persistence shape.
- Changing test strategy.
- Adding a cross-cutting abstraction.

## Step 10: Review Agents Like Junior Engineers With Perfect Typing Speed

Agent output should be reviewed for design drift, not just syntax.

Review checklist:

- Does the code use the ubiquitous language?
- Did it change only the intended bounded context?
- Are public interfaces smaller than implementations?
- Are external systems behind adapters?
- Are tests checking behavior rather than implementation trivia?
- Did it add new generic helpers without enough evidence?
- Did it weaken or delete tests?
- Did it leave instruction files stale?
- Did it increase coupling by importing internals from another module?

The most important review question is: "Will the next agent need less context or more context because of this change?"

## Practical Rollout Plan

Do this in order. Each phase should leave behind a repo-owned artifact, a deterministic command, or both. The point is to turn agent behavior into a repeatable engineering system instead of a collection of good prompts.

### Day 0: Bootstrap

Goal: create the control plane before asking agents to build features.

1. Create `agent/` with the canonical files listed in Step 1. Keep each file short enough that an agent can load it at the start of work.
2. Fill `agent/project-brief.md` with the product goal, primary workflows, non-goals, external systems, and definition of done. Do not start implementation until the primary workflows are named.
3. Create `agent/ubiquitous-language.md` as a table of `Business Term | Technical Symbol | Definition | Constraints`. Pull the first terms from `Plan.md`: design concept, design tree, bounded context, ubiquitous language, feedback loop, entropy hotspot, vertical slice, adapter, seam, and ADR.
4. Create `agent/design-tree.md` with three sections: `Open Decisions`, `Settled Decisions`, and `Pressure Points`. The first version can be rough, but it must name the choices that are still uncertain.
5. Run the `grill-me` pre-flight review from `Plan.md` before creating architecture rules. In this repo, implement that as the `grilling-design` skill or a `grill-me` alias that loads `agent/skills/grilling-design/SKILL.md`.
6. During `grill-me`, make the agent critique the proposed design for reliability, context management, security, and scalability. Require short answers to: "What is unclear?", "What will agents likely misunderstand?", "What test proves the first behavior?", and "What decision must be recorded now?"
7. Update `agent/design-tree.md` and `agent/ubiquitous-language.md` based on the grilling output. The review is not complete until the repo files change or the agent states that no change is needed and why.
8. Add `agent-rules.md`, `tool-instruction-template.md`, `architecture.md`, and `testing-policy.md`. These files should tell agents what to read, which bounded context they may touch, when tests may change, and which checks must run.
9. Add the four skills: `grilling-design`, `testing-vertical-slices`, `improving-architecture`, and `tracking-entropy`. Each skill should include trigger conditions, required inputs, required output, and which repo files it may update.
10. Add `agent-doctor.sh`, `sync-agent-env.sh`, `entropy-hotspots.sh`, `scripts/check.sh`, `scripts/check-md.sh`, `scripts/check-tests-unchanged.sh`, and `scripts/update-test-manifest.sh`.
11. Run `agent/scripts/agent-doctor.sh` and `./scripts/check.sh`. Fix missing files before starting feature work.

### Week 1: Make Feedback Deterministic

Goal: make every agent change pass through the same local checks.

1. Choose the project commands and write them into `agent/testing-policy.md`: `format`, `lint`, `typecheck`, `unit test`, `integration test`, `e2e smoke`, and `check`. If a command does not exist yet, write `not available yet` and the reason.
2. Make `./scripts/check.sh` the manual one-command gate. It should call Markdown checks, test-manifest checks, and any project-specific commands that exist.
3. Add `tests/.manifest.sha256` by running `./scripts/update-test-manifest.sh`. From this point forward, `./scripts/check-tests-unchanged.sh` tells you whether tests changed since the last approved manifest.
4. Define the test-change rule in `agent/testing-policy.md`: existing tests must not be weakened during implementation; intentional test changes require a matching manifest update and a short explanation in the final response.
5. Turn on strict typechecking as far as the current codebase allows. If strict mode creates too much noise, document the relaxed rule and the plan to tighten it.
6. Add import-boundary rules for the highest-value bounded contexts first. Start with one or two forbidden imports that catch real mistakes rather than a large policy that nobody understands.
7. Add one E2E smoke test for the most important workflow. Keep it thin: it should prove the app starts and the primary path works, not exhaustively test every variant.
8. Update `agent/agent-rules.md` so every agent final response includes checks passed, checks skipped, and whether tests were changed.
9. Run `./scripts/check.sh` manually before and after feature work. This replaces continuous watching; you decide when you want assurance.

### Week 2: Improve Agent Memory

Goal: move repeated explanations out of chat and into files agents can read.

1. Review the last few feature discussions, bug reports, or design notes. Extract repeated domain terms into `agent/ubiquitous-language.md`.
2. Use `grilling-design` whenever a term is ambiguous. The skill should ask whether the term belongs to the business domain, technical implementation, UI copy, or external-system vocabulary.
3. Add ADRs for decisions that repeatedly confuse agents: bounded context ownership, persistence shape, adapter boundaries, test strategy, and naming conventions.
4. Move long prompt paragraphs into `agent/` files. A good rule: if you paste the same instruction twice, it belongs in the repo.
5. Run `agent/scripts/sync-agent-env.sh` so `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/agent-rules.md`, `.github/copilot-instructions.md`, and `.codex/AGENTS.md` are generated from the same source.
6. Run `agent-doctor.sh` after syncing. It should fail if a canonical file is missing or if a generated shim is stale.
7. Update `agent/skills/*/SKILL.md` when a repeated workflow appears. Keep each skill focused: one trigger, one process, one expected output.

### Week 3: Reduce Entropy

Goal: use agents to make the codebase easier to change, not just larger.

1. Run `agent/scripts/entropy-hotspots.sh` and pick one file or module with high churn. Do not start with the worst file if it is too broad; choose the smallest hotspot that affects current work.
2. Run the `tracking-entropy` skill. Required output: why the file changes often, which concepts are mixed together, what tests currently protect it, and what change would reduce future context needs.
3. Run `improving-architecture` on the chosen hotspot. Ask it to identify shallow modules, hidden domain concepts, unclear ownership, and imports that cross boundaries.
4. Choose one small refactor: extract a domain concept, move adapter code behind an interface, shrink a public API, or merge shallow pass-through modules.
5. Before refactoring, run `testing-vertical-slices` to identify the smallest behavior test that protects the boundary. Add or identify that test before implementation.
6. Make the refactor in one vertical slice. Avoid broad cleanup unless it directly supports the new boundary.
7. Run targeted tests first, then `./scripts/check.sh`.
8. Record the decision in an ADR if future agents need to preserve the boundary. Update `agent/architecture.md` if imports or ownership changed.

### Ongoing: Per Feature

Goal: make every feature follow the same generate-check-fix loop.

1. Write a feature brief with `Feature`, `Domain Language`, `Bounded Context`, `Expected Behavior`, and `Checks`.
2. Load the relevant canonical files: `project-brief.md`, `design-tree.md`, `architecture.md`, `ubiquitous-language.md`, `testing-policy.md`, and `agent-rules.md`.
3. Run `grilling-design` for non-trivial work, ambiguous bug fixes, architecture changes, cross-context changes, or security-sensitive changes. For tiny changes, write the five-bullet version: chosen design, rejected alternative, main risk, public interface, and test strategy.
4. Run `testing-vertical-slices` before implementation. It should choose the narrowest useful test level: unit for pure rules, integration for adapters or persistence, E2E smoke for user workflows, and property-based tests for invariants.
5. Define types, interfaces, and public boundaries first. Use names from `agent/ubiquitous-language.md`; add new terms before using them widely.
6. Write or identify the smallest useful test. If the test suite must change, run `./scripts/update-test-manifest.sh` after the intentional edit and explain why the manifest changed.
7. Implement one vertical slice. Keep external systems behind adapters and avoid importing another bounded context's internals.
8. Run the narrowest check first, then broader checks, then `./scripts/check.sh`.
9. If checks fail, repair from actual tool output. Do not weaken tests unless the feature brief explicitly says the expected behavior changed.
10. Close the loop by updating `ubiquitous-language.md`, `design-tree.md`, `architecture.md`, or an ADR when the change creates durable knowledge.
11. Final response must state: what changed, which skill was used, which checks ran, whether tests changed, and whether the manifest changed.

## What To Avoid

- Do not let agents implement across the whole repo from a vague prompt.
- Do not store important instructions only in chat.
- Do not give write access to production systems through MCP.
- Do not let agents weaken tests during implementation.
- Do not create generic `utils`, `helpers`, `managers`, or `services` without a domain name.
- Do not split modules by framework layer when the domain boundary is clearer.
- Do not add heavyweight process for every small change. Use stronger ceremony only when the change affects architecture, security, data, or critical workflows.

## The Practical Standard

A codebase is agent-ready when a new agent can answer these questions from repo files and tools, without relying on hidden conversation history:

1. What is this app trying to do?
2. What domain words should I use?
3. Which bounded context am I changing?
4. What public interface should I respect?
5. Which tests prove the behavior?
6. Which commands tell me I broke something?
7. Where do I record a design decision?

If those answers are easy to find, agents will produce smaller, safer, more coherent changes. If those answers are missing, agents will compensate by inventing structure, and that is where entropy accelerates.
