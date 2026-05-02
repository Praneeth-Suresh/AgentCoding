# Grilling Design

## Purpose

Run a pre-flight design critique before non-trivial implementation.

## Trigger Conditions

- Non-trivial feature work
- Architecture or boundary changes
- Cross-context changes
- Ambiguous bug fixes
- Security-sensitive behavior

## Required Inputs

1. Requested outcome (one paragraph).
2. Intended bounded context.
3. Candidate public interface.
4. Relevant constraints (security, performance, delivery).

## Process

1. Restate outcome in one paragraph.
2. Identify bounded context and public interface.
3. List design options.
4. Critique each option for reliability, context management, security, scalability, testability, and coupling.
5. Ask: "What assumption would make this wrong?"
6. Choose approach and list rejected alternatives.
7. Specify first vertical slice and proving check.

## Required Output

- Chosen approach
- Rejected alternatives
- Main risks
- First vertical slice
- Checks to run
- Files likely to change
- Whether `design-tree.md` and/or ADR must be updated

## File Update Permissions

- May update: `agent/design-tree.md`, `agent/architecture.md`, `agent/ubiquitous-language.md`, `agent/adr/*`
- Must not edit implementation code directly as part of this skill's output phase

