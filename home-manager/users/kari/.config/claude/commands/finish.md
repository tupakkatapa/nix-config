---
description: "Sign-off gates only, for a branch that is done: docs current, tests prove it, no breaking changes or regressions, review clean. Promises or refuses; does not commit. /tt:ship runs it together with review and commit."
argument-hint: "[base ref]"
---

You are running the **final pre-merge sign-off**. The branch is "done" — prove it is complete and safe, then promise it or refuse. This *wraps* `/tt:review`: review is the defect pass inside this gate, and this agenda adds what review does not — documentation completeness, test sufficiency, a breaking-change/regression analysis, and an evidence-backed promise. If a `verification-before-completion` skill is available, invoke it — evidence before assertion is the spine of this agenda.

**When to use:** the last step before merging a branch / PR.

**When NOT to use:** mid-development (use `/tt:review`), or a single dimension (use `/tt:docs` / `/tt:review` directly).

**Do NOT run the full test suite — CI owns that.** This agenda runs only the changed/new tests and reasons about the rest. It does not gate on a green full suite; it gates on the work being documented, proven, and non-breaking.

## Discipline (non-negotiable)
1. **Every gate runs, in order.** A later pass never excuses an earlier failure.
2. **Evidence before assertion.** Every "pass" carries the artefact/output that proves it. No claim without evidence.
3. **Block beats optimism.** Any gate failure → **refuse the promise**. Never say "merge-ready" on partial evidence.
4. **Orchestrate, don't reimplement.** Delegate to `/tt:docs`, `/tt:act:changelog` and `/tt:review`.
5. **No full suite, no merge/commit/push.** CI runs the suite; the human merges. This agenda only signs off.

## 1. Scope
What merges: the current branch against its base, uncommitted changes included. Ask only if the base is genuinely underivable. Derive (a) the change diff and (b) the base ref for breaking-change comparison.

## 2. Gate — Docs current
Apply `/tt:docs` discipline to the diff. Every changed public surface is reflected in the docs the project keeps — reference docs, public contracts (API endpoints/fields, CLI flags, config/module options), how-tos, tutorials.
- **In-code comments and docstrings are doc territory too.** Every comment/docstring on or near changed lines must be current and true — no stale version numbers, dead file/line references, contradicted invariants, or descriptions that no longer match the code. Plans/ADRs the diff executes are current (status + any deviation noted).
- If the project keeps a **changelog**, run `/tt:act:changelog` to bring it current. If there is no changelog, skip silently.
- **Block** if any touched surface is undocumented, a doc/comment/docstring contradicts the code, or a changed/added doc buries its signal in bloat (global Principle "Durable artefacts are high-signal").
- **Evidence:** each touched surface → its doc location (or "internal, n/a"); comments/docstrings on the diff verified true; changelog updated or "no changelog".

## 3. Gate — Tests prove it
For every behavioural change, a test exists that exercises it and **would fail if the change were reverted** — positive, negative, and edge cases. Run **only the new/changed tests** (targeted); CI runs the full suite.
- **Block** if new/changed behaviour lacks such a test, or a targeted test fails.
- **Where the project has no test infrastructure for this kind of change** (declarative config, infrastructure code), the evidence is the strongest check the project does have: a build, an evaluation, a dry run, or a manual check with its output. Say which.
- **Evidence:** test names mapped to the behaviours they pin + the targeted run output (or, if the tests can't be run in isolation cheaply, an inspection argument that they hold).

## 4. Gate — No breaking changes, no regressions
Analyse, do not run the suite. Apply the `compat` lens (`~/.claude/tt/pov/compat.md`): diff public surfaces against base — endpoints, request/response fields, CLI flags, config/module options, exported functions — and reason about existing callers.
- **Block** on any removal/rename/semantic shift in a public surface that the user has not explicitly accepted, with migration notes written, or any plausible regression the change introduces.
- **Evidence:** the public-surface diff verdict (breaking / non-breaking, with the compared symbols) + the regression reasoning.

## 5. Gate — Review
**Skip this gate when `/tt:review` or `/tt:review-strict` already ran on this same diff in this session and nothing but its own fixes changed since; carry its disposition summary forward as the evidence.** Otherwise invoke `/tt:review` against the diff (escalate to `/tt:review-strict` for security, architecture, or third-party-facing surfaces), with its §4 checks scoped to the §3 targeted tests — the full suite stays CI's (Discipline #5).
- **Block** on any unresolved Blocker or High.
- **Evidence:** the review's disposition summary.

## 6. The Promise
**Only if every gate passed**, emit the sign-off:
- An enumerated evidence block: docs updated (where) · changelog updated / n/a · tests added (which, proving what) · targeted tests green · public surfaces unchanged or breakage acknowledged · review clean.
- Then the explicit line: **"Promise: no breaking changes, no regressions — merge-ready."**
- Then one line: confidence (low / medium / high) and the single assumption that would break the promise if false.

If **any** gate failed: emit **no promise**. Report each blocking gate and exactly what must change. Re-run after fixing — never override a block.

## 7. Next
- **Promise emitted** → `/tt:act:commit` (if uncommitted), then the user pushes and `/tt:monitor` opens the PR.
- **Blocked** → fix with the agenda that owns the gap (`/tt:docs`, `/tt:impl`, `/tt:refactor`), then re-run `/tt:finish`.
