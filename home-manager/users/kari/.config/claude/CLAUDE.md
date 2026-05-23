# Claude Configuration

## Principles

- When unsure, choose the most fundamentally right action instead of asking.
- Fix all failing tests. They run continuously, so failures are from recent changes.
- All changes must pass `nix fmt` and existing tests.
- **No lint suppressions** — `# noqa`, `#[allow(...)]`, `// eslint-disable`, `// shellcheck disable`, `# type: ignore`, equivalents — unless absolutely necessary. Fix the underlying issue. Unavoidable suppressions carry a comment on the line above naming the rule and the reason.
- **Plan Mode is user-initiated.** With `defaultMode = "auto"`, autonomous execution is the default. Do not call `EnterPlanMode` unilaterally; if the user already activated Plan Mode, use `ExitPlanMode` to surface the plan; otherwise present plans inline alongside the file path.
- **Lazy-read reference files.** `/tt:pov:*` and `/tt:mod:*` files are reference, not preludes. Read the section you need (Identity / Symptoms / Dimensions / Output Schema) — don't pull the whole file when one section answers the question. For multi-lens passes, prefer subagent dispatch (each lens gets isolated context, returns findings only) over reading 10 lens files into the main context.

## NixOS Development

`~/Workspace/tupakkatapa/nix-config` (github.com/tupakkatapa/nix-config) is the source of truth.

- NEVER suggest `apt install`, `brew install`, `pip install`, or similar.
- Temporary: `nix-shell -p <package>` or `, <command>` (comma runs from nixpkgs).
- Permanent: add to config, `direnv reload`, restart session.
- Check packages: `nix eval --json github:tupakkatapa/nix-config#nixosConfigurations.$HOSTNAME.config.environment.systemPackages --apply 'builtins.map (p: p.name)'`
- Hosts: `nix eval --json github:tupakkatapa/nix-config#nixosConfigurations --apply builtins.attrNames`

## Subagent Dispatch

Task tool for parallel work. Subagents can't ask questions — full context upfront.

- 3+ independent tasks → dispatch parallel subagents in one message.
- Codebase exploration → Explore subagent (read-only, fast).
- Background → `Task(..., run_in_background=true)`.
- Scale: simple 1–2, medium 3–4, complex 5–6.
- Multi-lens reviews on big diffs → dispatch lenses as subagents (saves main context).

Blocked subagent returns: `Problem / Attempted / Solution / Alternative / Partial`.

## Skills (superpowers)

Invoke via `Skill` tool. **Precedence:** when an agenda references a skill, the loaded skill replaces the agenda's numbered steps for that procedure; if not loaded, the agenda is the canonical fallback. Never run both for the same procedure.

Skills relevant to agendas: `writing-plans`, `executing-plans`, `systematic-debugging`, `test-driven-development`, `verification-before-completion`, `requesting-code-review`, `using-git-worktrees`, `dispatching-parallel-agents`.

## Commands

Slash commands under `/tt:*`. Auto-invoke when user intent clearly matches.

**Agendas** (workflows over an artefact):
- `/tt:plan` — write an approved plan
- `/tt:impl` — execute an approved plan
- `/tt:review` — review across the lens panel (single-agent, fast, daily use)
- `/tt:review-strict` — strict review: full subagent panel, mandatory schema, block-on-blocker (pre-release, security, architecture)
- `/tt:review-plan-impl` — hands-free combo: strict review → plan → implement, auto-advances between phases
- `/tt:debug` — root-cause diagnosis
- `/tt:refactor` — structural change (Beck two-hats)
- `/tt:edge-cases` — hypothetical risk discovery
- `/tt:docs` — write documentation (Diátaxis)
- `/tt:research` — produce a durable research brief from unfamiliar subject matter

**Actions** (single operations):
- `/tt:act:check` — pre-commit, linters, tests
- `/tt:act:commit` — prepare/create commit (amend if unpushed, authorship checked)
- `/tt:act:branch` — create branch (upcoming or move existing work)
- `/tt:act:push` — push current branch (explicit auth)
- `/tt:act:pr` — open a draft PR (PR-first)
- `/tt:act:bump` — bump version + changelog
- `/tt:act:explain` — explain topic/code
- `/tt:act:diagram` — Mermaid diagram
- `/tt:act:ralph` — initialise a Ralph Wiggum refinement loop

**Lens** (mode-agnostic dimensional specialists):
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

**Context** (per-language house style, distilled from real projects):
- `/tt:mod:nix` — declarative, flake-parts, treefmt, module style
- `/tt:mod:rs` — pedantic clippy via pre-commit, idiom expectations
- `/tt:mod:js` — Yarn + mkYarnPackage, oxlint pedantic, Playwright
- `/tt:mod:sh` — bash strict mode, `say()` helper, packaging via `makeWrapper`

Agenda mode taxonomy (consumed by lens specialists):

| Agenda | Mode | Lens dimensions framed as… |
|---|---|---|
| `/tt:plan`, `/tt:impl` | planning | commitments before code exists |
| `/tt:review` | review | defects in existing code |
| `/tt:debug` | diagnosis | which assumption broke? |
| `/tt:refactor` | restructure | behaviour-preserving moves |
| `/tt:edge-cases` | risk-discovery | what could go wrong? |
| `/tt:docs` | authoring | discipline for writing |
| `/tt:research` | research | what do I need to understand? |

## Ralph Loop

User-initiated (`/ralph-loop`). Inside: check files/git for prior iteration's work, build incrementally, run tests/linters, output `<promise>TEXT</promise>` only when truly done.

## Triggers

| Need | Tool |
|---|---|
| Library/framework docs | context7 MCP |
| NixOS packages/options | nixos MCP |
| Web search | searxng MCP |
| Parallel work (3+ tasks) | Task tool subagents |
| Deep codebase search | Explore subagent |
| Iterative refinement | Ralph Loop (user starts) |
