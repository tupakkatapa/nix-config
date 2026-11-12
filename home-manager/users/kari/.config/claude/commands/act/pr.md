---
description: "Open a draft pull request for the current, already pushed branch."
argument-hint: "[base branch]"
---

Open a draft pull request for the current branch.

## 1. Detect Branch State

- `git branch --show-current` — abort if on the integration branch.
- The branch must be on the remote with nothing local left to push: `git rev-parse --abbrev-ref @{upstream}` resolves and `git log @{upstream}..HEAD` is empty. Otherwise print the push command for the user (`git -C <repo> push -u origin <branch>`) and stop.
- The branch must be ahead of its base: `git log <base>..HEAD` is not empty.
- `gh pr view --json url,state 2>/dev/null` — if a PR already exists, report its URL and stop.

## 2. Generate PR Body

Sources:
1. **Plan file**, only when its slug matches the branch (`feat/2026-05-16-add-foo` → `docs/plans/2026-05-16-add-foo.md`): Goal and a link.
2. **Commits on the branch** (`git log --oneline <base>..HEAD`).

Structure, when the repository has no `.github/PULL_REQUEST_TEMPLATE.md` (else follow the template):
```markdown
## Goal
<one sentence: what this changes for a user or caller>

## Changes
<a handful of bullets, by capability, not by commit>

## Plan
See [docs/plans/<filename>.md](<relative-link>).   <!-- only when a plan exists -->
```

## 3. Title

- If the branch name follows `<type>/<date>-<slug>`, derive a title like `<Type>: <slug humanised>` (e.g. `feat/2026-05-16-add-foo` → `feat: add foo`).
- If the plan's Goal line is concise, use it.
- Otherwise write a short title from the commits, in the style of the repository's recent PR titles.

## 4. Open the PR

Write the body to a temporary file so it survives review-and-revise:

```bash
body_file=/tmp/pr-body.md
# write the generated body content to "$body_file" first
gh pr create --draft --title "<title>" --body-file "$body_file"
```

Pass `--base "$integration"` if the integration branch is not the repo default (the project `./CLAUDE.md` names it; else see `/tt:act:branch` §3).

If `gh` is unavailable, print the title, body, and the URL that would open the web form (`https://github.com/<owner>/<repo>/compare/<branch>?expand=1`), and ask the user to open it manually.

## 5. Report
The PR URL. The user marks it ready (`gh pr ready`) when the work is done.
