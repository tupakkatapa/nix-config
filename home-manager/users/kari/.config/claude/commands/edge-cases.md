
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

You are probing the artefact for edge cases, implicit assumptions, and architectural gaps that normal review misses. The substantive lenses are the `/tt:pov:*` specialists applied in **risk-discovery** mode — "what could go wrong here that the happy path hides?" — rather than review or planning.

## 1. Clarify Scope
If the subject is unclear, ask the user to choose:
- [ ] Current uncommitted diff
- [ ] Recent unpushed commits
- [ ] A specific feature or component (ask which)
- [ ] A specific interaction between systems (ask which)

## 2. Study the Subject
- Read the code, trace dependencies, understand how it integrates with the rest of the system.
- Identify trust boundaries, state transitions, external calls, and concurrency points.

## 3. Apply the Lens Panel (mode = risk-discovery)

Read lens files lazily — only the Symptoms / Dimensions sections for lenses with risk surface in this artefact. Reframe their dimensions as risk prompts rather than defect-against-spec; bias toward "what assumption breaks?".

Typically relevant for edge-case work:

- **`/tt:pov:reliability`** — failure modes, partial failures, recoverability, observability gaps. State lifecycle: transitional states, post-failure residue, cascading effects (constraints, hooks, events). Data consistency: orphaning, broken cleanup, circular dependencies, batch atomicity. External system interactions: secondary call failures, idempotency under retry, internal-vs-external state divergence.
- **`/tt:pov:sec`** — authorisation boundaries: every role/privilege level, indirect access paths, consistency of checks across cleanup and error paths, least-privilege scope, policies evaluated against stale vs current state.
- **`/tt:pov:perf`** — concurrency and timing: simultaneous conflicting operations, check-then-act races, async arrivals (webhooks, queues, event handlers) after the entity is mutated/deleted, transaction scope (too broad or too narrow).
- **`/tt:pov:testing`** — implicit assumptions about non-null fields, required relationships, "impossible" states; schema/API evolution; error messages leaking internals; gaps where no test would catch a regression.
- **`/tt:pov:scope`** — undocumented assumptions about the data model or environment; complexity hiding edge cases by making the reachable state space too large to reason about.
- **`/tt:pov:arch`** — only when an edge case is a structural defect (cross-module invariant broken, dependency-direction inversion enabling the bug).

Skip lenses that have no risk surface for this artefact.

## 4. Findings
For each finding:
- **Lens** — which lens surfaced it.
- **Category** — the specific dimension within that lens.
- **Scenario** — concrete steps that trigger the edge case.
- **Current behaviour** — what happens today.
- **Impact** — severity and blast radius (data loss, security issue, silent corruption, cosmetic).
- **Assessment** — needs fixing / accepted limitation / needs discussion.
- **Fix sketch** — brief description of what a fix would involve and its trade-offs.

## 5. Trade-off Discussion
For findings where fixing one thing could introduce another, present:
- Options with pros and cons.
- Recommendation with rationale.
- Whether the gap belongs in the project's decisions/considerations log.

## 6. Summary
- Count of findings by impact.
- Items to fix before shipping.
- Acceptable limitations worth documenting.
- Items needing further investigation or discussion.

## 7. Handoff
Branch by where the findings hit:

- **Findings invalidate the plan's assumptions** → suggest `/tt:plan` to revise. Do not patch around in implementation; the plan was wrong, fix the plan.
- **Findings reveal bugs in already-shipped code** → suggest `/tt:debug` for each, in severity order.
- **Findings reveal missing behaviour** → suggest `/tt:impl` (with a plan revision first if the missing behaviour is non-trivial).
- **Findings reveal structural defects** → suggest `/tt:refactor`.
- **Findings are accepted limitations** → suggest documenting them via `/tt:docs` (explanation mode: ADR or design-note) so the trade-off is captured for future readers.
