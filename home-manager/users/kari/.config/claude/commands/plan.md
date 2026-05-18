
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

You are writing a plan for a piece of work. **Planning ends with an approved plan, not with code.** Execution is `/tt:impl`'s job; this agenda stops at the handoff. If a `writing-plans` skill is available, invoke it for the procedure.

Distinct from:
- `/tt:impl` — executes an approved plan (or a small task that needs none).
- `/tt:debug` — diagnoses a failure (planning a fix is part of that flow, not this one).
- `/tt:refactor` — restructures behaviour-preserving (planning is inline, scoped to the structural move).

## 1. Clarify Scope
If the planning subject is unclear, ask the user to choose:
- [ ] A new feature or capability (ask which)
- [ ] A rework of existing functionality (ask which, what shape it needs)
- [ ] A migration or breaking change (ask source/target, callers affected)
- [ ] An architectural change without a specific feature (ask what problem motivates it)

Capture: success criteria, constraints, non-goals, deadlines, stakeholders. A plan without success criteria is wishful thinking.

## 2. Investigate
- **Search persistent memory first.** Use `mcp__plugin_claude-mem_mcp-search__search` with terms from the task brief; pull `timeline` / `get_observations` on hits that look relevant. Past work in the same area often dictates the shape of the new plan and surfaces gotchas the codebase no longer remembers.
- Analyse the existing codebase: architecture, patterns, conventions, dependencies.
- Identify where and how the proposed work integrates.
- Note existing utilities, base classes, or patterns to reuse — and anti-patterns to avoid.
- If the planning subject is unfamiliar territory, dispatch an Explore subagent before continuing.

## 3. Consult Language Context

Detect the project's primary language(s) and pull the matching context file(s) — these capture house-style preferences (linters, formatters, packaging idiom, idiom expectations) the plan must honour:

- Nix-only or Nix as substrate → `/tt:mod:nix`.
- Rust → `/tt:mod:rs` (assumes the Nix layer).
- JavaScript / TypeScript → `/tt:mod:js` (assumes the Nix layer).
- Shell scripts → `/tt:mod:sh`.

Per-project `./CLAUDE.md` overrides anything in a context file; honour the override.

## 4. Apply the Lens Panel (mode = planning)

For each relevant lens, frame its dimensions as **commitments the proposed design must honour**, not retrospective audit. **Read lens files lazily** — pull only the section (Identity / Symptoms / Dimensions) you need for each lens as you reach it; skip lenses with no planning surface for this work. Pull guidance from `commands/pov/<name>.md`.

Typically relevant:

- **`/tt:pov:scope`** — what is essential vs accidental in this work. Reject premature abstraction, speculative configurability, dead-code-on-arrival. Smallest thing that delivers the value.
- **`/tt:pov:arch`** — module boundaries, dependency direction, data flow. Where does the work slot in, what does it depend on, what depends on it. Hidden coupling to break.
- **`/tt:pov:sec`** — trust boundaries the change crosses; authn/authz, secrets, input validation at those boundaries.
- **`/tt:pov:reliability`** — failure modes the design must tolerate; idempotency, retries, observability hooks, deployability.
- **`/tt:pov:perf`** — only if a measurable concern exists (data volume, hot path, contention). Otherwise defer.
- **`/tt:pov:testing`** — how the work will be tested; seams, doubles, characterisation needs.
- **`/tt:pov:quality`** — duplication, naming, separation within the module being touched.
- **`/tt:pov:ux`** — only if the change has a surface (CLI flag, API field, config knob, GUI control).
- **`/tt:pov:docs`** — what tutorials/how-tos/reference/explanation or changelog/ADR entries this implies.

## 5. Write the Plan
Always produce the plan as a markdown file. Default path: `docs/plans/YYYY-MM-DD-<short-kebab-title>.md` (use today's date; create the directory if it does not exist). If the project has an existing convention for design docs (a different directory, a ticket system, an ADR layout), use that — the per-project `./CLAUDE.md` is the source of truth. Never plan in-conversation only — a file gives the plan a stable identity for review, edge-case analysis, and later execution. Structure:

- **Goal** — one sentence, user-facing.
- **Success criteria** — verifiable conditions that signal "done".
- **Non-goals** — explicitly excluded scope.
- **Approach** — sections per relevant lens, capturing commitments concretely (not checklists).
- **Steps** — incremental, each independently verifiable, with file/module targets and dependencies between steps.
- **Test strategy** — positive and negative cases, characterisation if touching legacy.
- **Risks & trade-offs** — known unknowns, chosen trade-offs with rationale.
- **Rollout** — migration, feature flags, deprecation timeline if applicable.

## 6. Present for Approval
If Plan Mode is already active in the conversation, exit it with the plan summary (`ExitPlanMode`) and the path to the written file. Otherwise present the plan inline alongside the file path. Do not call `EnterPlanMode` unilaterally — the user controls whether the conversation runs in Plan Mode.

On change requests, revise the file and re-present. Do not begin implementation from this agenda.

## 7. Handoff
When the plan is approved, **suggest** these next steps for the user to run (this agenda does not invoke them):

**Plan validation (the user runs these against the plan file):**
- **`/tt:review`** — scope = "an implementation plan"; lens panel applies to a plan as readily as to code.
- **`/tt:edge-cases`** — surface hypothetical risks before they harden into bugs.

**Git workflow (optional; PR-first style):**
- **`/tt:act:branch`** — create a branch named after the plan.
- **`/tt:act:commit`** — commit the plan file as the initial commit on the branch.
- **`/tt:act:push`** + **`/tt:act:pr`** — open a draft PR so CI runs alongside development.

**Execution:**
- **`/tt:impl`** — with the plan file as the input artefact.

If validation steps surface revisions, return to step 5 and update the plan file before continuing.
