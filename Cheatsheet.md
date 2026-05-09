# Agent Project Setup Cheatsheet

Use this when starting a new software project from this boilerplate. The goal is simple: copy the control plane, fill the project facts, wire the checks, then make every agent change follow the same loop.

## 0. Copy The Boilerplate

From this repository, copy these paths into the new project root:

```bash
cp -R agent /path/to/new-project/
cp -R scripts /path/to/new-project/
cp -R githooks /path/to/new-project/
cp -R .github /path/to/new-project/
cp CLAUDE.md /path/to/new-project/ 2>/dev/null || true
```

Then enter the new project:

```bash
cd /path/to/new-project
```

Make scripts executable if needed:

```bash
chmod +x scripts/*.sh agent/scripts/*.sh githooks/pre-commit
```

Generate tool-specific instruction shims:

```bash
./agent/scripts/sync-agent-env.sh
```

If your repo ignores a generated tool directory such as `.codex/`, either track the needed shim explicitly or adjust `agent/scripts/agent-doctor.sh` so CI does not require ignored local files.

## 0.1 Configure Browser MCP (Web/HTML Work)

For deterministic browser feedback, standardize on **Microsoft Playwright MCP**.

1. Ensure Node.js 18+ is available.
2. Register Playwright MCP in Codex:

```bash
codex mcp add playwright npx "@playwright/mcp@latest"
codex mcp list
```

3. If you prefer config files, add this to `~/.codex/config.toml` (or project `.codex/config.toml`):

```toml
[mcp_servers.playwright]
command = "npx"
args = ["@playwright/mcp@latest"]
```

4. For web UI tasks, prompt the agent to verify behavior in Playwright MCP before marking work done.

## 1. Fill The Minimum Project Facts

Do this before asking an agent to build features.

Edit:

```text
agent/project-brief.md
agent/design-tree.md
agent/ubiquitous-language.md
agent/architecture.md
agent/testing-policy.md
agent/security-policy.md
```

Minimum required content:

1. `project-brief.md`: product goal, users, 3 to 5 core workflows, non-goals, external systems, definition of done.
2. `design-tree.md`: current design concept, open decisions, settled decisions, pressure points.
3. `ubiquitous-language.md`: domain terms agents must use in prompts, code, and tests.
4. `architecture.md`: bounded contexts, ownership, public entry points, forbidden imports.
5. `testing-policy.md`: exact commands for format, lint, typecheck, unit tests, integration tests, E2E smoke, and `check`.
6. `security-policy.md`: secrets rules, approval-required operations, external access limits.

Run:

```bash
./agent/scripts/agent-doctor.sh
./scripts/check.sh
```

Fix anything that fails before implementation starts.

## 2. Configure The Test Manifest

The test manifest tells you if test files changed since the last approved baseline.

Edit:

```text
agent/test-manifest.conf
```

Set:

```bash
MANIFEST_PATH="tests/.manifest.sha256"
INCLUDE_GLOBS=(
  "tests/**"
  "spec/**"
  "src/**/__tests__/**"
  "**/*.test.*"
  "**/*.spec.*"
  "**/*_test.go"
  "**/*_test.py"
)
EXCLUDE_GLOBS=(
  ".git/**"
  "node_modules/**"
  "vendor/**"
  ".venv/**"
  "dist/**"
  "build/**"
  "coverage/**"
)
```

Create the first manifest:

```bash
./scripts/update-test-manifest.sh
```

Check that tests are unchanged:

```bash
./scripts/check-tests-unchanged.sh
```

Normal rule:

- Run `./scripts/check-tests-unchanged.sh` when you want assurance that tests did not move.
- Run `./scripts/update-test-manifest.sh` only when a test change is intentional.
- Commit the test change and manifest change together.

## 3. Configure The Project Check

Edit:

```text
scripts/check-project.sh
```

Put your real project commands there.

Examples:

```bash
npm run format:check
npm run lint
npm run typecheck
npm test
```

or:

```bash
ruff check .
pyright
pytest
```

or:

```bash
gofmt -w .
go test ./...
```

Then run the full gate:

```bash
./scripts/check.sh
```

Use `./scripts/check.sh` as the manual "am I still safe?" command.

## 4. Optional Git Hook

Enable the pre-commit hook if you want checks before every commit:

```bash
git config core.hooksPath githooks
```

The hook runs:

```bash
./scripts/check.sh
```

Skip this if you only want to run checks manually.

## 5. Optional CI

The copied workflow is:

```text
.github/workflows/deterministic-checks.yml
```

It runs:

```bash
./scripts/check.sh
./agent/scripts/agent-doctor.sh
```

Before relying on CI, verify that every file required by `agent-doctor.sh` is tracked by Git or generated during the workflow.

## 6. First Agent Prompt For A New Project

Use this before implementation:

```text
Read the canonical files under agent/ only as needed:
- project-brief.md
- design-tree.md
- architecture.md
- ubiquitous-language.md
- testing-policy.md
- security-policy.md
- agent-rules.md

Run the grill-me skill for the initial design concept.

Input:
requested_outcome: [what the project should do]
bounded_context: [first bounded context]
candidate_public_interface: [first public API/component/route/module boundary]
constraints:
  security: [constraints or none]
  reliability: [constraints or none]
  scalability: [constraints or none]
  delivery: [constraints or none]

Output the grill-me YAML template, then update agent/design-tree.md and agent/ubiquitous-language.md if needed.
Do not implement code yet.
```

After the agent responds, review the design. If it is coherent, proceed. If not, ask it to revise the design tree first.

## 7. Per-Feature Developer Workflow

For every feature, do this:

1. Write a small feature brief.
2. Ask the agent to run `grill-me` if the work is non-trivial.
3. Ask the agent to run `testing-vertical-slices`.
4. Ask the agent to write or identify the smallest behavior test.
5. Ask the agent to implement one vertical slice.
6. Ask the agent to run narrow checks first.
7. Ask the agent to run `./scripts/check.sh`.
8. Ask the agent to update `agent/` docs or ADRs if durable knowledge changed.
9. Review whether tests changed. If tests changed intentionally, verify the manifest changed too.

Feature prompt template:

```text
Feature:
[What the user can now do.]

Bounded context:
[Context from agent/architecture.md.]

Domain language:
[Terms from agent/ubiquitous-language.md.]

Expected behavior:
- [Happy path]
- [Edge case]

Checks:
- [narrow command]
- ./scripts/check.sh

Use these skills:
1. grill-me, if the design is non-trivial or ambiguous.
2. testing-vertical-slices before implementation.

Implement one vertical slice only.
Do not weaken existing tests.
If test files change intentionally, run ./scripts/update-test-manifest.sh and explain why.
Final response must include checks run, skipped checks, skills used, whether tests changed, and whether the manifest changed.
```

## 8. When To Use Each Skill

Use `grill-me` before:

- New features with unclear design.
- Architecture changes.
- Cross-context changes.
- Ambiguous bug fixes.
- Security-sensitive work.

Ask:

```text
Run agent/skills/grill-me/SKILL.md using its YAML input and output templates.
```

Use `testing-vertical-slices` before:

- Feature implementation.
- Bug fixes with behavior impact.
- Refactors that can break behavior.

Ask:

```text
Run agent/skills/testing-vertical-slices/SKILL.md. Choose the smallest useful test level and identify the first narrow command to run.
```

Use `improving-architecture` when:

- One change touches too many files.
- Public APIs are unclear.
- Modules are shallow pass-through layers.
- Contexts are importing each other's internals.

Ask:

```text
Run agent/skills/improving-architecture/SKILL.md on [module/path]. Propose one small boundary improvement and the tests that protect it.
```

Use `tracking-entropy` when:

- Starting weekly maintenance.
- Planning a large feature.
- Seeing repeated edits in the same files.
- Deciding where refactoring is worth it.

Ask:

```text
Run agent/skills/tracking-entropy/SKILL.md with time window 12.month. Pick one hotspot and propose the smallest next refactor slice.
```

## 9. Weekly Maintenance

Run:

```bash
./agent/scripts/entropy-hotspots.sh
```

Then ask an agent:

```text
Run tracking-entropy on the hotspot list.
Pick one high-churn area.
Then run improving-architecture on that area.
Propose one small refactor slice, the test that protects it, and whether an ADR is needed.
Do not implement until I approve the slice.
```

If approved, implement one slice and run:

```bash
./scripts/check.sh
```

## 10. ADR Rule

Create an ADR in `agent/adr/` when a decision affects future work.

Use ADRs for:

- Bounded context changes.
- Public interface changes.
- Persistence shape changes.
- Adapter contracts.
- Test strategy changes.
- Security model changes.
- Naming conventions across contexts.

Do not write ADRs for tiny implementation details.

## 11. Daily Commands

Use these most often:

```bash
./scripts/check.sh
```

Run all deterministic checks.

```bash
./scripts/check-tests-unchanged.sh
```

Check whether the configured test scope changed.

```bash
./scripts/update-test-manifest.sh
```

Approve intentional test changes by refreshing the manifest.

```bash
./agent/scripts/agent-doctor.sh
```

Check that the agent control plane and generated shims are present and synced.

```bash
./agent/scripts/sync-agent-env.sh
```

Regenerate tool-specific instruction files from `agent/tool-instruction-template.md`.

```bash
./agent/scripts/entropy-hotspots.sh
```

Find files that changed most often in Git history.

## 12. What To Check Before Merging

Before merge, require:

1. `./scripts/check.sh` passes.
2. `./agent/scripts/agent-doctor.sh` passes.
3. The agent final response lists checks run and skipped.
4. Any intentional test changes include an updated manifest.
5. New domain terms are in `agent/ubiquitous-language.md`.
6. Boundary changes are in `agent/architecture.md`.
7. Durable decisions have ADRs.
8. No hidden rules exist only in chat.

## 13. Quick Recovery

If an agent makes a messy change:

1. Stop feature expansion.
2. Run `./scripts/check.sh`.
3. Ask the agent to repair only from tool output.
4. If design drift caused the issue, run `grill-me`.
5. If tests changed unexpectedly, run `./scripts/check-tests-unchanged.sh` and inspect the diff.
6. If one module is absorbing too much change, run `tracking-entropy` and then `improving-architecture`.
