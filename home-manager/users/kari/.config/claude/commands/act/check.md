
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

Run automated checks: pre-commit, linters, and tests.

## 1. Pre-commit
Detect how pre-commit is wired in this project:

- **`.pre-commit-config.yaml` at repo root** → invoke directly:
  ```
  pre-commit run --all-files
  ```
- **`flake.nix` with `git-hooks.nix` / `pre-commit-hooks.nix`** (the tupakkatapa Nix-context default) → the hooks live inside the devshell. Invoke through it:
  ```
  nix develop -c pre-commit run --all-files
  ```
  or rely on `nix flake check` to run the same hooks as a flake check (slower but no devshell entry needed).
- **`pre-commit` not in PATH and no flake hooks** → skip this step; proceed to §2.

Fix all errors and warnings. Repeat until clean. **No lint suppressions** (`noqa`, `#[allow(...)]`, `// eslint-disable`, `// shellcheck disable`, `# type: ignore`, etc.) unless absolutely necessary; suppressions carry a justifying comment on the line above naming the rule and the reason. See the Principles in `~/.claude/CLAUDE.md`.

## 2. Tests & Linters
Detect project type from config files (`flake.nix`, `Cargo.toml`, `pyproject.toml`, `package.json`, `go.mod`, etc.) and run the appropriate commands:
- **Universal**: `make test` or `just test` if available (prefer these).
- **Nix**: `nix flake check` (runs treefmt + module evaluation + any wired tests).
- **Rust**: `cargo test --all-features` (or via `nix develop -c …` when the toolchain lives in the flake).
- **Python**: `pytest`.
- **Go**: `go test ./...`.
- **JS/TS**: `yarn test`, `npm test`, or `pnpm test` depending on the lock file.

Fix all failures. Be skeptical of skipped tests — verify they should be skipped (skips need an owner, a reason, and an expiry per `/tt:pov:testing`).

## 3. Final Pre-commit
Run `pre-commit run --all-files` once more to catch any regression from fixes.

## 4. Handoff
On success, report only that all checks and tests passed. On failure, report which step failed and what remains.
