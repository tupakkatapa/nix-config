---
description: "Take finished work to a commit ready to push: one review pass, fix the findings, sign-off gates, commit, print the push command. Use for 'review, finish, commit'."
argument-hint: "[base ref]"
---

You are taking finished work to a pushable commit in one pass. This orchestrates `/tt:review`, `/tt:finish` and `/tt:act:commit`; their files own the detail. It exists to be fast: one review, targeted tests, no ceremony.

## Discipline
1. **One review pass.** `/tt:review` runs once. `/tt:finish` reuses its result and does not review again.
2. **No full test suite.** Run only tests that cover the changed code. CI owns the suite.
3. **Fix, don't hand off.** Address every finding at Medium or above in this pass. A behavioural fix follows the repro-test rule: a test that fails for the stated reason, then the fix. Only a structural redesign stops the run.
4. **Zero tolerance for regressions and breaking changes.** An unaccepted break blocks the commit.
5. **Never push.** The user pushes.

## 1. Scope
The current branch against its base, uncommitted changes included. Base: the argument, else the integration branch named in the project `CLAUDE.md`, else the remote default branch.

## 2. Non-goals check
If a plan file covers this work (a file in `docs/plans/` whose slug matches the branch name, or one the user named), read its **Non-goals** and compare the diff against each line. A breach blocks: name the line and the hunk, then stop.

## 3. Review and fix
Run `/tt:review` on the diff, without its checks step (tests run once, in §4). Apply its dispositions and fix findings per Discipline 3. Low and Nit findings: fix when it is a one-line change, else list them.

## 4. Sign-off
Run `/tt:finish` gates 2 to 4 (docs current, tests prove it, no breaking changes or regressions). Gate 5 is satisfied by §3. A blocked gate that this pass can fix gets fixed, then the gate re-runs once. A gate still blocked stops the run with the blocker named.

## 5. Commit
Run `/tt:act:commit`. An unaccepted breaking change, or a gate still blocked, means no commit.

## 6. Report
In this order, nothing else:
- The promise line from `/tt:finish`, with its confidence and the one assumption that would break it.
- Findings fixed, one line each. Findings left, one line each.
- The push command, last, in a code block: `git -C <absolute repo or worktree path> push -u origin <branch>`.

Next: the user pushes, then `/tt:monitor`.
