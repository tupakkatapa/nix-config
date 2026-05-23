
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

You are diagnosing a failure: a failing test, a reported bug, an incident, or unexpected behaviour. This is **root-cause discovery**, distinct from `/tt:edge-cases` (hypothetical risk) and `/tt:review` (defect-finding pass). The substantive judgement comes from the `/tt:pov:*` panel applied in **diagnosis** mode — "what assumption broke, and where?" If a `systematic-debugging` skill is available, invoke it for the procedure.

## 1. Reproduce
A bug you cannot reliably trigger is a bug you cannot fix. Before anything else:
- Capture the exact symptom: error message, stack trace, observed vs expected output, environment.
- Build a minimal reliable repro: smallest input, fewest steps, deterministic outcome.
- If the symptom is flaky, treat the flake itself as the bug — a non-deterministic test masks real failures.

If reproduction is impossible (production-only, intermittent, environmental), capture the strongest evidence available (logs, traces, dumps) and proceed — but flag that fix verification will be probabilistic.

## 2. Characterise
- Read the failing code and its callers. Trace the data flow that produced the symptom.
- Identify what changed: recent commits, config, dependencies, data shape, traffic pattern.
- Bisect when the suspect range is large (`git bisect`, feature flag, dependency version).
- Distinguish: incorrect output, missing output, wrong timing, resource exhaustion, crash, silent corruption. Each implies different root-cause classes.

## 3. Apply the Lens Panel (mode = diagnosis)

Read each relevant lens file lazily — only the section you need (Symptoms / Dimensions), only the lenses with a diagnostic surface for this symptom. Reframe its dimensions as "which assumption here is the one that broke?".

Typically relevant for diagnosis:

- **`/tt:pov:reliability`** — failure modes that match the symptom: partial failure, retry semantics, observability gaps that hid the root cause earlier, state left after error paths.
- **`/tt:pov:testing`** — which test *should* have caught this and didn't? Implicit assumptions about non-null fields, "impossible" states, or relationship invariants that turned out to be false.
- **`/tt:pov:scope`** — accidental complexity hiding the bug. State space too large to reason about, dead branches still reachable, premature abstractions obscuring control flow.
- **`/tt:pov:arch`** — boundary violations: function reaching past its layer, hidden coupling, dependency direction wrong, invariant that should live at a boundary leaking inside.
- **`/tt:pov:perf`** — only when the symptom is latency, throughput, resource exhaustion, or a concurrency race. Apply USE method, identify saturation, measure before guessing.
- **`/tt:pov:sec`** — only when the symptom involves trust boundary crossing (auth bypass, injection, privilege escalation, data leak).

## 4. Hypothesise
State the root cause as a falsifiable claim:
- "The bug is X because of Y; if I change Z, the symptom should disappear."
- Predict what evidence would *disprove* the hypothesis — not only what would confirm it.
- Rank competing hypotheses by likelihood and cost-to-test.

A symptom can have multiple coincident causes. Don't stop at the first that fits; verify it explains *all* the evidence.

## 5. Verify
- Run the targeted experiment: minimal change at the suspected root, observe the prediction.
- If the prediction holds and competing hypotheses are now ruled out, the root is confirmed.
- If not, return to step 3 with the new evidence — don't escalate the fix to compensate for a wrong diagnosis.

## 6. Fix — commit ordering matters
Apply Beck's two-hats discipline rigorously. The order of commits in a debug session is:

1. **Structural prep (if needed)** — testability seams (Feathers), broken dependencies, characterisation tests. Each its own commit, behaviour-preserving. Apply via `/tt:refactor` discipline.
2. **Behavioural fix** — the minimal change at the root, not at the symptom. Its own commit.
3. **Regression test** — see §7. May ride with (2) if it lands in an existing harness; if a new harness/fixture/file is needed, that scaffolding goes in (1) instead.

Never bundle unrelated cleanup with the fix. Surface unrelated tidying as deferred items in the summary.

## 7. Regression Test
- Add a test that would have caught this bug. If the bug was untestable, fix the testability first as a structural commit (see step 6.1; refer to `/tt:pov:testing` for seam techniques).
- Verify the test fails against the unfixed code, then passes against the fix. If the test passes both before and after, the fix is at the wrong layer or the test asserts the wrong thing.
- If the bug was a missing assumption check, ask: are there sibling assumptions equally undefended? Add tests for those too.

## 8. Run Automated Checks
Run pre-commit hooks (if configured), linters, and the project's tests. Fix all failures before continuing.

## 9. Summary
- Root cause in one sentence.
- Evidence that confirmed it.
- The fix and why it is at the root, not the symptom.
- The regression test added.
- Sibling risks discovered along the way (defer to `/tt:edge-cases` or a follow-up commit if substantial).

## 10. Handoff
When the fix is verified, suggest running `/tt:review` to validate the patch, then `/tt:act:commit`.
