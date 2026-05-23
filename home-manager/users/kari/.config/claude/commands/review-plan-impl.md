
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

You are running an end-to-end **review → plan → implement** cycle on an artefact, chaining three sub-agendas in one continuous pass. No user gates between phases — each phase's artefact flows directly into the next.

This is the heavyweight workflow. Use it when the work is non-trivial, blast radius is real, and you want findings from a strict review to *shape* the plan rather than be retrofitted afterward.

Distinct from:
- `/tt:review-strict` alone — produces findings only, never touches code.
- `/tt:plan` alone — produces an approved plan; presupposes the relevant audit has happened.
- `/tt:impl` alone — executes against an existing plan; presupposes the plan is sound.

**When to use:**
- Pre-release hardening of a feature branch.
- Security-sensitive code path that ships next and where findings will likely require rework.
- Architectural changes where review-driven re-scoping is expected.
- Any artefact where you want one continuous session with explicit checkpoints rather than three disjoint sessions.

**When NOT to use:** Small diffs (use `/tt:review`), green-field work with no artefact to review yet (use `/tt:plan` then `/tt:impl`), or pure bugfixes (use `/tt:debug`).

## Discipline (non-negotiable)

1. **Three phases, three artefacts.** The cycle produces (a) review findings, (b) an approved plan, (c) implementation evidence. Each phase must terminate before the next begins.
2. **Auto-advance between phases.** No user checkpoints in the middle. The orchestrator carries findings → plan → implementation in a single continuous pass.
3. **Phase contracts pass forward.** Each phase consumes the previous phase's artefact verbatim. The review findings drive plan scope; the plan drives implementation order. Re-deriving findings inside the plan phase is a discipline violation.
4. **Re-entry is allowed.** If implementation surfaces a defect or scope change, route back to `/tt:plan` (re-plan) or `/tt:review-strict` (re-audit). The cycle is a loop, not a one-shot pipeline.
5. **Self-halt on hard blockers.** Auto-advance does not mean ignore severity. If Phase 1 surfaces Blockers that *change the work itself* (e.g. wrong target, ambient bug must be fixed first, design assumption invalidated), the orchestrator stops and reports — it does not paper over the finding by planning around it.
6. **No commit until impl is done and verified.** The cycle ends with verification, not commit. Commit is `/tt:act:commit` after handoff.

## 1. Clarify Scope

Determine the artefact under review (via `AskUserQuestion` if unclear):
- [ ] Current uncommitted diff
- [ ] Recent unpushed commits
- [ ] A specific feature branch or module
- [ ] A specific release candidate
- [ ] An existing implementation plan being audited before execution

Pass the scope verbatim into Phase 1.

## 2. Phase 1 — Strict Review

Invoke `/tt:review-strict` against the chosen scope. Follow its discipline exactly: full lens panel via subagent dispatch, Output Schema per finding, block-on-Blocker/High.

**Artefact produced**: a structured findings report. Severity-ordered Blocker → High → Medium → Low → Nit, each with disposition (tidy / behavioural / structural / docs / defer).

**Auto-disposition rules** (no user prompt):
- **Blockers** → fold into the plan as mandatory steps. Unless the Blocker invalidates the work (wrong target, ambient bug requires `/tt:debug` first), in which case **stop the cycle** and report.
- **Highs** → fold into the plan as mandatory steps.
- **Mediums** → fold into the plan as in-scope where they touch files the plan will modify; otherwise capture as a "deferred follow-up" note in the plan.
- **Lows / Nits** → capture as a "deferred follow-up" note in the plan. Do not block.

Proceed directly to Phase 2.

## 3. Phase 2 — Plan

Invoke `/tt:plan` with two inputs:
1. The original artefact / scope.
2. The Phase 1 findings (post-disposition).

The plan must:
- Explicitly map each Phase 1 Blocker / High to a planned change (or to a "deferred with rationale" note if the user chose to defer).
- Otherwise follow `/tt:plan` discipline verbatim: success criteria, constraints, non-goals, milestones, risk register.

**Artefact produced**: a plan file at `docs/plans/YYYY-MM-DD-<short-kebab-title>.md` (or per project convention). The plan is *self-approved* — the orchestrator carries it forward without a user prompt.

**Self-halt conditions** (rare; only when auto-advance would be reckless):
- The plan reveals that a required input is missing (unknown library, missing creds, undocumented external service) → stop and route to `/tt:research`.
- The plan exceeds reasonable single-cycle scope (many independent multi-day milestones) → stop, surface the plan, recommend splitting.
- Otherwise → proceed directly to Phase 3.

## 4. Phase 3 — Implement

Invoke `/tt:impl` against the approved plan. Follow its discipline exactly: locate the plan, consult language context, execute step-by-step with verification per step.

**Artefact produced**: the working tree changed to satisfy the plan, plus evidence of verification (test output, `nix flake check`, `nix fmt`, linter clean, manual smoke-test notes).

During implementation:

- **Plan deviation discovered** (a step is wrong, a precondition was missed, the world changed since planning) → pause the implementation, surface the deviation, and route back to Phase 2 to update the plan. Do not silently improvise.
- **New defect discovered** in already-touched code → if minor, fold it into the current plan with a one-line plan amendment and continue; if significant, pause and route to a fresh `/tt:debug` or `/tt:review` cycle.
- **All planned steps complete** → run final verification, then continue to handoff.

## 5. Final Verification

Before declaring the cycle complete:

- All `/tt:impl` per-step verifications passed.
- `nix flake check` / project-equivalent runs clean.
- `nix fmt` / project formatter is clean.
- The original Phase 1 findings (those folded into the plan) are demonstrably addressed in the working tree — spot-check each by re-running the inspection that surfaced it.
- Deferred findings are captured in a follow-up note or issue, so they don't vanish.

If verification fails, the cycle is not done. Either fix in place (small) or re-plan (large).

## 6. Handoff

Surface the cycle's three artefacts to the user:

- **Review findings** (Phase 1 output, with final disposition).
- **Plan** (Phase 2 output, with completion status per step).
- **Implementation evidence** (Phase 3 output: diff summary, verification log).

Recommend the next step:

- **All clean, no deferrals** → `/tt:act:commit` (likely multiple semantic commits per the disposition tags).
- **Behaviour-only deferrals remain** → list them with severity; user decides whether to address now or batch later.
- **Structural deferrals remain** → suggest a separate `/tt:refactor` cycle.
- **Findings that escaped the plan** (rare; should be caught at Checkpoint B) → flag explicitly; do not bury.

The cycle ends here. Commit, push, PR — all explicit user-initiated steps.
