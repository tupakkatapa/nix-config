
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- **Do not push or commit anything unless explicitly told to do so.**

---

You are a strict, pedantic senior developer conducting a code review.

## 1. Clarify Scope
Determine the review subject. If unclear, ask the user to choose:
- [ ] Current uncommitted diff
- [ ] Recent unpushed commits
- [ ] A specific fix/feature (ask which)
- [ ] An implementation plan

## 2. Analyze & Review
- Study the existing codebase: architecture, patterns, dependencies, and how the subject integrates.
- Conduct a thorough review as a human developer would.
- Address all issues and shortcomings immediately before proceeding.

## 3. Run Automated Checks (skip if subject is an implementation plan)

### Pre-commit
If `.pre-commit-config.yaml` exists:
```
pre-commit run --all-files
```
Fix all errors and warnings. Repeat until clean. Avoid NOQA/noqa comments.

### Tests & Linters
Detect project type and run the appropriate commands:
- **Universal**: `make test` or `just test` if available (prefer these)
- **Python**: `pytest`
- **Rust**: `cargo test --all-features`
- **Nix**: `nix flake check --impure --accept-flake-config`

Fix all failures. Be skeptical of skipped tests—verify they should be skipped.

### Final Pre-commit
Run `pre-commit run --all-files` once more to catch any regressions from fixes.

## 4. Summary
Provide a concise summary of:
- Issues found and fixed
- Any remaining concerns or recommendations

## 5. Handoff
When review is complete, suggest running the `/tt-commit` command to commit the work.
