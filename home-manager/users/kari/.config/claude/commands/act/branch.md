
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

Create a new branch. Handles two scenarios:

1. **Upcoming work** — clean tree on the integration branch; create branch, switch to it, ready to start.
2. **Work already in progress** — uncommitted changes or local commits on the wrong branch (typically the integration branch); carry that work onto a new branch.

## 1. Detect Scenario

Run:
- `git branch --show-current` — current branch.
- `git status --short` — uncommitted changes.
- `git log --oneline @{upstream}..HEAD 2>/dev/null` — local commits ahead of upstream.

Decide:
- Clean tree, no commits ahead → **upcoming work**.
- Uncommitted changes only → **work in progress (uncommitted)**.
- Local commits ahead on integration branch → **work already committed to wrong branch**.
- Already on a feature branch → ask the user whether this is intentional; the action is normally invoked from the integration branch.

If the scenario is ambiguous (mix of states, unusual setup), state what was detected and ask the user to confirm before proceeding.

## 2. Choose Branch Name

If the user named the branch, use that verbatim.

Otherwise derive from the most recent plan in `docs/plans/`:
- Strip the `docs/plans/` prefix and `.md` suffix.
- Prepend a type prefix matching repo convention (`feat/`, `fix/`, `refactor/`, `docs/`, `chore/`). Infer the type from the plan's Goal line; if ambiguous, ask the user.
- Example: `docs/plans/2026-05-16-add-foo.md` → `feat/2026-05-16-add-foo`.

If no plan exists, ask the user for a short kebab-case title plus a type.

## 3. Create the Branch

Determine the integration branch dynamically (don't hardcode `main`):
```bash
integration=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
integration=${integration:-$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)}
integration=${integration:-main}
```

### Upcoming work (clean tree)
Fetch and fast-forward the integration branch first:
```bash
git fetch origin
git merge --ff-only "origin/$integration"
git checkout -b "<branch-name>"
```

### Work in progress (uncommitted)
Uncommitted changes follow the checkout automatically:
```bash
git checkout -b "<branch-name>"
```

### Work already committed to wrong branch — destructive sequence

This path rewinds the integration branch. **Refuse if the working tree has uncommitted changes** (they would be destroyed by `git reset --hard`). Stash or commit first.

Step-by-step:

1. **Verify clean working tree** — abort otherwise:
   ```bash
   if [[ -n "$(git status --porcelain)" ]]; then
     echo "Uncommitted changes present. Stash or commit before proceeding." >&2
     exit 1
   fi
   ```
2. **Show the user what is about to move** (this must run *before* any destructive command):
   ```bash
   git fetch origin
   echo "The following commits will be moved from $integration to <branch-name>:"
   git log --oneline "origin/$integration..HEAD"
   ```
3. **Confirm with the user via `AskUserQuestion`** — explicit yes required (auto mode does not bypass this; criterion: irreversible operation on shared state).
4. **Apply the move** — mark the branch first, then rewind, then check out:
   ```bash
   git branch "<branch-name>"
   git reset --hard "origin/$integration"
   git checkout "<branch-name>"
   ```

Never run step 4 without steps 1–3 in order.

## 4. Handoff

Report:
- New branch name.
- Scenario detected.
- Commits/changes now on the new branch.

Suggest next steps based on scenario:
- **Upcoming work** — `/tt:act:commit` (for the plan file), then `/tt:act:push` + `/tt:act:pr`.
- **Work in progress** — `/tt:act:commit` (for the staged changes), then `/tt:act:push` + `/tt:act:pr`.
- **Work already committed** — `/tt:act:push` + `/tt:act:pr`; the commits are now on the feature branch.
