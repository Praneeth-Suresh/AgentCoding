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

Put your real project commands there. This is the project-specific extension point already called by `./scripts/check.sh`; do not add another wrapper script for formatters or linters.

Required order:

1. Formatter check.
2. Linter.
3. Typecheck.
4. Unit/integration tests.

Use non-mutating formatter check mode in `check-project.sh` when the tool supports it. Agents should still run the mutating formatter command immediately after writing code, but the shared gate should fail cleanly in hooks and CI instead of silently rewriting files.

Examples:

```bash
npm run format:check
npm run lint
npm run typecheck
npm test
```

or:

```bash
ruff format --check .
ruff check .
pyright
pytest
```

or:

```bash
test -z "$(gofmt -l .)"
go vet ./...
golangci-lint run
go test ./...
```

Also update `agent/testing-policy.md` so agents know both commands:

| Stack | Formatter after edits | Formatter check in `check-project.sh` | Linter |
| --- | --- | --- | --- |
| TypeScript/JavaScript | `npm run format` | `npm run format:check` | `npm run lint` |
| Python | `ruff format .` | `ruff format --check .` | `ruff check .` |
| Go | `gofmt -w .` | `test -z "$(gofmt -l .)"` | `go vet ./...` and/or `golangci-lint run` |

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

## 6. First Agent Prompt For A New 

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

Use this after the initial design specification is reviewed and accepted:

```text
Implement the complete application from the approved initial design specification.

Read canonical files under agent/ only as needed:
- project-brief.md
- design-tree.md
- architecture.md
- ubiquitous-language.md
- testing-policy.md
- security-policy.md
- agent-rules.md

Do not load tool-specific shim instruction files for this run.

Working loop:
1. Restate the product goal, primary workflows, bounded contexts, and definition of done from the canonical files.
2. Plan implementation as ordered vertical slices mapped to the primary workflows.
3. If a slice is non-trivial or ambiguous, run grill-me before coding that slice.
3a. Optional (easy to remove): run Design Reviewer sub-agent before coding each medium/high-risk slice.
4. Run testing-vertical-slices before coding each slice; choose the narrowest useful test level.
5. Implement one vertical slice at a time, keeping external systems behind adapters and interfaces small.
5a. Optional (easy to remove): if a slice touches multiple contexts or many files, run Architecture Reviewer sub-agent before continuing.
6. Use terms from agent/ubiquitous-language.md in prompts, code, and tests; update it when durable terms are added.
7. Respect architecture boundaries: do not import internals from another bounded context.
8. After code edits, run the formatter command from agent/testing-policy.md, then run narrow checks, then run ./scripts/check.sh.
8a. Optional (easy to remove): run Slice Reviewer sub-agent after narrow checks for continuous review.
9. For web UI behavior, verify with Playwright MCP before marking a slice done.
10. If tests change intentionally, run ./scripts/update-test-manifest.sh and explain why.
11. Update agent/design-tree.md, agent/architecture.md, and agent/adr/* whenever durable decisions change.
12. Optional (easy to remove): run Final Reviewer sub-agent before merge for independent gatekeeping.

Continue until all primary workflows in agent/project-brief.md satisfy the definition of done.

Final response must include:
- What was implemented.
- Skills used.
- Checks run.
- Checks skipped or unavailable.
- Whether tests changed and whether the test manifest changed.
- Which agent/ docs or ADRs were updated.
```

Optional removable sub-agent prompts:
- Design Reviewer (required sub-agent role: independent reviewer)
  Prompt:
  Review the feature brief and grill-me output before coding.
  Use only the Step 10-style checklist: language, bounded context, public interfaces, adapter isolation, tests, and coupling.
  Return only blockers, risk level (low/medium/high), and one exact fix per blocker.
  If no blockers, reply exactly: approved for implementation
- Architecture Reviewer (required sub-agent role: improving-architecture)
  Prompt:
  Review this slice for boundary drift.
  Return one minimal boundary improvement, the public API change, and the smallest protecting test.
  Do not propose broad cleanup.
- Slice Reviewer (required sub-agent role: code reviewer)
  Prompt:
  Review only the current slice diff plus narrow-check output.
  Report only blocking issues with exact fixes.
  Ignore style-only or optional cleanup.
  If no blockers, reply exactly: approved for next slice
- Final Reviewer (required sub-agent role: independent merge reviewer)
  Prompt:
  Review full diff and changed agent/ docs before merge.
  Prioritize boundary drift, test weakening, adapter leakage, and stale instruction files.
  Report only merge blockers and exact fixes.
  If no blockers, reply exactly: approved for merge

After the first pass, review missing workflow gaps and continue slice-by-slice until complete.

## 7. Per-Feature Developer Workflow

For every feature, do this:

1. Write a small feature brief.
2. Ask the agent to update `agent/project-brief.md` with the new or changed user workflow, success condition, and definition-of-done impact.
3. Ask the agent to update `agent/design-tree.md` with the design choices and a Feature Slice Ledger for the vertical slices.
4. Ask the agent to run `grill-me` if the work is non-trivial.
5. Ask the agent to run `testing-vertical-slices`.
6. Ask the agent to write or identify the smallest behavior test for the next planned slice.
7. Ask the agent to implement one vertical slice.
8. Ask the agent to mark that slice `in_progress` in the Feature Slice Ledger before coding.
9. Ask the agent to run the formatter command from `agent/testing-policy.md`.
10. Ask the agent to run narrow checks first.
11. Ask the agent to run `./scripts/check.sh`, which must include formatter check mode and lint through `scripts/check-project.sh`.
12. Ask the agent to mark the slice `done` or `blocked` in the Feature Slice Ledger based on actual check output.
13. Ask the agent to update `agent/` docs or ADRs if durable knowledge changed.
14. Review whether tests changed. If tests changed intentionally, verify the manifest changed too.
15. Optional (easy to remove): run Slice Reviewer sub-agent after narrow checks.
16. Optional (easy to remove): if the slice touches multiple contexts, run Architecture Reviewer sub-agent.
17. Optional (easy to remove): run Final Reviewer sub-agent before merge on medium/high-risk work.

Feature Slice Ledger:

Use `agent/design-tree.md` as the working memory for sequential slices. Add this section when a feature has more than one slice, or when the work may be interrupted and resumed:

```md
## Active Feature Slices

| Slice ID | Feature | User Outcome | Bounded Context | Depends On | Status | Checks | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| FS-001 | [feature name] | [observable behavior] | [context] | none | planned | [formatter], [narrow], ./scripts/check.sh | [risk or decision] |
| FS-002 | [feature name] | [next observable behavior] | [context] | FS-001 | planned | [formatter], [narrow], ./scripts/check.sh | [risk or decision] |
```

Status values:

- `planned`: not started.
- `in_progress`: currently being implemented; only one slice should have this status.
- `done`: implemented and checks passed.
- `blocked`: stopped on missing information or failing external prerequisite.

When all slices are `done`, remove the active ledger or move the durable result into `Settled Decisions`, `Pressure Points`, `agent/architecture.md`, or an ADR. Do not leave stale slice state in `agent/design-tree.md`.

Feature prompt template:

```text
Feature:
[What the user can now do.]

Project brief update:
- Update agent/project-brief.md with the new/changed primary workflow, success condition, and definition-of-done impact.

Bounded context:
[Context from agent/architecture.md.]

Domain language:
[Terms from agent/ubiquitous-language.md.]

Expected behavior:
- [Happy path]
- [Edge case]

Checks:
- [formatter command from agent/testing-policy.md]
- [narrow command]
- ./scripts/check.sh

Design tree / working memory:
- Update agent/design-tree.md before coding.
- Add or update Open Decisions, Settled Decisions, and Pressure Points as needed.
- Add or update the Active Feature Slices ledger.
- Mark exactly one next slice as in_progress before coding.
- After checks, mark that slice done or blocked and leave the next planned slice visible.

Use these skills:
1. grill-me, if the design is non-trivial or ambiguous.
2. testing-vertical-slices before implementation.

Optional sub-agent blocks (delete this section if sub-agents are unavailable):
1. Design Reviewer (for medium/high-risk work) prompt:
   Review the feature brief and grill-me output before coding.
   Return blockers, risk level, and exact fixes only.
   If no blockers, reply exactly: approved for implementation
2. Slice Reviewer (continuous review) prompt:
   Review only this slice diff and narrow-check output.
   Report blockers and exact fixes only.
   If no blockers, reply exactly: approved for next slice
3. Architecture Reviewer (boundary escalation) prompt:
   If this slice crosses contexts, propose one minimal boundary correction and the protecting test.
4. Final Reviewer (pre-merge) prompt:
   Review full diff + changed agent docs.
   Report only merge blockers and exact fixes.
   If no blockers, reply exactly: approved for merge

Implement one vertical slice only.
Run the formatter command after code edits.
Do not weaken existing tests.
If test files change intentionally, run ./scripts/update-test-manifest.sh and explain why.
Final response must include checks run, skipped checks, skills used, whether tests changed, whether the manifest changed, project-brief updates, design-tree updates, and the next planned slice ID.
```

Follow-up prompt to continue feature slices:

```text
Continue implementing the feature from the Active Feature Slices ledger in agent/design-tree.md.

Read only the relevant canonical files:
- agent/project-brief.md
- agent/design-tree.md
- agent/architecture.md
- agent/ubiquitous-language.md
- agent/testing-policy.md
- agent/agent-rules.md

Find the first slice with status planned and all dependencies done.
Mark that slice in_progress before coding.
Implement only that slice.
Run the formatter command from agent/testing-policy.md, then the narrow checks listed for the slice, then ./scripts/check.sh.
If checks pass, mark the slice done and leave the next planned slice visible.
If blocked, mark the slice blocked with the exact blocker and stop.

Do not start another slice in the same pass.
Do not weaken tests.
If tests change intentionally, run ./scripts/update-test-manifest.sh and explain why.

Final response must include:
- slice ID implemented
- files changed
- checks run
- checks skipped or unavailable
- whether tests changed
- whether the manifest changed
- project-brief updates, if any
- design-tree ledger status
- next planned slice ID
```

Follow-up prompt to repair or resume an interrupted slice:

```text
Resume the slice marked in_progress in agent/design-tree.md.

If no slice is in_progress, choose the first planned slice whose dependencies are done.
Repair or implement only that slice.
Use actual tool output as the source of truth.
Run the formatter command from agent/testing-policy.md, then the slice's narrow checks, then ./scripts/check.sh.
Update the Active Feature Slices ledger to done or blocked.

Do not start a second slice.
Final response must include the slice ID, status, checks, and next planned slice.
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

### Optional Sub-Agent Review Overlay (easy to remove)

Use Design Reviewer sub-agent:

- Before coding medium/high-risk slices.
- After `grill-me`, before implementation.

Ask:

```text
Review feature brief + grill-me output using the review checklist.
Report blockers, risk level, and exact fixes only.
If no blockers, reply exactly: approved for implementation
```

Use Slice Reviewer sub-agent:

- After narrow checks for each medium/high-risk slice.
- For low-risk work, every second slice to reduce overhead.

Ask:

```text
Review only current slice diff + narrow-check output.
Report blockers and exact fixes only.
If no blockers, reply exactly: approved for next slice
```

Use Architecture Reviewer sub-agent:

- When one slice spans contexts or many files.

Ask:

```text
Review for boundary drift and propose one minimal correction plus protecting test.
Do not propose broad cleanup.
```

Use Final Reviewer sub-agent:

- Before merge on medium/high-risk work.

Ask:

```text
Review full diff + changed agent docs.
Report merge blockers and exact fixes only.
If no blockers, reply exactly: approved for merge
```

Speed notes:

- Keep reviewer outputs blocker-only to reduce token and triage time.
- Start Slice Reviewer right after narrow checks while broader checks continue.
- Skip optional reviewer layers on tiny low-risk changes.

## 8.5 Worktree Branches For Parallel Agent Runs

Use Git worktrees when you want two or three agents to try competing implementations from the same base branch.

Best targets:

- Initial project implementation after the design spec is accepted.
- Medium/high-risk features.
- Ambiguous bug fixes.
- Entropy hotspot refactors.
- Competing architecture boundary designs.

Avoid worktrees for tiny edits.

### Create Variants

Start clean:

```bash
git fetch origin
git status --short
BASE=origin/main
REPO="$(basename "$(pwd)")"
WT_ROOT="../${REPO}.worktrees"
mkdir -p "$WT_ROOT"
```

Create one branch and one worktree per attempt:

```bash
git worktree add -b agents/<task-slug>-a "$WT_ROOT/<task-slug>-a" "$BASE"
git worktree add -b agents/<task-slug>-b "$WT_ROOT/<task-slug>-b" "$BASE"
git worktree add -b agents/<task-slug>-c "$WT_ROOT/<task-slug>-c" "$BASE"
```

Existing remote branch:

```bash
git fetch origin
git worktree add --track -b <branch-name> "$WT_ROOT/<branch-name>" origin/<branch-name>
```

Useful defaults:

```bash
git config --global worktree.guessRemote true
git config --global checkout.defaultRemote origin
```

### Hydrate Each Copy

In each worktree:

```bash
cd "$WT_ROOT/<task-slug>-a"
./agent/scripts/agent-doctor.sh
./scripts/check.sh
```

Then run the project dependency setup command. Copy only local non-production environment files if needed:

```bash
cp /path/to/main-worktree/.env.local .env.local
```

Do not commit secrets.

### Agent Prompt Shape

```text
You are working in ../<repo>.worktrees/<task-slug>-a on branch agents/<task-slug>-a.

Implement one vertical slice for:
[feature brief]

Variant angle:
[smallest implementation | strongest type boundary | architecture cleanup first]

Read canonical files under agent/ as needed.
Do not touch other worktrees.
Run the formatter command after code edits, then narrow checks, then ./scripts/check.sh.
Final response must include changed files, checks run, checks skipped, tests changed, manifest changed, and agent/ docs updated.
```

### Compare Variants

Collect evidence:

```bash
git -C "$WT_ROOT/<task-slug>-a" status --short
git -C "$WT_ROOT/<task-slug>-a" diff --stat "$BASE"...HEAD
git -C "$WT_ROOT/<task-slug>-a" diff "$BASE"...HEAD
```

Chooser prompt:

```text
Compare variants A, B, and C against the feature brief.

Choose the winner using:
1. Correct behavior and passing checks.
2. Smallest coherent public interface.
3. Least boundary drift.
4. Behavior tests without weakened existing tests.
5. Lowest future context cost.

Return winner, rejected alternatives, exact files/commits to keep, and cleanup needed.
```

### Integrate And Clean Up

Push the winner:

```bash
git -C "$WT_ROOT/<task-slug>-a" push -u origin agents/<task-slug>-a
```

Or merge locally into an integration branch:

```bash
git switch -c integrate/<task-slug> origin/main
git merge --no-ff agents/<task-slug>-a
./scripts/check.sh
```

Remove losing worktrees through Git:

```bash
git worktree list
git worktree remove "$WT_ROOT/<task-slug>-b"
git worktree remove "$WT_ROOT/<task-slug>-c"
git worktree prune
```

Delete losing branches only after review:

```bash
git branch -D agents/<task-slug>-b
git branch -D agents/<task-slug>-c
git push origin --delete agents/<task-slug>-b
git push origin --delete agents/<task-slug>-c
```

Notes:

- Git refuses to check out the same branch in two worktrees. Give every agent attempt its own branch.
- Use `git worktree remove`; do not manually delete worktree directories unless you also run `git worktree prune`.
- If the winning branch intentionally changed tests, run `./scripts/update-test-manifest.sh` before the final `./scripts/check.sh`.
- After a GitHub pull request merges, delete the head branch unless another open pull request still uses it as a base.
- References: [Git worktree docs](https://git-scm.com/docs/git-worktree.html), [GitHub branch docs](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-branches).

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
./scripts/check-project.sh
```

Run the project-specific formatter check, linter, typecheck, and tests configured for this codebase.

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

```bash
git worktree list
```

List active worktrees and their checked-out branches.

```bash
git worktree remove ../<repo>.worktrees/<task-slug>-b
```

Remove a completed or rejected worktree.

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
9. Optional (easy to remove): Final Reviewer sub-agent reports `approved for merge` for medium/high-risk changes.
10. If worktrees were used, the winning branch is identified and rejected worktrees are removed or intentionally kept.
11. `scripts/check-project.sh` includes formatter check mode and lint for the current project stack.

## 13. Quick Recovery

If an agent makes a messy change:

1. Stop feature expansion.
2. Run `./scripts/check.sh`.
3. Ask the agent to repair only from tool output.
4. If design drift caused the issue, run `grill-me`.
5. If tests changed unexpectedly, run `./scripts/check-tests-unchanged.sh` and inspect the diff.
6. If one module is absorbing too much change, run `tracking-entropy` and then `improving-architecture`.
