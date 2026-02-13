
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
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
Detect project type from config files (`flake.nix`, `Cargo.toml`, `pyproject.toml`, `package.json`, `go.mod`, etc.) and run the appropriate commands:
- **Universal**: `make test` or `just test` if available (prefer these)
- **Nix**: `nix flake check`
- **Rust**: `cargo test --all-features`
- **Python**: `pytest`
- **Go**: `go test ./...`
- **JS/TS**: `npm test` or `pnpm test`

Fix all failures. Be skeptical of skipped tests—verify they should be skipped.

## 3. Final Pre-commit
Run `pre-commit run --all-files` once more to catch any regression from fixes.

## 4. Handoff
No need to summarize or report, state that all checks and tests passed.
