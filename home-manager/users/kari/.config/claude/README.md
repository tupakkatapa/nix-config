# Claude config

`/tt:*` slash commands live in `commands/`; the lenses and language contexts they draw on live in `pov/` and `mod/`. Four tiers:

| Tier | What it is | Location | Reached as | Examples |
|------|-----------|----------|------------|----------|
| **agenda** | multi-step workflow over an artefact | `commands/*.md` | `/tt:<name>` | `start`, `plan`, `review`, `ship`, `monitor`, `debug`, `finish` |
| **action** | a single operation | `commands/act/*.md` | `/tt:act:<name>` | `commit`, `branch`, `pr`, `check-draft`, `release-chores` |
| **lens** | a way of thinking — a mode-agnostic dimension | `pov/*.md` | file `~/.claude/tt/pov/<name>.md` | `scope`, `arch`, `compat`, `sec`, `testing` |
| **context** | a domain of knowledge — per-language house style | `mod/*.md` | file `~/.claude/tt/mod/<name>.md` | `nix`, `rs`, `js`, `sh` |

Agendas and actions are slash commands. Lenses and contexts are plain reference files that agendas (and their subagents) read by path, a section at a time; they sit outside `commands/` so they stay out of the command listing. This README sits outside `commands/` for the same reason: every `.md` inside `commands/` becomes a command.

Skills live in `skills/<name>/SKILL.md` (`gh-recipes`, `subagent-execution`, `yt-clip`) and are invoked through the `Skill` tool. `default.nix` installs all of it under `~/.claude`.

## Composition

Agendas sit on top and **orchestrate** the lower tiers — they reference lenses, context, and actions rather than restating them:

```
agenda  ──uses──▶  lens     (which dimensions to inspect, framed per the agenda's mode)
        ──uses──▶  context  (the language's house style to honour)
        ──uses──▶  action   (commit, changelog, … as steps)
```

Governing principle: **the upstream (agenda) structure stays stable; its output changes when a downstream tier changes.** Improve a lens, refine a context file, or fix an action — and every agenda that pulls it in produces better output automatically, with no edit to the agenda itself. The agenda says *which* lenses/context/actions apply and in what order; the *content* of each lives in one place, downstream, and propagates upward.

Example: `/tt:review` names the lens panel and order; the actual inspection criteria live in `pov/*.md`. Sharpen `pov/sec.md` and every agenda that runs the security lens (`review`, `review-strict`, `plan`) tightens — no agenda file touched.

## Modes

A lens is mode-agnostic; the *agenda* supplies the mode that frames the lens's dimensions (planning / review / diagnosis / restructure / risk-discovery / authoring / research / verification). The agenda→mode mapping lives in `CLAUDE.md` (this directory).

## Registry

A command's frontmatter `description` is the single statement of what it is for; it is what the command listing shows. `CLAUDE.md` (this directory) is the canonical index of tiers: it names the agendas and actions, lists every lens and context with a one-line description, and holds the mode taxonomy. Add a command file under `commands/` with a `description`, then add its name there; add a lens or context file, then add its line there.
