---
description: "Write a plan file for new work, a rework, a migration or an architectural change. Ends with an approved plan, no code."
argument-hint: "[what to plan | issue id]"
---

You are writing a plan for a piece of work. **Planning ends with an approved plan, not with code.** Execution is `/tt:impl`'s job; this agenda stops at the handoff. This file owns the plan's path, structure and ending; a planning skill, if loaded, contributes technique only.

Distinct from:
- `/tt:impl` — executes an approved plan (or a small task that needs none).
- `/tt:debug` — diagnoses a failure (planning a fix is part of that flow, not this one).
- `/tt:refactor` — restructures behaviour-preserving (planning is inline, scoped to the structural move).

## 1. Clarify Scope
Derive the subject from context — default: the work under discussion. Only if genuinely underivable, ask the user to choose:
- [ ] A new feature or capability (ask which)
- [ ] A rework of existing functionality (ask which, what shape it needs)
- [ ] A migration or breaking change (ask source/target, callers affected)
- [ ] An architectural change without a specific feature (ask what problem motivates it)

Capture: success criteria, constraints, non-goals, deadlines, stakeholders. A plan without success criteria is wishful thinking. For each criterion name what, other than you or the user, shows it is met: a test, a reproduction, a measurement, a reviewer.

**Open decisions do not stall the plan.** List every question whose answer changes the plan in one table, each with the default you chose and why, then proceed on the defaults. The user changes the ones they disagree with.

## 2. Investigate
- Analyse the existing codebase: architecture, patterns, conventions, dependencies.
- Identify where and how the proposed work integrates.
- Note existing utilities, base classes, or patterns to reuse — and anti-patterns to avoid.
- If the planning subject is unfamiliar territory, dispatch an Explore subagent before continuing.

## 3. Consult Language Context

Detect the project's primary language(s) and pull the matching context file(s) — these capture house-style preferences (linters, formatters, packaging idiom, idiom expectations) the plan must honour:

- Nix-only or Nix as substrate → `~/.claude/tt/languages/nix.md`.
- Rust → `~/.claude/tt/languages/rust.md` (assumes the Nix layer).
- JavaScript / TypeScript → `~/.claude/tt/languages/javascript.md` (assumes the Nix layer).
- Shell scripts → `~/.claude/tt/languages/shell.md`.

Per-project `./CLAUDE.md` overrides anything in a context file; honour the override.

## 4. Apply the Lens Panel (mode = planning)

For each relevant lens, frame its dimensions as **commitments the proposed design must honour**, not retrospective audit. **Read lens files lazily** — pull only the section (Identity / Symptoms / Dimensions) you need for each lens as you reach it; skip lenses with no planning surface for this work. Pull guidance from `~/.claude/tt/lenses/<name>.md`.

Typically relevant:

- **`scope`** — what is essential vs accidental in this work. Reject premature abstraction, speculative configurability, dead-code-on-arrival. Smallest thing that delivers the value.
- **`architecture`** — module boundaries, dependency direction, data flow. Where does the work slot in, what does it depend on, what depends on it. Hidden coupling to break.
- **`security`** — trust boundaries the change crosses; authn/authz, secrets, input validation at those boundaries.
- **`reliability`** — failure modes the design must tolerate; idempotency, retries, observability hooks, deployability.
- **`performance`** — only if a measurable concern exists (data volume, hot path, contention). Otherwise defer.
- **`testing`** — how the work will be tested; seams, doubles, characterisation needs.
- **`quality`** — duplication, naming, separation within the module being touched.
- **`compatibility`** — when the work touches a public surface or stored data: what existing callers, clients and data must keep working, and the migration shape.
- **`ux`** — only if the change has a surface (CLI flag, API field, config knob, GUI control).
- **`ui`** — only if the change has a graphical surface.
- **`documentation`** — what tutorials/how-tos/reference/explanation or changelog/ADR entries this implies.

## 5. Write the Plan
Always produce the plan as a markdown file. Default path: `docs/plans/YYYY-MM-DD-<short-kebab-title>.md` (use today's date; create the directory if it does not exist). If the project has an existing convention for design docs (a different directory, a ticket system, an ADR layout), use that — the per-project `./CLAUDE.md` is the source of truth. Never plan in-conversation only — a file gives the plan a stable identity for review, edge-case analysis, and later execution. Structure:

- **Goal** — one sentence, user-facing.
- **Success criteria** — verifiable conditions that signal "done".
- **Non-goals** — explicitly excluded scope, one complete rule per line: what was decided against, what is tempting, what would quietly undo an earlier decision. `/tt:impl` and `/tt:ship` check the diff against this list.
- **Open decisions** — the table from §1: question, chosen default, rationale.
- **Approach** — sections per relevant lens, capturing commitments concretely (not checklists).
- **Steps** — incremental, each independently verifiable, with file/module targets and dependencies between steps.
- **Test strategy** — positive and negative cases, characterisation if touching legacy.
- **Risks & trade-offs** — known unknowns, chosen trade-offs with rationale.
- **Rollout** — migration, feature flags, deprecation timeline if applicable.

## 6. Present for Approval
If Plan Mode is already active in the conversation, exit it with the plan summary (`ExitPlanMode`) and the path to the written file. Otherwise present the plan inline alongside the file path. Do not call `EnterPlanMode` unilaterally — the user controls whether the conversation runs in Plan Mode.

On change requests, revise the file and re-present. Do not begin implementation from this agenda.

## 7. Next
- Design-sensitive plan → `/tt:review` with the plan file as the artefact, and `/tt:edge-cases`; fold the findings into the plan file.
- Approved → `/tt:impl` with the plan file. For work that needs its own branch first: `/tt:start`.
