Create a git commit for current changes.

## Analysis

1. Run `git status` to see changes
2. Run `git diff --staged` for staged changes
3. Run `git log -3 --oneline` for commit style reference

## Commit Process

1. Stage relevant files (if not already staged)
2. Create commit message that:
   - Summarizes the change in imperative mood
   - Focuses on "why" not "what"
   - Matches repository style
3. Do NOT use `--no-verify` or `--no-gpg-sign`

## Safety

- Never force push
- Never skip hooks without explicit permission
- If hooks fail, fix issues and try again
