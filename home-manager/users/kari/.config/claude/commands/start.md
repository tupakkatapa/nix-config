---
description: "Start work on an issue or task: new worktree and branch off the integration branch, then build it (plan-review-impl, or debug for a bug). Use for 'branch out into a new worktree, then ...'."
argument-hint: "<issue id | task description>"
---

You are starting a piece of work in isolation and carrying it through `/tt:plan-review-impl`.

## 1. Understand the task
- An issue id → read the issue (title, description, comments, relations, blockers). A blocker that is still open stops the run: name it.
- A description → use it as given.

## 2. Worktree and branch
- Base: the integration branch named in the project `CLAUDE.md`, else the remote default branch. Fetch it first; branch from the remote tip, not a stale local copy.
- Branch name: the project convention (`./CLAUDE.md`, else the pattern of recent branches); include the issue id when there is one.
- Create a git worktree for the branch, at the location the project uses for worktrees, else beside the repository. Work only inside the worktree from here on.

## 3. Build
- A bug or failure → `/tt:debug`.
- A trivial task (single obvious change) → say so in one line and implement directly.
- Anything else → `/tt:plan-review-impl` with the task.

## 4. Stop
Report what was built and where. Stop here unless the user chained further commands; the next one is `/tt:ship`.
