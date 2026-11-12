---
description: "After the user pushed: open a draft PR against the integration branch, watch CI, fix failures. Also watches CI/CD after a merge. Use for 'pushed, open PR, monitor CI' and 'merged, monitor'."
argument-hint: "[base branch | merged]"
---

You are taking a pushed branch through CI, or watching the pipeline after a merge. You never push and never merge; the user does both.

## 1. Detect the state
Check in this order and take the first that holds:
1. **The user reports a merge, or the argument is `merged`** → §5.
2. **Local commits not on the remote** → print the push command (`git -C <path> push -u origin <branch>`) and stop.
3. **On the integration branch** → stop; there is nothing to monitor.
4. **Branch pushed, no PR** → §2.
5. **Branch pushed, PR exists** → §3.

## 2. Open the PR
Run `/tt:act:pr`. Base: the argument, else the integration branch named in the project `CLAUDE.md`, else the remote default branch.

## 3. Watch CI
Run `gh pr checks --watch` as a background command so a long pipeline cannot hit the tool timeout; do not poll in a loop and do not narrate while waiting. If the repository has no checks configured, say so and go to §6.

## 4. Fix failures
For each failed check: read the failing job's log (`gh run view --log-failed`), find the cause, fix it under the repro-test rule where a test can express it. Then `/tt:act:commit`, print the push command, and stop. After the user pushes, resume at §3.

Merge conflicts with the base: merge the base branch in and resolve (a plain push still works); say what was resolved. Do not rebase a pushed branch.

A failure unrelated to the branch (flaky job, broken base, infrastructure) is reported with its evidence, not patched around.

## 5. After a merge
Watch the pipeline on the target branch: build, deploy, and migrations if the project has them. Then check the deployed service's logs for new errors since the deploy, where the project gives access. Report what ran and what was checked; a step that could not be checked is named as unchecked.

If the work ran in a worktree, end with the commands to remove it and its local branch (`git worktree remove <path>` and `git branch -d <branch>`), for the user to run.

## 6. Report
- State: green, red (with the failing check and cause), or waiting on the user.
- The PR URL.
- The user's next action, last, as an exact command: on green `gh pr ready <number>`, then the merge is theirs.
