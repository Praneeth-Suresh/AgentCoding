# Agent Control Plane

This directory is the canonical source of truth for agent behavior in this repository.

## Why this exists

The system follows the core rule from `Plan.md`: generation speed is useful only when deterministic feedback loops are stronger than the generation loop. These files make that rule executable.

## Source of truth model

1. `agent/` files are canonical.
2. Tool-specific instruction files (`AGENTS.md`, `CLAUDE.md`, `.cursor/rules/agent-rules.md`, `.github/copilot-instructions.md`, `.codex/AGENTS.md`) are generated shims.
3. Do not edit generated shims manually. Edit `agent/tool-instruction-template.md` and run:

```bash
./agent/scripts/sync-agent-env.sh
```

## Bootstrap checklist

Fill these files before feature implementation:

- `project-brief.md`
- `ubiquitous-language.md`
- `design-tree.md`
- `architecture.md`
- `testing-policy.md`
- `agent-rules.md`

Then run:

```bash
./agent/scripts/sync-agent-env.sh
./agent/scripts/agent-doctor.sh
./scripts/check.sh
```

## Test manifest scope

Configure test immutability detection in `agent/test-manifest.conf`.

- `INCLUDE_GLOBS`: which test files are tracked
- `EXCLUDE_GLOBS`: ignored paths
- `MANIFEST_PATH`: where the hash manifest is stored

## Decision recording rule

- Use `design-tree.md` for evolving or unresolved design choices.
- Use `agent/adr/` when a decision changes durable architecture, boundaries, terminology, data shape, or test strategy.

## Skill naming alias

- `grill-me` is the shorthand alias.
- `grill-me` is the canonical skill contract.
