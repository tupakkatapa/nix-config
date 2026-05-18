
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.

---

Open a pull request for the current branch, **draft by default** (PR-first workflow: the PR is opened before the work is complete and gates CI feedback during development).

## 1. Detect Branch State

- `git branch --show-current` — current branch; abort if on the integration branch.
- `git rev-parse --abbrev-ref @{upstream} 2>/dev/null` — must be set and have at least one commit ahead. If not pushed, suggest `/tt:act:push` first.
- `gh pr view --json url,state 2>/dev/null` — does a PR already exist? If yes, report its URL and stop.

## 2. Generate PR Body

Compose the PR body from available sources, in this order:

1. **Plan file** (`docs/plans/<branch-name>.md` or most recent in the directory) — Goal, Success criteria, Approach summary.
2. **Commits on the branch** (`git log --oneline <upstream>..HEAD`) — list, grouped if many.
3. **Open questions / known TODOs** — anything explicitly marked in the plan as deferred.

Structure:
```markdown
## Goal
<one sentence from plan Goal>

## Plan
See [docs/plans/<filename>.md](<relative-link>).

## Status
- [ ] Implementation complete
- [ ] Tests passing locally
- [ ] CI green
- [ ] Reviewed
```

Adapt the structure to the repo's existing PR template if `.github/PULL_REQUEST_TEMPLATE.md` exists.

## 3. Title

- If the branch name follows `<type>/<date>-<slug>`, derive a title like `<Type>: <slug humanised>` (e.g. `feat/2026-05-16-add-foo` → `feat: add foo`).
- If the plan's Goal line is concise, use it.
- Otherwise ask the user for the title.

## 4. Open the PR

Write the body to a temporary file so it survives review-and-revise:

```bash
body_file=/tmp/pr-body.md
# write the generated body content to "$body_file" first
gh pr create --draft --title "<title>" --body-file "$body_file"
```

Pass `--base "$integration"` if the integration branch is not the repo default (see `branch.md` §3 for how to detect it).

If `gh` is unavailable, print the title, body, and the URL that would open the web form (`https://github.com/<owner>/<repo>/compare/<branch>?expand=1`), and ask the user to open it manually.

## 5. Handoff

Report the PR URL. Suggest (do not invoke):
- `/tt:impl` — when the user is ready to begin executing the plan.
- `gh pr ready` (user runs it themselves) — when the work is ready for review.
