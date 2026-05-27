# Coding with Agents (Properly)

> Bad code is the most expensive it's ever been.

While agentic coding is powerful, it introduces new engineering challenges around control, reliability, and maintainability.

The goal is not to make agents write more code; it is to make them produce code that stays easy to change.

## The Design Concept

This idea originates from Fred Brooks.

When you have more than one person working on something, there is some idea or invisible theory. Good systems are guided by a coherent underlying idea shared by the people building them. In agentic programming, the agent needs access to that concept before it starts generating implementation details.

### The Design Tree

The traditional "rational model" assumes a complete design tree (a tree of decisions) can be drawn upfront, which Brooks argues is rarely true for novel systems.

Unlike routine design, original design involves evolving, interconnected constraints where the "desiderata" (desired outcomes) change, making it difficult to fully map the tree of choices.

Instead of fully mapping a decision tree beforehand, design is a process of co-evolution, where the problem and the solution are understood more deeply through constant iteration.

This is what you want to do during the first stage of coding anything with an agent: you need to co-design it and try to come up with better and better versions of the decision tree.

### Fix 1: `/grill-me`

Force a shared design concept to exist before implementation using a **Pre-flight Design Review** workflow.

- **Implementation**: Before any code is written, the agent must run a `grill-me` sub-task where it critiques its own proposed plan.
- **Criteria**: The review must evaluate the plan for:
    - **Reliability**: How will it handle tool failures or ambiguous LLM outputs?
    - **Context Management**: Is the plan efficient with token usage and state persistence?
    - **Security**: Does it protect credentials and system integrity?
    - **Scalability**: How does the design hold up as task complexity increases?
- **Outcome**: The agent cannot proceed until it has answered its own "grilling" questions and updated the design tree accordingly.

## Skills

A skill packages instructions, resources, and optional scripts so that you don’t need to tell your agents to so something over and over again.

### Fix 1: Build clear skills

Shift from "prompt engineering" to "agent engineering" by following strict standards for skill and tool design:

- **Atomic Scoping**: Each tool should do one thing well (e.g., `copy_file`, `move_file` instead of `manage_files`).
- **Gerund Naming**: Use the `-ing` form for skill names (e.g., `fixing-bugs`, `testing-code`) to imply an ongoing capability.
- **Strict Contracts**: Use strong typing and JSON Schemas for inputs/outputs. Trim outputs to minimize token usage.
- **Informative Errors**: Return structured error messages that explain *why* a tool failed so the agent can self-correct.
- **Progressive Disclosure**: Keep core instructions concise; move detailed reference material (error codes, complex schemas) to separate assets loaded only when needed.
- **Temporary State Hygiene**: Keep session-specific implementation notes out of durable agent files. Use ignored session state for active work and clear it when the task finishes.

## Shared Language

Eric Evans' idea, summarized by Agile Alliance, is that the domain vocabulary should continue all the way into the source code.

In software engineering, we define a ubiquitous language as a language used by all team members within a bounded context to connect team activity with the software. This matters even more with agents because they infer structure from names. If naming is sloppy, the agent's reasoning is sloppy.

If a term is overloaded, it will be overloaded in prompts, code, tests, and bugs.

### Fix 1: Define Language

Active architectural enforcement of the **Living Glossary**:

- **Implementation**: Create a `docs/ubiquitous-language.md` file using a table format: `Business Term | Technical Symbol | Definition | Constraints`.
- **Value Objects**: Use the type system to wrap primitives (e.g., instead of `string email`, use a `EmailAddress` type/class). This prevents "primitive obsession" and ensures the agent uses the correct language.
- **Custom Linting**: Implement linting rules (e.g., `eslint-plugin-n`) to forbid ambiguous terms like `Data`, `Manager`, or `ManagerBase` in favor of domain-specific nouns defined in the glossary.
- **PR Documentation**: Make naming a primary focus of code reviews. If a reviewer or agent asks "what does this variable represent?", the Ubiquitous Language has failed.

## Feedback Loops

We will go through some ways to create effective feedback loops:

### Fix 1: Static Types

Implement a **Generate-Check-Fix** loop to turn the agent into a deterministic engineer:

- **The Loop**: The agent generates code, runs the compiler (e.g., `tsc`, `mypy`, `rustc`), captures errors, and feeds them back into the next prompt.
- **Strict Mode**: Force "strict" compiler modes (e.g., `strict: true` in `tsconfig.json`). This narrows the search space for valid code, preventing "lazy" but buggy implementations.
- **Type-Driven Development**: Instruct the agent to write interfaces and types *first*. The type system then acts as the "nervous system," providing sensory feedback during logic implementation.

### Fix 2: MCP servers

Standardize on the **Model Context Protocol (MCP)** to provide deterministic tool access:

- **Standard Tools**: Use reference MCP servers for `Filesystem`, `Git`, and `Fetch` (web-to-markdown) to ensure the agent has reliable system access.
- **Custom Project Evaluators**: Build project-specific MCP servers (using `FastMCP` or MCP SDK) to allow the agent to query the database, check logs (e.g., Sentry), or run specialized simulations.
- **Browser Automation Standard**: For web apps and HTML/CSS tasks, default to **Microsoft Playwright MCP** for deterministic browser feedback (structured accessibility snapshots and reliable page interaction).

### Fix 3: Automated Tests

Align testing with domain intent through **BDD (Behavior Driven Development)**:

- **Implementation**: Write test scenarios in plain English (e.g., using Cucumber) that use terms from the Ubiquitous Language.
- **Internal Feature Slices**: Use the `tdd` skill to implement "red-green-refactor" loops one safe internal step at a time, ensuring logic is verified without asking the developer to manage slice bookkeeping.
- **Feedback Quality**: If a test fails, the agent must treat the failure output as a high-signal requirement rather than a generic error.

## Entropy

AI increases throughput. It also increases the speed at which teams can manufacture entropy. Better agentic programming is therefore mostly a problem of decreasing entropy as much as possible.

The idea of entropy is from *The Pragmatic Programmer*. Roughly, the idea is that entropy in code (like in physics) increases over time due to small structural compromises accumulate until the next change becomes harder, riskier, and more confusing than the last.

High software entropy is characterized by hugely complex code bases.

> Complexity is anything related to the structure of a software system that makes it hard to understand and modify the system.
> 

### Fix 1: Track "entropy hotspots”

Use **Code Forensics** to identify the intersection of High Churn and High Complexity:

- **Hotspot Metrics**: Use tools like `Code Maat` or `git-complexity` to correlate commit frequency with cyclomatic complexity.
- **Lightweight Monitoring**: Run periodic shell one-liners to flag high-risk files:
    ```bash
    # Top 20 most changed files in the last year
    git log --format=format: --name-only --since=12.month | egrep -v '^$' | sort | uniq -c | sort -nr | head -20
    ```
- **Refactoring Triggers**: Define a threshold (e.g., "files touched by >10 features") that triggers an automatic agent task to modularize the hotspot.

## Modularity

Software quality depends heavily on deep modules: modules with simple interfaces that hide substantial internal complexity.

Eric Evans’, *Domain-Driven Design* communicates this idea as follows:

- modules should "tell the story of the system"
- decomposition should follow "conceptual contours"

This is where locality matters. Related code should live together. Unrelated code should not be mixed merely because it shares a framework layer.

### Fix 1: Design Modules by Responsibility

Encapsulate logic using **Internal Boundaries**:

- **Implementation**: Use language features to hide internals (e.g., `internal` packages in Go, `private` exports in TS, or `_` prefixes in Python).
- **Tooling**: Use tools like `ts-morph` or custom linting rules to ensure that a module's "responsibility" is not leaked across boundaries.
- **Agent Instruction**: Explicitly tell the agent: "This module is only responsible for [Task]. Do not import logic from [Other Task] merely for convenience."

### Fix 2: Prefer Deep Modules

Apply John Ousterhout's **Deep Module** principle:

- **Goal**: A module should have a small, precise interface but extensive hidden logic.
- **Detection**: Identify "Shallow" modules where the interface is nearly as complex as the implementation (e.g., a function that just calls another function with the same parameters).
- **Refactoring**: Propose mergers of shallow modules to "deepen" the system and reduce the cognitive load of navigation.

### Fix 3: Make Public Interfaces Smaller

Enforce **Interface-First Development**:

- **Explicit Exports**: Use a single entry point (e.g., `index.ts` or `__init__.py`) and only export the absolute minimum required for other modules.
- **Import Restrictions**: Use `eslint-plugin-import` or similar to prevent "reaching into" another module's internal directories.
- **Seams**: Ensure every public interface acts as a "seam" where behavior can be substituted without touching the calling code.

## Test Driven Development (TDD)

> Good codebases are easy to test, which leads to better quality feedback loops.
> 

Large undirected generations are dangerous because they delay feedback. By the time the agent checks types, tests, or runtime behavior, it may have already spread bad assumptions across many files.

### Testing Decisions

Testing in inherently a difficult problem. First, we need to answer the following 3 broad questions to get a sense of what the test will be about:

1. How big is the unit?
2. What to mock?
3. What behaviours to test?

### Test Pyramid

The **Test Pyramid** is a visual model introduced by Martin Fowler to describe the ideal distribution of tests in a software project. It emphasizes:

- **Many unit tests** (fast, isolated, cheap to write and run).
- **Fewer integration tests** (slower, test interactions between components).
- **Even fewer end-to-end tests** (slowest, test the entire system).

Ideally, you want all of these but you want them to run at different points to ensure that we are not wasting too much time and compute on testing.

### Fix 1: Write Good Tests

Move beyond simple example-based tests to **Invariant Verification**:

- **Property-Based Testing**: Use tools like `Hypothesis` (Python) or `fast-check` (TS) to validate that certain "properties" (invariants) hold true for thousands of random inputs.
- **Test Pyramid Integrity**: Ensure a distribution of many fast unit tests, fewer integration tests, and minimal E2E tests.
- **Coverage for Agents**: Instruct the agent that a change is "incomplete" until it has added a test case that specifically targets the new edge case it just implemented.

### Fix 2: Freeze The Tests

Prevent "moving the goal posts" during implementation by **locking the test suite**:

- **Pre-commit Hook**: Implement a git hook that marks `/tests` directories as read-only (or fails the commit) if a "feature" branch is being modified, unless the commit is explicitly tagged as `test-update`.
- **CI Enforcement**: Fail CI if test files are modified in the same PR that implements the fix, unless it's a TDD "Test First" phase.
- **Agent Rule**: The agent must confirm: "I have verified that my changes pass the existing tests without modifying the test logic."

## Coupling

Seams and adapters are the practical machinery that makes agentic code safe.

Now, we need to understand what these concepts refer to. 

> a seam is a place where you can alter behavior in your program without editing in that place
> 

Essentially, a seam is a change point that lets you substitute behavior.

In agentic programming, these patterns matter because the agent should be able to change implementation at the edges without corrupting the core model.

Without seams and adapters, external details leak into the domain.

### Fix 1: Improve architecture

Use a systematic loop to **Rescue the Codebase** from "ball of mud" patterns:

- **Friction Identification**: Periodically run an agent task to find "shallow" modules or areas where understanding one concept requires bouncing between many files.
- **RFC Generation**: When the user explicitly requests parallel agent work, use multiple sub-agents to design competing interfaces for a friction point. Otherwise, perform the comparison locally.
- **Decision Records**: Capture the winner in an ADR (Architecture Decision Record) and generate a concrete GitHub issue with the refactoring plan.
- **Reference**: Use the [Improve Codebase Architecture](https://github.com/mattpocock/skills/blob/main/skills/engineering/improve-codebase-architecture/SKILL.md) framework to manage coupling effectively.

## Domain Driven Design (DDD)

Domain-Driven Design (DDD) is **a software development approach that places the core business domain (the problem area) and its logic at the heart of software design**. It focuses on modeling complex systems based on a "Ubiquitous Language" shared by technical and business experts, rather than organizing primarily around technical infrastructure.

Domain-Driven Design becomes more valuable in the AI era because it gives agents a stable map of the problem space.

Here is the key idea behind this approach:

1. focus on the core domain
2. explore models collaboratively
3. speak a ubiquitous language within an explicitly bounded context

### Fix 1: Define Domain Boundaries

Enforce Bounded Contexts through **Directory Hierarchy**:

- **Implementation**: Map business sub-systems (e.g., `/billing`, `/fulfillment`) directly to top-level directories. Avoid generic technical layers like `/services` or `/models` at the root.
- **Context Mapping**: Define clear interfaces between boundaries. An agent working in the `billing` context should not be able to reach into `inventory` internals.
- **Entity Specification**: In the design phase, explicitly set out the **Entities, Value Objects, and Aggregates**. This gives the agent a stable map of the "Identity" vs "Data" in the system.
- **Boundary Guards**: Use automated checks (e.g., dependency-cruiser) to ensure no illegal imports occur between bounded contexts.
