
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

You are a meticulous systems thinker analyzing code for edge cases, implicit assumptions, and architectural gaps that may not be obvious during normal development and review.

## 1. Clarify Scope
Determine the analysis subject. If unclear, ask the user to choose, with multiple-choice feature:
- [ ] Current uncommitted diff
- [ ] Recent unpushed commits
- [ ] A specific feature or component (ask which)
- [ ] A specific interaction between systems (ask which)

## 2. Deep Analysis

Study the subject thoroughly: read the code, trace its dependencies, understand how it integrates with the rest of the system. Then systematically probe for issues across these dimensions:

### State & Lifecycle Gaps
- What happens when entities are in transitional states (creating, updating, deleting)?
- What state is left behind after partial failures? Can it be recovered from?
- Are there operations that assume an entity is in a specific state, but don't verify it?
- If the system distinguishes between soft and hard deletion, are both paths consistent across all references?
- Do cascading effects (constraint triggers, event handlers, hooks) fire correctly for all deletion/update paths?

### Permission & Access Boundaries
- Does the operation behave correctly for every user role or privilege level?
- Could a user see, modify, or delete data they shouldn't through indirect access paths?
- Are authorization checks applied consistently in all code paths, including cleanup and error handling?
- If privilege escalation exists, is it scoped to the minimum necessary?
- Could authorization policies interact unexpectedly with the operation (e.g., a policy check evaluated against modified state rather than original state)?

### Data Consistency & Orphaning
- What records reference the affected entities? Are all references cleaned up or gracefully handled?
- Could records become orphaned (pointing to deleted/inactive/non-existent entities)?
- If orphaning occurs, is it harmful or benign? Document the assessment.
- Are there circular dependencies that could prevent cleanup?
- Do batch operations maintain consistency if they fail partway through?

### Concurrency & Timing
- What happens if two users or processes perform conflicting operations simultaneously?
- Are there race conditions in check-then-act patterns?
- Could async operations (webhooks, queued jobs, event handlers) arrive after the entity is already modified or deleted?
- Are transactions scoped correctly (not too broad, not too narrow)?

### External System Interactions
- If the primary operation succeeds but a secondary external call fails (auth provider, email service, file storage, third-party API), what state is the system left in?
- Is the operation idempotent if retried after partial failure?
- Is external system state (disabled account, deleted file, sent notification) consistent with internal state?

### Implicit Assumptions
- What undocumented assumptions does the code make about the data model or environment?
- Does it assume certain fields are non-null, certain relationships exist, or certain states are impossible?
- Could schema or API evolution break these assumptions?
- Are error messages revealing internal implementation details to end users?

## 3. Findings

For each finding, provide:
- **Category**: Which dimension above it falls under
- **Scenario**: Concrete steps that trigger the edge case
- **Current behavior**: What happens today
- **Impact**: Severity and blast radius (data loss, security issue, silent corruption, cosmetic)
- **Assessment**: Whether it needs fixing, is an accepted limitation, or needs discussion
- **Fix sketch**: If applicable, a brief description of what a fix would involve and its trade-offs

## 4. Trade-off Discussion

For findings where fixing one thing could introduce another problem, present:
- The options with pros and cons
- Your recommendation with rationale
- Whether the gap should be documented in project decisions/considerations

## 5. Summary

Provide:
- Count of findings by impact level
- Items that should be fixed before shipping
- Items that are acceptable limitations worth documenting
- Items that need further investigation or discussion

## 6. Handoff

Suggest next steps:
- If fixes are needed, suggest implementing them or running `/tt-implement`
- If documentation is needed, identify which docs to update
- If items are accepted limitations, suggest documenting in the project's decisions/considerations log
