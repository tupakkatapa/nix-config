
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

You are conducting a code review across the `/tt:pov:*` dimensions inline (single agent, no subagent dispatch by default).

**Read lens files lazily.** Don't load all 10 into main context upfront — each lens file is a reference. When you reach a lens in §2, read the section you need (Identity → Symptoms → Dimensions → Output Schema), apply, move on. Skip lenses with no surface in this artefact entirely.

**Escalate to subagent dispatch when:** (a) the diff is too large for one context, or (b) the artefact triggers most of the panel and reading every lens file inline would pollute the main context. In that case dispatch via the Task tool in three stages: sequential `scope` → `architecture`; parallel `ux`/`security`/`performance`/`reliability`/`quality`/`testing`; final `docs` → `aesthetics`. Each subagent reads only its own lens file; main context only sees the consolidated findings. Default to inline for small-to-medium diffs — cross-lens synthesis (scope cuts removing downstream concerns) is the value, and panel dispatch sacrifices it.

## 1. Clarify Scope
If the review subject is unclear, ask the user to choose:
- [ ] Current uncommitted diff
- [ ] Recent unpushed commits
- [ ] A specific fix/feature (ask which)
- [ ] An implementation plan

## 2. Apply the Lens Panel (mode = review)

Read each lens file (`commands/pov/<name>.md`) for the dimensions it owns, then apply them in this order. Each lens filters what the next inspects.

1. **`/tt:pov:scope`** — cull gold-plating, premature abstraction, dead code, speculative configurability first.
2. **`/tt:pov:arch`** — module boundaries, dependency direction, data flow, layering.
3. **`/tt:pov:sec`** — trust boundaries, authn/authz, secrets, input validation. *(Skip only if no boundary is crossed.)*
4. **`/tt:pov:reliability`** — failure modes, idempotency, observability, recoverability.
5. **`/tt:pov:perf`** — only when a measurable concern exists; otherwise defer.
6. **`/tt:pov:quality`** — duplication, naming, idiom, separation of concerns within module boundaries.
7. **`/tt:pov:testing`** — coverage of critical paths, edge cases, testability.
8. **`/tt:pov:ux`** — only if the change has a surface (CLI / API / config / GUI / TUI / library).
9. **`/tt:pov:docs`** — README, tutorials, how-tos, reference, changelog, runbooks, ADRs.
10. **`/tt:pov:style`** — formatting, naming consistency, comment discipline, ordering. *(Runs last; only one lens can be last.)*

For each finding, record:
- **Lens** — which dimension raised it.
- **Severity** — Blocker / High / Medium / Low / Nit.
- **Description** — the issue, with `file:line`.
- **Recommended fix** — concrete.
- **Confidence** — High / Medium / Low.

Resolve conflicting findings by preferring the more fundamental concern: scope → architecture → security → reliability → performance → quality → testing → ux → docs → aesthetics.

## 3. Disposition (not apply-now)

Review *finds* defects. Fixing them is a separate hat per Beck's *two hats* rule; bundling find + fix into one commit usually mixes tidying with behaviour change. For each finding, decide one of:

- **Tidying — apply inline.** Behaviour-preserving fixes (rename, extract, inline within a module, format) at severity Low or Nit. Apply directly in a separate tidying commit. Skip for findings that touch behaviour.
- **Behavioural fix — hand off to `/tt:impl`.** Anything that changes what the code does (Blockers, Highs that fix bugs, behavioural Mediums). Capture the finding as a follow-up task; do not change behaviour from a review session.
- **Structural fix — hand off to `/tt:refactor`.** Cross-module moves, boundary redraws, dependency-direction changes. Refactor pins behaviour via characterisation tests before applying.
- **Documentation fix — apply inline (it's text).** Wrong reference, dead link, broken example, mode-confused doc — fix in a docs-only commit.
- **Defer with rationale.** Low / Nit findings batched into a follow-up. Note in the summary so they don't get lost.

Severity ordering for triage: Blocker → High → Medium → Low → Nit. Conflict-resolution order between lenses (when findings overlap): scope → architecture → security → reliability → performance → quality → testing → ux → docs → aesthetics. Removing something supersedes restructuring it; restructuring supersedes polishing it.

## 4. Run Automated Checks
Skip if subject is an implementation plan.

Run pre-commit hooks (if configured), linters, and the project's tests. Fix all failures before continuing.

## 5. Summary
- Issues fixed in this pass.
- Issues deferred with rationale.
- Remaining concerns and follow-ups.

## 6. Handoff
When review is complete, suggest the next step based on the disposition from §3:

- **Findings against an implementation plan** → suggest `/tt:edge-cases` against the same plan to surface risks before execution.
- **Behavioural fixes are needed** → suggest `/tt:impl` (or `/tt:debug` if findings are diagnoses of an existing failure).
- **Structural moves are needed** → suggest `/tt:refactor`.
- **Only tidyings applied + low/nits deferred** → suggest `/tt:act:commit` for the tidying commit, with the deferred list captured for a later pass.
- **Nothing actionable** → close the loop; suggest `/tt:act:commit` for the original work if not yet committed.
