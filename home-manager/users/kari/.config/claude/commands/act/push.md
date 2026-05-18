
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.

---

Push the current branch to its remote. Invoking this command is the explicit authorisation to push — no further confirmation needed unless the push is non-fast-forward.

## 1. Detect Branch State

- `git branch --show-current` — current branch.
- `git rev-parse --abbrev-ref @{upstream} 2>/dev/null` — upstream, if set.
- `git log --oneline @{upstream}..HEAD 2>/dev/null` — local commits ahead of upstream.
- `git status --short` — uncommitted changes.

If the working tree has uncommitted changes that should be part of this push, ask the user (via `AskUserQuestion`) whether to commit first. Never push past uncommitted intended work.

## 2. Decide Push Mode

- **No upstream set** — push with `-u`:
  ```bash
  git push -u origin <branch-name>
  ```
- **Upstream set, branch ahead** — fast-forward push:
  ```bash
  git push
  ```
- **Diverged from upstream** — **stop**. Ask the user explicitly: rebase, merge, force-with-lease, or abort. Never force-push without explicit user approval, and prefer `--force-with-lease` over `--force`. Pin the expected remote sha explicitly to avoid the race where someone else pushed between your fetch and your push:
  ```bash
  expected_remote_sha=$(git rev-parse @{upstream})
  git push --force-with-lease="$(git branch --show-current):$expected_remote_sha"
  ```
  The unparameterised `--force-with-lease` form uses the locally-cached remote ref and is racy if a background fetch ran.

## 3. Handoff

Report: branch, commits pushed, upstream URL.

If no PR exists for this branch, suggest `/tt:act:pr` to open one.
If CI is configured, name the next sensible check (`gh run watch`, dashboard URL).
