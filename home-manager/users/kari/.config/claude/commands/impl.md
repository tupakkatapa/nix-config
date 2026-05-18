
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

You are executing a piece of work — either against an approved plan from `/tt:plan` or a small task that needs no formal plan. **Planning is `/tt:plan`'s job, not this one.** If an `executing-plans` skill is available, invoke it for the procedure.

Distinct from:
- `/tt:plan` — produces an approved plan; this agenda consumes it.
- `/tt:debug` — fixes a failure; that flow plans the fix inline.
- `/tt:refactor` — restructures behaviour-preserving; planning is scoped to the structural move.

## 1. Locate or Create the Plan
- Default plan location: `docs/plans/YYYY-MM-DD-<short-kebab-title>.md` (the convention written by `/tt:plan`). If the user names a specific plan, read that one; otherwise read the most recent file in `docs/plans/` or the file whose slug matches the current branch name; confirm the scope is unchanged.
- **If no plan exists and the work is non-trivial** (new feature, multi-file change, architectural decision, unclear requirements, anything that crosses module boundaries), **stop and ask the user to run `/tt:plan` first**. Do not improvise a plan inside this agenda.
- **If the work is trivial** (typo, single-line fix, mechanical change, user-supplied detailed specs that obviate planning), proceed without a plan, but **state the trivial-work classification back to the user and what you will do** before making any change. If the user objects or the scope grows mid-execution, stop and route to `/tt:plan`.

## 2. Consult Language Context
Detect the project's primary language(s) and pull the matching context file(s) so house-style preferences (linters, formatters, packaging idiom, idiom expectations) are honoured throughout execution:

- Nix-only or Nix as substrate → `/tt:mod:nix`.
- Rust → `/tt:mod:rs`.
- JavaScript / TypeScript → `/tt:mod:js`.
- Shell scripts → `/tt:mod:sh`.

Per-project `./CLAUDE.md` overrides anything in a context file; honour the override.

## 3. Implementation
Execute step-by-step against the plan (or the task description, for trivial work):
- Complete each step fully before moving to the next.
- After each step, verify the result locally (compile, run, test the affected surface).
- Flag deviations from the plan and confirm with the user before proceeding. A deviation discovered mid-execution often means the plan needs revision, not silent improvisation.

If you discover the plan is wrong (assumption broken, blocked by missing context, surfaces a bug), stop and return to `/tt:plan` rather than patch over it.

## 4. Testing
Implement tests covering:
- **Positive cases** — correct behaviour with valid inputs and expected usage.
- **Negative cases** — invalid inputs, edge cases, error conditions; what should fail, fails gracefully.

Adapt to the project's testing tools and conventions. If no test infrastructure exists, propose one — but that proposal goes through `/tt:plan`, not inline.

**Two-hats discipline for tests** (Beck): adding *new test files / fixtures / a harness* is structural; commit those before behavioural code so the test scaffolding is its own commit. Adding *cases to an existing harness* may ride with the behavioural commit they cover.

## 5. Run Automated Checks
Run pre-commit hooks (if configured), linters, and the project's tests. Fix all failures before continuing.

## 6. Summary
- Steps completed against the plan.
- Deviations and their rationale.
- Tests added.
- Follow-ups deferred (link to plan or open issues).

## 7. Handoff
When implementation is complete, suggest running `/tt:review` to validate the work, then `/tt:act:commit`.
