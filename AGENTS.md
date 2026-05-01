# Repository Guidelines

## Project Structure & Module Organization

This repository is currently documentation-focused. The main files live at the repository root:

- `introduction.md`: framing and motivation for agentic engineering.
- `Coding.md`: longer guide to better agentic programming.
- `Plan.md`: source ideas and principles.
- `Final.md`: actionable implementation gameplan.

There is no `src/`, `tests/`, or `assets/` directory yet. If code is added later, keep source files under `src/`, tests under `tests/`, and static/reference assets under `assets/` or `docs/assets/`.

## Build, Test, and Development Commands

No build system or package manager is configured at the moment. For documentation edits, use simple local checks:

```bash
sed -n '1,120p' Final.md
wc -l *.md
```

If a toolchain is added later, expose standard commands such as `make check`, `npm test`, or `pytest` and document them here.

## Coding Style & Naming Conventions

Use Markdown for repository content. Keep headings descriptive, use fenced code blocks with language labels, and prefer short paragraphs over dense prose. Use ASCII punctuation unless quoting existing material that requires otherwise.

Name files by purpose with clear nouns, for example `Plan.md`, `Final.md`, or `architecture.md`. For future agent instructions, prefer `agent-rules.md`, `ubiquitous-language.md`, and `testing-policy.md`.

## Testing Guidelines

There are no automated tests yet. For now, review Markdown manually for:

- Broken heading hierarchy.
- Unclosed code fences.
- Typos in commands or file paths.
- Repetition between `Plan.md` and `Final.md`.

If code is introduced, add tests alongside the feature and include the command required to run them.

## Commit & Pull Request Guidelines

Git metadata is not currently usable from this workspace, so no existing commit convention can be inferred. Use concise imperative commit messages, such as `Add repository contributor guide` or `Refine agent workflow plan`.

Pull requests should include a short summary, the files changed, and any verification performed. For documentation-only changes, screenshots are unnecessary unless rendered formatting is important.

## Agent-Specific Instructions

Treat `Plan.md` as the conceptual source and `Final.md` as the operational plan. Keep future agent guidance concrete, testable, and tied to repository files rather than hidden chat context.
