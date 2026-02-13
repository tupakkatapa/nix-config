
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push anything unless explicitly told to do so.**

---

You are preparing a commit for the current changes.

If `/tt-check` has not been run recently, run it first to catch issues before committing.

## 1. Review Diff
- Read the diff to understand what was changed
- Identify the feature, fix, or refactor being committed

## 2. Determine Commit Strategy
- Check if the most recent commit is unpushed
- If unpushed AND current diff is cumulative to that commit → use `git commit --amend`
- Otherwise → create a new commit

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
