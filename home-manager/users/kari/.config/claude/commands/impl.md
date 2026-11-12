---
description: "Execute an approved plan file, or a small change that needs no plan, in the current branch."
argument-hint: "[plan file]"
---

You are executing a piece of work — either against an approved plan from `/tt:plan` or a small task that needs no formal plan. **Planning is `/tt:plan`'s job, not this one.**

Distinct from:
- `/tt:plan` — produces an approved plan; this agenda consumes it.
- `/tt:debug` — fixes a failure; that flow plans the fix inline.
- `/tt:refactor` — restructures behaviour-preserving; planning is scoped to the structural move.

## 1. Locate or Create the Plan
- Default plan location: `docs/plans/YYYY-MM-DD-<short-kebab-title>.md` (the convention written by `/tt:plan`). If the user names a specific plan, read that one; otherwise read the file whose slug matches the current branch name. No match means no plan.
- **If no plan exists and the work is non-trivial** (new feature, multi-file change, architectural decision, unclear requirements, anything that crosses module boundaries), **run `/tt:plan` first**, then continue here with its plan. Do not improvise a plan inside this agenda.
- **If the work is trivial** (typo, single-line fix, mechanical change, user-supplied detailed specs that obviate planning), proceed without a plan — **state the trivial-work classification and what you will do in one line, then proceed without waiting for acknowledgement** (the user interrupts if wrong). If the scope grows mid-execution, stop and route to `/tt:plan`.

## 2. Consult Language Context
Detect the project's primary language(s) and pull the matching context file(s) so house-style preferences (linters, formatters, packaging idiom, idiom expectations) are honoured throughout execution:

- Nix-only or Nix as substrate → `~/.claude/tt/languages/nix.md`.
- Rust → `~/.claude/tt/languages/rust.md`.
- JavaScript / TypeScript → `~/.claude/tt/languages/javascript.md`.
- Shell scripts → `~/.claude/tt/languages/shell.md`.

Per-project `./CLAUDE.md` overrides anything in a context file; honour the override.

## 3. Implementation
Execute step-by-step against the plan (or the task description, for trivial work):
- Complete each step fully before moving to the next.
- After each step, verify the result locally (compile, run, test the affected surface).
- Check each step against the plan's **Non-goals**; a change that breaches one is a plan-invalidating deviation.
- Deviations from the plan: **minor** (same intent, different mechanics) → flag in one line and proceed; **plan-invalidating** (broken assumption, changed scope) → stop, don't silently improvise.

If you discover the plan is wrong (assumption broken, blocked by missing context, surfaces a bug), stop and return to `/tt:plan` rather than patch over it.

## 4. Testing
Implement tests covering:
- **Positive cases** — correct behaviour with valid inputs and expected usage.
- **Negative cases** — invalid inputs, edge cases, error conditions; what should fail, fails gracefully.

Adapt to the project's testing tools and conventions. If no test infrastructure exists, propose one — but that proposal goes through `/tt:plan`, not inline.

**Two hats for tests** (Beck): a new test file, fixture or harness is structural; cases added to an existing harness ride with the behaviour they cover. Do not commit here: `/tt:act:commit` splits structural from behavioural when it commits.

## 5. Run Automated Checks
Run pre-commit hooks (if configured) and the tests that cover the changed code; the full suite is CI's. Fix failures this session caused; report failures that were already there.

## 6. Summary
- Steps completed against the plan.
- Deviations and their rationale.
- Tests added.
- Follow-ups deferred (link to plan or open issues).

## 7. Handoff
Next: `/tt:ship`.
