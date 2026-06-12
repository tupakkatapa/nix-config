# Claude config

`/tt:*` slash commands live in `commands/`, organised into four tiers. Each tier is a directory layer; the prefix mirrors the path. (This README sits outside `commands/` on purpose — every `.md` *inside* `commands/` is auto-discovered as a command.)

| Tier | What it is | Location | Invoke | Examples |
|------|-----------|----------|--------|----------|
| **agenda** | multi-step workflow over an artefact | `commands/*.md` | `/tt:<name>` | `plan`, `impl`, `review`, `debug`, `refactor`, `finish`, `summary` |
| **lens** | a way of thinking — a mode-agnostic dimension | `commands/pov/*.md` | `/tt:pov:<name>` | `scope`, `architecture`, `security`, `testing` |
| **context** | a domain of knowledge — per-language house style | `commands/mod/*.md` | `/tt:mod:<name>` | `nix`, `rs`, `js`, `sh` |
| **action** | a single operation | `commands/act/*.md` | `/tt:act:<name>` | `commit`, `branch`, `pr`, `changelog`, `bump` |

The conceptual names `lens` and `context` map to the directories `pov/` and `mod/` (and the `/tt:pov:` / `/tt:mod:` prefixes).

## Composition

Agendas sit on top and **orchestrate** the lower tiers — they reference lenses, context, and actions rather than restating them:

```
agenda  ──uses──▶  lens     (which dimensions to inspect, framed per the agenda's mode)
        ──uses──▶  context  (the language's house style to honour)
        ──uses──▶  action   (commit, changelog, … as steps)
```

Governing principle: **the upstream (agenda) structure stays stable; its output changes when a downstream tier changes.** Improve a lens, refine a context file, or fix an action — and every agenda that pulls it in produces better output automatically, with no edit to the agenda itself. The agenda says *which* lenses/context/actions apply and in what order; the *content* of each lives in one place, downstream, and propagates upward.

Example: `/tt:review` names the lens panel and order; the actual inspection criteria live in `commands/pov/*.md`. Sharpen `pov/security.md` and every agenda that runs the security lens (`review`, `review-strict`, `plan`, `finish`) tightens — no agenda file touched.

## Modes

A lens is mode-agnostic; the *agenda* supplies the mode that frames the lens's dimensions (planning / review / diagnosis / restructure / risk-discovery / authoring / research / verification). The agenda→mode mapping lives in `CLAUDE.md` (this directory).

## Registry

`CLAUDE.md` (this directory) is the canonical index — every command with a one-line description, plus the mode taxonomy. Add a command file under `commands/`, then register it there. (`commands/CLAUDE.md` is unrelated — a claude-mem scratch file, not the registry.)
