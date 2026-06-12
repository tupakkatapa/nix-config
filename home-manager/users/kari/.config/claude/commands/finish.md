
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

You are running the **final pre-merge sign-off**. The branch is "done" — prove it is complete and safe, then promise it or refuse. This *wraps* `/tt:review`: review is the defect pass inside this gate, and this agenda adds what review does not — documentation completeness, test sufficiency, a breaking-change/regression analysis, and an evidence-backed promise. If a `verification-before-completion` skill is available, invoke it — evidence before assertion is the spine of this agenda.

**When to use:** the last step before merging a branch / PR.

**When NOT to use:** mid-development (use `/tt:review`), or a single dimension (use `/tt:docs` / `/tt:review` directly).

**Do NOT run the full test suite — CI owns that.** This agenda runs only the changed/new tests and reasons about the rest. It does not gate on a green full suite; it gates on the work being documented, proven, and non-breaking.

## Discipline (non-negotiable)
1. **Every gate runs, in order.** A later pass never excuses an earlier failure.
2. **Evidence before assertion.** Every "pass" carries the artefact/output that proves it. No claim without evidence.
3. **Block beats optimism.** Any gate failure → **refuse the promise**. Never say "merge-ready" on partial evidence.
4. **Orchestrate, don't reimplement.** Delegate to `/tt:docs`, `/tt:act:changelog`, `/tt:review`, and the project's tests.
5. **No full suite, no merge/commit/push.** CI runs the suite; the human merges. This agenda only signs off.

## 1. Scope
Determine what merges (via `AskUserQuestion` if unclear): current branch vs its base (default), or uncommitted diff. Derive (a) the change diff and (b) the base ref for breaking-change comparison.

## 2. Gate — Docs current
Apply `/tt:docs` discipline to the diff. Every changed public surface is reflected in the docs the project keeps — reference docs, public contracts (API endpoints/fields, CLI flags, config/module options), how-tos, tutorials.
- If the project keeps a **changelog**, run `/tt:act:changelog` to bring it current. If there is no changelog, skip silently.
- **Block** if any touched surface is undocumented, or a doc contradicts the code.
- **Evidence:** each touched surface → its doc location (or "internal, n/a"); changelog updated or "no changelog".

## 3. Gate — Tests prove it
For every behavioural change, a test exists that exercises it and **would fail if the change were reverted** — positive, negative, and edge cases. Run **only the new/changed tests** (targeted); CI runs the full suite.
- **Block** if new/changed behaviour lacks such a test, or a targeted test fails.
- **Evidence:** test names mapped to the behaviours they pin + the targeted run output (or, if the tests can't be run in isolation cheaply, an inspection argument that they hold).

## 4. Gate — No breaking changes, no regressions
Analyse, do not run the suite. Diff public surfaces against base — endpoints, request/response fields, CLI flags, config/module options, exported functions — and reason about existing callers.
- **Block** on any removal/rename/semantic shift in a public surface that is not explicitly acknowledged with migration notes, or any plausible regression the change introduces.
- **Evidence:** the public-surface diff verdict (breaking / non-breaking, with the compared symbols) + the regression reasoning.

## 5. Gate — Review
Invoke `/tt:review` against the diff (escalate to `/tt:review-strict` for security, architecture, or third-party-facing surfaces).
- **Block** on any unresolved Blocker or High.
- **Evidence:** the review's disposition summary.

## 6. The Promise
**Only if every gate passed**, emit the sign-off:
- An enumerated evidence block: docs updated (where) · changelog updated / n/a · tests added (which, proving what) · targeted tests green · public surfaces unchanged or breakage acknowledged · review clean.
- Then the explicit line: **"Promise: no breaking changes, no regressions — merge-ready."**

If **any** gate failed: emit **no promise**. Report each blocking gate and exactly what must change. Re-run after fixing — never override a block.

## 7. Handoff
- **Promise emitted** → suggest `/tt:summary` for a reviewer/client brief, then `/tt:act:commit` (if uncommitted) → merge / `/tt:act:pr`.
- **Blocked** → suggest the agenda that fixes it: `/tt:docs` (docs), `/tt:impl` (tests / behaviour), `/tt:refactor` (structural), re-`/tt:review`. Then re-run `/tt:finish`.
