---
description: "Commit the current changes: amend when the last commit is unpushed and yours, else a new commit. Never pushes."
---

You are preparing a commit for the current changes. If the tree is clean, say so and stop.

If the project's pre-commit hooks have not run on this diff in this session, run them first and fix what they report.

## 1. Review Diff
- Read the diff to understand what was changed
- Identify the feature, fix, or refactor being committed
- If the diff mixes structural change (renames, moves, tidying) with behavioural change, or holds unrelated changes, split it into one commit per kind, structural first

## 2. Determine Commit Strategy
- Check whether the most recent commit is unpushed: `git log -1 HEAD --not --remotes` returns it only when no remote branch contains it. A commit that any remote branch contains is pushed, whatever the current branch's upstream.
- **Authorship check before amending** — `git log -1 --format='%ae'` must equal `git config user.email`. Amending someone else's commit silently rewrites authorship and can break signing. If they differ → create a new commit instead.
- If unpushed AND authored by current user AND current diff is cumulative to that commit → `git commit --amend`.
- Otherwise → create a new commit.

## 3. Craft Commit Message
- Review past commit messages: `git log --oneline -10`
- Match the style, format, and conventions of existing commits
- Write a brief, precise message that represents the change
- Only add extended body or `Co-Authored-By` if the repo convention includes them

## 4. Commit
- Stage only relevant changes—never stage temporary, debug, or unrelated files
- Run the commit (new or amend as determined above)
- **Never use `--no-verify` or `SKIP=` under any circumstances**
- **Never push—leave that to the user**

### GPG Signing Errors
If you encounter an error related to GPG signing or hardware key, use `AskUserQuestion` to ask:
- Question: "GPG signing failed. Proceed without signing?"
- Options: "Yes" / "No"

Only use `--no-gpg-sign` if the user explicitly approves.
