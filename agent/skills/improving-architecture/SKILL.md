# Improving Architecture

## Purpose

Reduce coupling and context sprawl by improving module boundaries.

## Trigger Conditions

- A feature touches too many unrelated files
- Ownership or module boundaries are unclear
- Repeated illegal/fragile cross-context imports
- "Shallow module" behavior (pass-through layers with no encapsulation)

## Required Inputs

1. Friction point description.
2. Current module/context boundaries.
3. Imports and public API touchpoints.
4. Existing tests guarding the area.

## Process

1. Identify friction and hidden domain concept.
2. Find shallow modules and pass-through APIs.
3. Propose smaller public boundary.
4. Move internals behind boundary.
5. Add or update boundary-protecting tests.
6. Record durable design choice in ADR if needed.

## Required Output

- Current problem
- Proposed boundary
- Public API after change
- Internal files behind the API
- Tests that protect the boundary
- ADR needed? (yes/no and why)

## File Update Permissions

- May update: implementation files, `agent/architecture.md`, `agent/design-tree.md`, `agent/adr/*`
- Must keep changes scoped to one vertical slice per iteration

