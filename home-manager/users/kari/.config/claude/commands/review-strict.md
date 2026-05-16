
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

You are conducting a **strict, comprehensive** code review across the full `/tt:lens:*` panel via mandatory subagent dispatch. This agenda is the heavyweight counterpart to `/tt:review` — slower, more expensive in tokens, with no shortcuts.

**When to use:**
- Pre-release reviews (any version bump that ships to consumers).
- Security-sensitive code (auth, secrets, data handling, anything crossing a trust boundary).
- Architectural changes (new module boundaries, dependency-direction shifts, service splits/merges).
- Third-party-facing surfaces (public APIs, library releases, CLI tools that others script against).
- Any artefact where "fast and selective" is unacceptable.

**When NOT to use:** Daily commits, small diffs, work-in-progress reviews. Use `/tt:review` for those.

## Discipline (non-negotiable)

1. **Every lens runs.** No skipping. A lens with no findings reports "no findings: <one-line reason>" — that statement is itself a deliverable, proving the dimension was inspected.
2. **Subagent dispatch is mandatory.** Each lens runs in its own subagent with isolated context, reading its own lens file in full (not lazily — strict mode loads the principles and dimensions). The orchestrator (you) only sees consolidated findings.
3. **Output Schema is mandatory per finding.** No prose summaries. Each finding has all schema fields populated.
4. **Citations are mandatory.** Every finding cites the lens principle or symptom it derives from (e.g. "violates `architecture` principle 5: Pull complexity downwards" or "matches `security` symptom: errors leak stack traces to unauthenticated callers"). Anchors the judgment in canon.
5. **Block-on-Blocker / High.** Review cannot close while any Blocker or High remains unresolved or explicitly acknowledged with rationale.
6. **Two-hats disposition is mandatory.** Each finding tagged with its next-step owner.

## 1. Clarify Scope
Determine the review subject. If unclear, ask the user (via `AskUserQuestion`) to choose:
- [ ] Current uncommitted diff
- [ ] Recent unpushed commits
- [ ] A specific fix/feature (ask which)
- [ ] Full codebase audit (a specific module or package)
- [ ] An implementation plan
- [ ] A specific release candidate

Pass the chosen scope verbatim to every lens subagent below, along with `mode = review` and the strict-mode contract from §Discipline.

## 2. Dispatch the Lens Panel

Each subagent prompt includes:
- The artefact under review (paths, diff, plan file — whatever scope was chosen).
- The full text of the corresponding `commands/lens/<name>.md` file.
- This contract: "Read your lens file in full. Apply every dimension. Report findings using the Output Schema verbatim. Cite the principle/symptom each finding derives from. If your lens has no surface in this artefact, return one explicit 'no findings: <one-line reason>' statement — the *reason* must reference what you inspected to reach that conclusion."

### Stage 1 — Sequential (each filters the next)

These two run first, in order. The second receives the first's findings to avoid re-inspecting code that scope already culled.

1. **`/tt:lens:scope`** — essential vs accidental complexity; cull gold-plating, premature abstraction, dead code, speculative configurability before deeper inspection.
2. **`/tt:lens:architecture`** — module boundaries, dependency direction, data flow, layering, distributed shape.

### Stage 2 — Parallel (independent dimensions)

Dispatch all six in a single message via the Task tool — independent facets, no inter-blocking. Each subagent receives the artefact as shaped by Stage 1's findings:

- **`/tt:lens:ux`** — surfaces (GUI / TUI / CLI / API / library / config schema).
- **`/tt:lens:security`** — threat model, authn/authz, secrets, crypto, trust boundaries.
- **`/tt:lens:performance`** — algorithmic complexity, IO patterns, contention, tail latency; with measurements where claims are made.
- **`/tt:lens:reliability`** — failure modes, SLIs/SLOs, observability, deployability, recoverability.
- **`/tt:lens:quality`** — duplication, naming, idiom, separation of concerns inside module boundaries.
- **`/tt:lens:testing`** — coverage of critical paths, edge cases, testability, suite health.

### Stage 3 — Final pass (form, after everything else has stabilised)

- **`/tt:lens:docs`** — README, tutorials, how-tos, reference, changelog, runbooks, ADRs (Diátaxis-aware).
- **`/tt:lens:aesthetics`** — formatting, naming consistency, comment discipline, ordering. **Runs last.**

## 3. Consolidate

Merge specialist reports into a single findings list. For each finding, the consolidated record includes:

- **Lens** — which specialist raised it.
- **Severity** — Blocker / High / Medium / Low / Nit.
- **Description** — the issue, including `file:line` or design reference.
- **Evidence** — concrete: quote, measurement, repro command, dependency arrow, vocabulary mismatch. "Feels wrong" is not evidence.
- **Citation** — the lens principle or symptom the finding derives from, named.
- **Recommended fix** — concrete action.
- **Confidence** — High / Medium / Low.
- **Disposition** — tidying (inline) / behavioural (`/tt:implement` or `/tt:debug`) / structural (`/tt:refactor`) / docs (inline) / deferred-with-rationale.

Resolve conflicting findings by the conflict-resolution order: scope → architecture → security → reliability → performance → quality → testing → ux → docs → aesthetics. Removing something supersedes restructuring it; restructuring supersedes polishing it.

## 4. Block-on-Blocker / High Gate

Before proceeding past this step:
- Every **Blocker** must be either (a) fixed inline (if a tidying), or (b) handed off to a slash command with the handoff captured in the summary, or (c) explicitly acknowledged with rationale (user-confirmed).
- Every **High** must reach one of the same three states.

A strict review does not close while a Blocker or High is in limbo.

## 5. Apply Inline Disposition

Apply findings whose disposition is "tidying" or "docs" inline now — these are form-only, behaviour-preserving, do not invite scope creep. One tidying commit per coherent group (per Beck's two-hats rule). Surface behavioural / structural findings as handoffs; do not change behaviour from a review session.

## 6. Run Automated Checks
Skip only if subject is an implementation plan.

Run pre-commit hooks (if configured), linters, and the project's tests. Fix all failures before continuing.

## 7. Summary

Produce a structured summary:

- **Counts** — by specialist and severity (e.g. "scope: 1 High / 2 Medium; security: 0; reliability: 1 Blocker addressed").
- **Findings fixed** — list, with the commit (or pending commit) that addressed each.
- **Findings handed off** — list, with the slash command that owns each.
- **Findings deferred** — list, with rationale and the follow-up where they're tracked.
- **Block-on-Blocker gate** — confirmed clean, or list the acknowledged-with-rationale Blockers.
- **Confidence statement** — "Reviewed by N lens specialists. No Blockers remain. M Highs handed off to /tt:Y. K Lows/Nits deferred."

## 8. Handoff

Suggest the next slash command per dominant disposition:
- Behavioural fixes pending → `/tt:implement` (or `/tt:debug` if findings are diagnoses).
- Structural moves pending → `/tt:refactor`.
- Otherwise → `/tt:actions:commit` for the tidying / docs commit applied in §5.
