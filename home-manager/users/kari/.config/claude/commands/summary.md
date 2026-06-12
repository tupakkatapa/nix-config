
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

You produce a **high-level brief of what a branch changed** — the things a reviewer or client should know before reading the diff. Read-only: this analyses, it does not judge, gate, or modify. Answer "what's new and what behaves differently", not "is it good" (that's `/tt:review`) or "is it safe to merge" (that's `/tt:finish`).

**When to use:** to quickly grasp a branch you (or someone else) built — new endpoints/fields, client-visible behaviour shifts, and the key implementation choices — without reading every line.

**When NOT to use:** for defect-finding (`/tt:review`) or merge sign-off (`/tt:finish`).

## Discipline
1. **Brief, not exhaustive.** Surface what matters; omit mechanical churn (formatting, renames with no behavioural effect). If everything is trivial, say so in one line.
2. **Client/caller perspective first.** Lead with what an external consumer experiences differently, then the internals behind it.
3. **Concrete.** Name the actual endpoints, fields, options, files. "Refactored parsing" is useless; "`/process` now parses CSV row-by-row, adds `status` and `processedAt` fields" is the point.
4. **No verdicts.** Don't rate or flag risk — just report. (Breaking changes may be *noted* factually under their own heading.)

## 1. Scope
Determine the branch and its base (via `AskUserQuestion` if unclear): current branch vs base (default), or a given range. Derive the diff and the commit log over that range.

## 2. Gather
From the diff + commit messages, identify:
- New / changed / removed public surface: endpoints, request & response fields, CLI flags, config & module options, exported functions, schemas, migrations.
- Behavioural changes visible to a caller/client (what a request now does, returns, or requires that it didn't before).
- The key implementation mechanics behind each change — the "how", only where non-obvious (parsing strategy, data flow, new dependencies, side effects).

## 3. Brief
Emit a concise markdown brief. Include only the sections that apply:

- **Summary** — 1–3 sentences: what this branch is about.
- **Client-visible changes** — bullets, caller's perspective. e.g. "`POST /process` now accepts CSV uploads; returns `{ rows, errors }`."
- **New / changed surface** — endpoints, fields (name · type · meaning), options, migrations. A small table if it helps.
- **Key implementation notes** — the non-obvious "how" per notable change. e.g. "CSV parsed with streaming reader; each row mapped to `Job`, adding `status` + `processedAt`."
- **Breaking / migration notes** — factual, only if any public surface changed incompatibly.

Keep the whole brief skimmable. Prefer bullets and short tables over prose.

## 4. Handoff
- The brief is the deliverable — present it inline. Offer to save it (e.g. PR description, `docs/`, the ticket) if the user wants it persisted.
- Natural next steps: `/tt:finish` (merge sign-off) or `/tt:review` (defect pass).
