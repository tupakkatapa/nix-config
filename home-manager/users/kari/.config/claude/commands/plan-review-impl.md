
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

You are running an end-to-end **plan → review → implement** cycle, chaining three sub-agendas in one continuous pass. No user gates between phases — each phase's artefact flows directly into the next.

This is the **green-field complement** to `/tt:review-plan-impl`. Where that workflow audits *existing code* before planning changes to it, this one drafts a plan for *new* work, audits the **plan itself** before any code exists, then builds. The premise: a flawed plan is far cheaper to fix than flawed code. You review the design, not the diff.

Distinct from:
- `/tt:review-plan-impl` — review existing code → plan → implement. For hardening an artefact that already exists.
- `/tt:plan` alone — produces an approved plan; no built-in audit-the-plan or execution phase.
- `/tt:impl` alone — executes an existing plan; presupposes the plan is sound.
- `/tt:research` — when the subject matter is unfamiliar enough that you cannot plan yet.

**When to use:**
- New feature or capability with no existing code to review.
- Design-sensitive work where committing to the wrong approach is expensive (data model, public API, migration shape).
- Architectural green-field where you want the plan adversarially vetted before sinking implementation effort.
- Any work where "measure twice, cut once" pays — catch the design flaw at the plan stage.

**When NOT to use:** Existing code that needs hardening (use `/tt:review-plan-impl`), small diffs (use `/tt:review`), pure bugfixes (use `/tt:debug`), or unfamiliar territory where you can't plan yet (use `/tt:research` first).

## Discipline (non-negotiable)

1. **Three phases, three artefacts.** The cycle produces (a) an approved plan, (b) review findings on that plan, (c) implementation evidence. Each phase must terminate before the next begins.
2. **Auto-advance between phases.** No user checkpoints in the middle. The orchestrator carries plan → findings → revised plan → implementation in a single continuous pass.
3. **Phase contracts pass forward.** Phase 2 reviews the Phase 1 plan verbatim; Phase 3 implements the revised plan verbatim. Re-planning from scratch inside the review phase is a discipline violation — the review *amends* the plan, it does not replace it.
4. **Review targets the design, not code.** Phase 2 has no diff to inspect. The lens panel is applied to the plan: are the success criteria testable, the boundaries right, the failure modes considered, the scope free of gold-plating? Findings are about the *plan's soundness*, framed in planning mode.
5. **Re-entry is allowed.** If review invalidates the approach, route back to `/tt:plan` (re-plan) or `/tt:research` (the plan rests on an unknown). The cycle is a loop, not a one-shot pipeline.
6. **Self-halt on hard blockers.** Auto-advance does not mean ignore severity. If Phase 2 finds the plan's core approach unsound (wrong abstraction, missing prerequisite, success criteria unachievable as scoped), the orchestrator stops and reports — it does not implement a plan it just refuted.
7. **No commit until impl is done and verified.** The cycle ends with verification, not commit. Commit is `/tt:act:commit` after handoff.

## 1. Clarify Scope

Determine the work to be planned (via `AskUserQuestion` if unclear):
- [ ] A new feature or capability (which?)
- [ ] A new module / service / package
- [ ] A migration or breaking change (source/target, callers affected)
- [ ] An architectural change without a specific feature (what problem motivates it)

Capture success criteria, constraints, non-goals, deadlines. Pass the scope verbatim into Phase 1.

## 2. Phase 1 — Plan

Invoke `/tt:plan` against the chosen scope. Follow its discipline exactly: investigate the codebase, consult language context (`/tt:mod:*`), produce success criteria, constraints, non-goals, milestones, risk register.

**Artefact produced**: a plan file at `docs/plans/YYYY-MM-DD-<short-kebab-title>.md` (or per project convention).

**Self-halt condition**: if planning reveals a required input is missing (unknown library, undocumented external service, missing creds) → stop and route to `/tt:research`. Otherwise proceed directly to Phase 2.

## 3. Phase 2 — Review the Plan

Invoke `/tt:review` (escalate to `/tt:review-strict` for design-sensitive or large-scope work) with the **plan file as the artefact** and mode framed as planning. The lens panel inspects the *design*, not a diff:

- **`scope`** — is the plan gold-plated? Premature abstraction, speculative configurability, milestones that aren't needed for the success criteria?
- **`architecture`** — are the proposed boundaries, dependency directions, and data flow right *before* they're cast in code?
- **`security`** — does the design cross trust boundaries it doesn't account for? Secrets, authz, input validation planned in?
- **`reliability`** — failure modes, idempotency, observability, recovery considered in the plan?
- **`testing`** — are the success criteria actually testable? Does the plan name how each milestone is verified?
- remaining lenses (`ux`, `performance`, `quality`, `docs`, `aesthetics`) as they have surface on the design.

**Artefact produced**: structured findings on the plan, severity-ordered Blocker → High → Medium → Low → Nit.

**Auto-disposition rules** (no user prompt):
- **Blockers / Highs** → amend the plan in place to resolve them, *unless* the finding invalidates the core approach (wrong abstraction, unachievable success criteria, missing prerequisite) → **stop the cycle** and report; route to re-plan or `/tt:research`.
- **Mediums** → fold into the plan where they touch planned milestones; otherwise capture as a "deferred follow-up" note in the plan.
- **Lows / Nits** → capture as a "deferred follow-up" note in the plan. Do not block.

The amended plan is *self-approved* — the orchestrator carries it forward without a user prompt. Proceed directly to Phase 3.

## 4. Phase 3 — Implement

Invoke `/tt:impl` against the revised plan. Follow its discipline exactly: locate the plan, consult language context, execute step-by-step with verification per step.

**Artefact produced**: the working tree changed to satisfy the plan, plus evidence of verification (test output, `nix flake check`, `nix fmt`, linter clean, manual smoke-test notes).

During implementation:
- **Plan deviation discovered** (a step is wrong, a precondition was missed, the world changed since planning) → pause, surface the deviation, route back to Phase 1 to update the plan (and re-run Phase 2 on the changed sections if the design shifted). Do not silently improvise.
- **New design flaw surfaces** that Phase 2 missed → if minor, fold a one-line plan amendment and continue; if it changes the approach, pause and route back to Phase 2.
- **All planned steps complete** → run final verification, then continue to handoff.

## 5. Final Verification

Before declaring the cycle complete:
- All `/tt:impl` per-step verifications passed.
- `nix flake check` / project-equivalent runs clean.
- `nix fmt` / project formatter is clean.
- Each plan success criterion is demonstrably met in the working tree — verify by the means the plan named.
- Phase 2 findings folded into the plan are demonstrably addressed; deferred findings are captured in a follow-up note or issue so they don't vanish.

If verification fails, the cycle is not done. Either fix in place (small) or re-plan (large).

## 6. Handoff

Surface the cycle's three artefacts to the user:
- **Plan** (Phase 1 output, as amended by Phase 2).
- **Plan-review findings** (Phase 2 output, with final disposition).
- **Implementation evidence** (Phase 3 output: diff summary, verification log).

Recommend the next step:
- **All clean, no deferrals** → `/tt:act:commit` (likely multiple semantic commits per the work's natural seams).
- **Behaviour-only deferrals remain** → list them with severity; user decides now or later.
- **Structural deferrals remain** → suggest a separate `/tt:refactor` cycle.

The cycle ends here. Commit, push, PR — all explicit user-initiated steps.
