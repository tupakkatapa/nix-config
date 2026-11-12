---
description: "Fast single-agent defect review of the current diff, unpushed commits or a plan file, across the lens panel. Applies tidying and doc fixes; fixes behaviour only when asked to address findings."
argument-hint: "[diff | commits | plan file]"
---

You are conducting a code review across the lens dimensions inline (single agent, no subagent dispatch by default).

**Read lens files lazily.** Don't load the whole panel into main context upfront — each lens file is a reference. When you reach a lens in §2, read the section you need (Identity → Symptoms → Dimensions → Output Schema), apply, move on. Skip lenses with no surface in this artefact entirely.

**Escalate to subagent dispatch when:** (a) the diff is too large for one context, or (b) the artefact triggers most of the panel and reading every lens file inline would pollute the main context. In that case dispatch subagents in three stages: sequential `scope` → `arch`; parallel `compat`/`sec`/`reliability`/`perf`/`quality`/`testing`/`ux`/`ui`; final `docs` → `prose` → `style` (names = lens file names under `~/.claude/tt/pov/`). Each subagent reads only its own lens file; main context only sees the consolidated findings. Default to inline for small-to-medium diffs — cross-lens synthesis (scope cuts removing downstream concerns) is the value, and panel dispatch sacrifices it.

## 1. Clarify Scope
Default: the current uncommitted diff; if the tree is clean, the unpushed commits. Only if neither applies or intent is ambiguous, ask the user to choose:
- [ ] Current uncommitted diff
- [ ] Recent unpushed commits
- [ ] A specific fix/feature (ask which)
- [ ] An implementation plan

## 2. Apply the Lens Panel (mode = review)

Read each lens file (`~/.claude/tt/pov/<name>.md`) for the dimensions it owns, then apply them in this order. Each lens filters what the next inspects.

1. **`scope`** — cull gold-plating, premature abstraction, dead code, speculative configurability first.
2. **`arch`** — module boundaries, dependency direction, data flow, layering.
3. **`compat`** — only if a public surface or stored data changes: endpoints, fields, flags, options, exported functions, wire and on-disk formats.
4. **`sec`** — trust boundaries, authn/authz, secrets, input validation. *(Skip only if no boundary is crossed.)*
5. **`reliability`** — failure modes, idempotency, observability, recoverability.
6. **`perf`** — only when a measurable concern exists; otherwise defer.
7. **`quality`** — duplication, naming, idiom, separation of concerns within module boundaries.
8. **`testing`** — coverage of critical paths, edge cases, testability.
9. **`ux`** — only if the change has a surface (CLI / API / config / GUI / TUI / library).
10. **`ui`** — only if the change has a graphical surface.
11. **`docs`** — README, tutorials, how-tos, reference, changelog, runbooks, ADRs.
12. **`prose`** — only if human-facing text changes: docs, changelog, messages shown to users.
13. **`style`** — formatting, naming consistency, comment discipline, ordering. *(Runs last; only one lens can be last.)*

For each finding, record:
- **Lens** — which dimension raised it.
- **Severity** — Blocker / High / Medium / Low / Nit.
- **Description** — the issue, with `file:line`.
- **Recommended fix** — concrete.
- **Confidence** — High / Medium / Low.

Resolve conflicting findings by preferring the more fundamental concern: scope → arch → compat → sec → reliability → perf → quality → testing → ux → ui → docs → prose → style.

## 3. Disposition

For each finding, decide one of:

- **Tidying — apply.** Behaviour-preserving fixes (rename, extract, inline within a module, format).
- **Documentation fix — apply.** Wrong reference, dead link, broken example, stale comment.
- **Behavioural fix — apply when findings are to be addressed** (the review runs inside `/tt:ship`, or the user asked to address them). Follow the repro-test rule: a test that fails for the stated reason first, then the fix. Otherwise report the finding and leave the code alone.
- **Structural fix — hand off to `/tt:refactor`.** Cross-module moves, boundary redraws, dependency-direction changes.
- **Defer with rationale.** Low / Nit findings not worth the change now. Name them in the summary.

Do not commit here; `/tt:act:commit` splits tidying from behavioural fixes (two hats). Severity ordering for triage: Blocker → High → Medium → Low → Nit. Removing something supersedes restructuring it; restructuring supersedes polishing it.

## 4. Run Checks
Skip if the subject is an implementation plan.

Run pre-commit hooks (if configured) and only the tests that cover the changed code. The full suite is CI's. Fix failures this session introduced; pre-existing failures are findings. Inside `/tt:ship` skip this step: the sign-off gate runs the tests once.

## 5. Summary
- Findings fixed in this pass.
- Findings reported but not fixed, by severity.
- Findings deferred, with rationale.

## 6. Next
- Findings against a plan → revise the plan file.
- Structural moves needed → `/tt:refactor`.
- Otherwise → `/tt:finish`, or `/tt:act:commit` when no sign-off is wanted.
