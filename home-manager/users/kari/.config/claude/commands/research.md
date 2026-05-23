
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

You are conducting **research**: building durable knowledge about an unfamiliar subject before any work commits to a direction. Research ends with a written brief, not a plan, fix, or refactor — discovery, not commitment. The substantive judgement comes from the `/tt:pov:*` panel applied in **research** mode — "what do I need to understand here, where are the gaps, what would a future implementer wish I had captured?"

Distinct from:
- `/tt:plan` — research ends with a brief; planning ends with an approved approach. A plan presupposes that the relevant facts are already known.
- `/tt:act:explain` — produces an in-conversation explanation. This agenda produces a durable file other agendas can consume.
- `/tt:debug` — diagnoses an existing failure. Research has no failure to bind to; it scopes the unknown.
- `/tt:docs` — writes user-facing docs from established knowledge. Research is investigator's notes; if those notes deserve to outlive the investigator they get promoted via `/tt:docs` (explanation mode).

## 1. Detect Target Type

Read the user's brief and classify the research target. The target type drives investigation tooling; the lens panel is shared.

- **Local codebase** — a path that resolves on disk (this repo, another local checkout, a subdirectory). Investigation via Read / Grep / Explore subagent and `git log` / `git blame`.
- **Remote git repository** — a forge URL (`https://github.com/...`) or `owner/repo` shorthand. Investigation via `gh repo view`, `gh api`, optional shallow clone into `/tmp/research/<slug>`.
- **Topic / library / concept** — no concrete artefact: a question, a library name, a protocol, a comparative survey. Investigation via `context7` (library docs), `nixos` MCP (packages/options), `searxng` (general web / `web_url_read` for full pages), authoritative specs.

Heuristics for auto-detection (prefer over asking):
- Path exists locally → codebase.
- Matches a forge URL or `<owner>/<repo>` and resolves remotely → remote git.
- Otherwise → topic.

If a single brief spans multiple target types (e.g. "compare our impl against upstream"), treat each leg in turn during step 3 and merge findings in step 6.

## 2. Frame the Question

A research session without a question wanders. Capture explicitly:

- **Question(s)** — one to three precise questions this brief must answer. "Tell me about X" is not a research question; "would X meet our isolation requirements and what does the migration cost?" is.
- **Decision(s) it informs** — the downstream agenda this feeds (`/tt:plan`, `/tt:debug`, `/tt:refactor`, …). Research detached from a decision is `/tt:act:explain`, not this agenda.
- **Out-of-scope** — adjacent questions deferred so the brief doesn't sprawl.
- **Stop condition** — the level of confidence that ends the session. Research expands forever otherwise.

## 3. Investigate by Target Type

Cite as you go — URL, `file:line`, commit SHA. A brief without citations is a hallucination risk.

**Local codebase.**
- Map directory shape (`tree`, `ls -R`) before opening files. Shape constrains everything that follows.
- Dispatch an `Explore` subagent for broad mapping; reserve the main context for synthesis.
- Trace entry points and data flow; note conventions, key abstractions, integration seams.
- Read commit history (`git log`, `git blame`) where the *why* behind a decision matters more than the *what*.

**Remote git.**
- `gh repo view <owner>/<repo>` — README, languages, recent activity, release cadence.
- `gh api repos/<owner>/<repo>/...` for specifics (releases, open issues, recent PRs, contributor count).
- For a deep read, shallow-clone into `/tmp/research/<slug>` and treat the working copy as the codebase target. Never clone into the project tree.
- **Pin the commit SHA in the brief.** Remote state moves; the brief without a SHA decays into a guess.

**Topic / library / concept.**
- Library / framework / SDK / CLI docs → `context7` MCP. Prefer it over web search for any named library — training data drifts.
- NixOS packages / options → `nixos` MCP.
- General web / surveys → `searxng` MCP. Read full pages via `web_url_read`; skimming snippets misses the load-bearing paragraph.
- Specs / standards → fetch the authoritative source (RFC, W3C, vendor docs). Note version/date — protocols evolve.
- Compare multiple sources; record disagreements rather than silently collapse them. The disagreement is often the load-bearing finding.

## 4. Consult Language Context

If the research feeds work in a known language, pull the matching context file so the brief surfaces relevant idiomatic constraints up front (linters, packaging idiom, house-style expectations a future implementer must honour):

- Nix → `/tt:mod:nix`.
- Rust → `/tt:mod:rs`.
- JavaScript / TypeScript → `/tt:mod:js`.
- Shell → `/tt:mod:sh`.

Skip for pure topic research with no downstream codebase. The per-project `./CLAUDE.md` overrides anything in a context file.

## 5. Apply the Lens Panel (mode = research)

Frame each relevant lens's dimensions as **questions the brief must answer**, not defects. **Read lens files lazily** — pull only the Dimensions section per lens you actually need; skip lenses with no research surface. For broad surveys spanning many lenses, dispatch lens specialists as subagents (each gets isolated context; main context only sees consolidated findings).

Typically relevant:

- **`/tt:pov:scope`** — what is essential to the question vs interesting-but-tangential. A brief's value is in what it leaves out as much as in what it includes.
- **`/tt:pov:arch`** — for codebase/repo: shape, module boundaries, the design decision each module hides. For topic: design space, alternatives, where the subject sits in the wider stack.
- **`/tt:pov:sec`** — trust model, threat surface, known CVEs (for libraries), authn/authz primitives offered, secrets handling expectations.
- **`/tt:pov:reliability`** — documented (and undocumented) failure modes, project maturity signal: release cadence, issue burndown, last-commit recency, bus factor.
- **`/tt:pov:perf`** — only when the question has a measurable performance angle; otherwise defer.
- **`/tt:pov:testing`** — test posture: how the project verifies itself, what would need pinning down before changes.
- **`/tt:pov:ux`** — for libraries/services: the API / CLI / config / TUI surface a future caller would touch, and how stable that surface is across versions.
- **`/tt:pov:docs`** — which Diátaxis quadrants the project covers (tutorials / how-tos / reference / explanation). Gaps signal where downstream work will struggle.

## 6. Write the Brief

Always produce a markdown file. Default path: `docs/research/YYYY-MM-DD-<short-kebab-slug>.md` (today's date; create the directory if it does not exist). Follow project convention if one exists — the per-project `./CLAUDE.md` is the source of truth.

Structure:

- **Subject & target type** — codebase / remote / topic. Pin: absolute path, `owner/repo@<sha>`, or a one-line topic statement.
- **Questions** — what this brief set out to answer (from step 2).
- **Findings** — one subsection per question, with citations inline.
- **Map / inventory** — for codebase or repo: directory shape, key modules, entry points, data flow. For topic: design space surveyed, alternatives compared in a small table.
- **Lens notes** — short paragraph per relevant lens with the dimensional findings.
- **Open questions** — gaps, unknowns, contradictions in sources. Honesty here saves the next investigator a day.
- **Recommended next step** — which agenda this hands off to and why.
- **Sources** — full list of URLs / `file:line` / commit SHAs. Anything cited inline appears here.

Write for a reader who has not done the research. They should be able to act on the brief without re-reading the sources.

## 7. Handoff

Present the brief inline (path + one-paragraph summary). Do not call `EnterPlanMode`.

Branch by what the questions were aimed at:

- **Brief informs a build** → `/tt:plan` with the brief as input artefact.
- **Brief informs a fix** → `/tt:debug` — the brief frames the diagnostic search space.
- **Brief informs a structural move** → `/tt:refactor`.
- **Brief is itself the deliverable** (literature review, comparative survey, ADR feed) → `/tt:docs` in explanation mode, to promote investigator notes into durable user-facing documentation.
- **Brief surfaces risks worth flagging** → `/tt:edge-cases` against the relevant artefact before commitment.
- **Nothing actionable yet** — file the brief and stop. No further agenda required.

If research reveals that the original question was the wrong question (a common outcome — the cheapest research result is "you were asking about X but the real question is Y"), update the brief with a short note and rerun this agenda against the refined question.
