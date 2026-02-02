
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- **Do not push or commit anything unless explicitly told to do so.**

---

Run automated checks: pre-commit, linters, and tests.

## 1. Pre-commit
If `.pre-commit-config.yaml` exists:
```
pre-commit run --all-files
```
Fix all errors and warnings. Repeat until clean. Avoid NOQA/noqa comments.

## 2. Tests & Linters
Detect project type and run the appropriate commands:
- **Universal**: `make test` or `just test` if available (prefer these)
- **Python**: `pytest`
- **Rust**: `cargo test --all-features`
- **Nix**: `nix flake check`

Fix all failures. Be skeptical of skipped tests—verify they should be skipped.

## 3. Final Pre-commit
Run `pre-commit run --all-files` once more to catch any regression from fixes.

## 4. Handoff
No need to summarize or report, state that all checks and tests passed.
