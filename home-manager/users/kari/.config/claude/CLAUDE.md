# Claude Configuration

## Principles (hard rules)

- When unsure, choose the most fundamentally right action instead of asking.
- Fix all failing tests — they run continuously, so failures come from recent changes.
- All changes must pass `nix fmt` and existing tests.
- **No lint suppressions** (`# noqa`, `#[allow(...)]`, `// eslint-disable`, `// shellcheck disable`, `# type: ignore`, equivalents) unless unavoidable. Fix the root cause. An unavoidable suppression carries a comment on the line above naming the rule and the reason.
- **Plan Mode is user-initiated.** `defaultMode = "auto"` → autonomous execution is the default. Never call `EnterPlanMode` yourself. If the user already activated Plan Mode, surface the plan via `ExitPlanMode`; otherwise present plans inline with the file path.
- **Lazy-read reference files.** `/tt:pov:*` and `/tt:mod:*` are reference, not preludes. Read only the section you need (Identity / Symptoms / Dimensions / Output Schema). For multi-lens passes, dispatch lenses as subagents (isolated context, findings-only return) instead of reading 10 files into main context.

## NixOS Development

`~/Workspace/tupakkatapa/nix-config` (github.com/tupakkatapa/nix-config) is the source of truth.

- NEVER suggest `apt install`, `brew install`, `pip install`, or similar.
- Temporary package: `nix-shell -p <package>`, or `, <command>` (comma runs from nixpkgs).
- Permanent package: add to config → `direnv reload` → restart session.
- List a host's packages: `nix eval --json github:tupakkatapa/nix-config#nixosConfigurations.$HOSTNAME.config.environment.systemPackages --apply 'builtins.map (p: p.name)'`
- List hosts: `nix eval --json github:tupakkatapa/nix-config#nixosConfigurations --apply builtins.attrNames`

## Tools & Dispatch

Capability → tool. Reach for these before improvising:

| Need | Use |
|---|---|
| Library/framework docs | context7 MCP |
| NixOS packages/options | nixos MCP |
| Web search | searxng MCP |
| Deep codebase search | Explore subagent (read-only, fast) |
| 3+ independent tasks | parallel Task subagents (one message) |
| Iterative refinement | Ralph Loop (user-initiated) |

Subagent rules — subagents can't ask questions, so give full context upfront:
- Dispatch 3+ independent tasks as parallel subagents in a single message.
- Background work → `Task(..., run_in_background=true)`.
- Fan-out scale: simple 1–2, medium 3–4, complex 5–6.
- Big-diff multi-lens review → dispatch each lens as a subagent (saves main context).
- Blocked subagent returns: `Problem / Attempted / Solution / Alternative / Partial`.

## Skills (superpowers)

Invoke via the `Skill` tool. **Precedence:** when an agenda references a skill, the loaded skill replaces the agenda's numbered steps for that procedure; if not loaded, the agenda is the canonical fallback. Never run both for the same procedure.

Agenda-relevant skills: `writing-plans`, `executing-plans`, `systematic-debugging`, `test-driven-development`, `verification-before-completion`, `requesting-code-review`, `using-git-worktrees`, `dispatching-parallel-agents`.

## Commands

Slash commands under `/tt:*`. Auto-invoke when user intent clearly matches.

**Agendas** (multi-step workflows over an artefact):
- `/tt:plan` — write an approved plan
- `/tt:impl` — execute an approved plan
- `/tt:review` — review across the lens panel (single-agent, fast, daily use)
- `/tt:review-strict` — strict review: full subagent panel, mandatory schema, block-on-blocker (pre-release, security, architecture)
- `/tt:review-plan-impl` — combo: review existing code → plan → implement (harden existing artefact)
- `/tt:plan-review-impl` — combo: plan → review the plan → implement (vet a green-field design before building)
- `/tt:debug` — root-cause diagnosis
- `/tt:refactor` — structural change (Beck two-hats)
- `/tt:edge-cases` — hypothetical risk discovery
- `/tt:docs` — write documentation (Diátaxis)
- `/tt:research` — produce a durable research brief from unfamiliar subject matter
- `/tt:finish` — final pre-merge sign-off: docs current (+ changelog) → tests prove it (targeted; CI runs full) → breaking/regression analysis → `/tt:review`, then an evidence-backed merge promise (or refuses, naming the blocker)
- `/tt:summary` — high-level brief of what a branch changed (endpoints/fields/client-visible behaviour + key implementation notes); read-only, no gating

**Actions** (single operations):
- `/tt:act:check` — pre-commit, linters, tests
- `/tt:act:commit` — prepare/create commit (amend if unpushed, authorship checked)
- `/tt:act:branch` — create branch (upcoming or move existing work)
- `/tt:act:push` — push current branch (explicit auth)
- `/tt:act:pr` — open a draft PR (PR-first)
- `/tt:act:issue` — create a Linear issue (priority/estimate/hierarchy conventions, fact-checked desc)
- `/tt:act:bump` — bump version + cut release heading (changelog content via `/tt:act:changelog`)
- `/tt:act:changelog` — update/clean up changelog without bumping (prod-dated entries)
- `/tt:act:explain` — explain topic/code
- `/tt:act:diagram` — Mermaid diagram
- `/tt:act:ralph` — initialise a Ralph Wiggum refinement loop

**Lens** (`/tt:pov:*`, mode-agnostic dimensional specialists):
- `scope` — essential vs accidental complexity
- `architecture` — boundaries, dependencies, layering
- `ux` — interaction surface (GUI/TUI/CLI/API/library/config)
- `security` — threats, authn/authz, secrets, crypto
- `performance` — measurement-first bottleneck analysis
- `reliability` — failure modes, observability, deploy/recover
- `quality` — duplication, idiom, separation
- `testing` — coverage, testability, edge cases
- `docs` — Diátaxis tutorials / how-tos / reference / explanation, runbooks, changelog, ADRs
- `aesthetics` — formatting, naming, comments (runs last)

**Context** (`/tt:mod:*`, per-language house style):
- `/tt:mod:nix` — declarative, flake-parts, treefmt, module style
- `/tt:mod:rs` — pedantic clippy via pre-commit, idiom expectations
- `/tt:mod:js` — Yarn + mkYarnPackage, oxlint pedantic, Playwright
- `/tt:mod:sh` — bash strict mode, `say()` helper, packaging via `makeWrapper`

Mode taxonomy (consumed by lens specialists):

| Agenda | Mode | Lens dimensions framed as… |
|---|---|---|
| `/tt:plan`, `/tt:impl` | planning | commitments before code exists |
| `/tt:review` | review | defects in existing code |
| `/tt:debug` | diagnosis | which assumption broke? |
| `/tt:refactor` | restructure | behaviour-preserving moves |
| `/tt:edge-cases` | risk-discovery | what could go wrong? |
| `/tt:docs` | authoring | discipline for writing |
| `/tt:research` | research | what do I need to understand? |
| `/tt:finish` | verification | is this safe to merge? |

## Ralph Loop

User-initiated (`/ralph-loop`). Inside the loop: check files/git for the prior iteration's work; build incrementally; run tests/linters; emit `<promise>TEXT</promise>` only when truly done.
