
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

# Rust project context (tupakkatapa house style)

Distilled from `~/Workspace/local/tupakkatapa/{nixos-runtime-modules,ftpilot,levari,ping-sweep,nvimkata,anytui}`. Assumes the Nix layer described in `/tt:mod:nix`. Shell scripts in the project follow `/tt:mod:sh`. Per-project `./CLAUDE.md` may override anything here.

## Philosophy
- **Pedantic clippy is non-negotiable.** Code merges only with `clippy::pedantic` and `clippy::cognitive_complexity` denied. Fix the lint; don't silence it.
- **No `#[allow(...)]` without a justifying comment** on the line above naming the specific clippy lint and the reason it's wrong here (false positive, FFI signature constraint, etc.). Matches the global rule in `~/.claude/CLAUDE.md`.
- **No Cargo.toml lints section.** Enforcement happens through pre-commit hooks, not through code-level `[lints.*]` tables. One source of truth (the hook), one error format.
- **`cargo test` runs in pre-commit, not in `nix build`.** `doCheck = false` in the derivation when tests need anything beyond the sandbox. Tests are part of the commit workflow.
- **No profile overrides without measurement.** Defaults are fine for nearly everything. Any `[profile.release]` tweak (LTO, strip, opt-level) is justified by a measurement comment.
- **Latest stable Rust.** No explicit MSRV. The flake's `nixpkgs` pin determines the toolchain version.

## Cargo.toml — real shape

The minimum that real projects ship (`nixos-runtime-modules/Cargo.toml`, `levari/Cargo.toml`, `ping-sweep/Cargo.toml`):

```toml
[package]
name = "<name>"
version = "0.1.0"
edition = "2021"            # "2024" for projects on recent nixpkgs

[dependencies]
# direct per-crate deps; alphabetical

[dev-dependencies]
# test-only deps; alphabetical
```

Real projects intentionally **omit** `description`, `license`, `repository`, `authors`. License lives in a top-level `LICENSE` file; repository info lives in the README. Add these fields only when publishing to crates.io.

For multi-crate **workspaces** (`ftpilot/Cargo.toml`, `anytui/Cargo.toml`):

```toml
[workspace]
members = ["crates/*"]
resolver = "2"

[workspace.dependencies]
ratatui = "0.30"
crossterm = "0.30"
zeroize = "1"
```

Members inherit with `.workspace = true`:

```toml
# crates/foo/Cargo.toml
[dependencies]
ratatui.workspace = true
crossterm.workspace = true
```

## Pre-commit hooks for Rust

Added to the `pre-commit.settings.hooks` block from `/tt:mod:nix`. **Verified verbatim** against `nixos-runtime-modules/flake.nix`, `ftpilot/flake.nix`, `anytui/flake.nix`, `nvimkata/flake.nix`:

```nix
pre-commit.settings.hooks = {
  treefmt = { /* from /tt:mod:nix */ };
  pedantic-clippy = {
    enable = true;
    entry = "cargo clippy -- -D clippy::pedantic -D clippy::cognitive_complexity";
    files = "\\.rs$";
    pass_filenames = false;
  };
  cargo-test = {
    enable = true;
    entry = "cargo test --all-features";
    files = "\\.rs$";
    pass_filenames = false;
  };
};
```

Notes:
- **No `--all-targets`** in clippy. Real practice is the bare `cargo clippy`. Don't add flags that aren't there.
- `cargo test --all-features` is the test command. `--all-features` is the default review baseline; tighten only when feature combinations are mutually exclusive (the project's CLAUDE.md would say so).
- `cognitive_complexity` is denied alongside `pedantic`. Clippy's default threshold (currently 25 expressions) is the line; suppressions with `#[allow(clippy::cognitive_complexity)]` need a comment explaining why the function genuinely can't be smaller.

## treefmt additions for Rust

Already covered by `/tt:mod:nix`. Add to its `programs` block:

```nix
programs = {
  # ... from /tt:mod:nix ...
  rustfmt.enable = true;
  taplo.enable = true;     # TOML formatter, useful for non-trivial Cargo.toml
};
```

`rustfmt.toml` not needed in most projects; defaults are fine. Override only with project-level justification.

## Devshell additions

```nix
devShells.default = pkgs.mkShell {
  packages = with pkgs; [
    cargo
    clippy
    rustc
    rustfmt
    cargo-tarpaulin   # coverage when needed (in nixos-runtime-modules, nvimkata, anytui)
    pre-commit
  ];
  shellHook = config.pre-commit.installationScript;
};
```

`rustup` is **not** in the devshell — the Nix-provided toolchain is the source of truth.

## Packaging — real idiom

See the canonical shape in `/tt:mod:nix` ("Packaging — the real idiom"). Rust-specific addition for runtime tool dependencies:

```nix
{ rustPlatform, lib, pkgs, makeWrapper, nix, ... }:
let manifest = (lib.importTOML ./Cargo.toml).package;
in rustPlatform.buildRustPackage {
  pname = manifest.name;
  inherit (manifest) version;

  nativeBuildInputs = with pkgs; [ pkg-config makeWrapper ];

  src = lib.sourceByRegex ./. [
    "^Cargo.toml$"
    "^Cargo.lock$"
    "^src.*$"
    "^tests.*$"
  ];

  cargoLock.lockFile = ./Cargo.lock;

  postInstall = ''
    wrapProgram $out/bin/${manifest.name} \
      --prefix PATH : ${lib.makeBinPath [ nix ]}
  '';

  # Tests require nix daemon access; run in pre-commit instead.
  doCheck = false;
}
```

`makeWrapper` + `postInstall` is how runtime dependencies (e.g. `masscan` and `lftp` in ftpilot, `neovim` in nvimkata, `nix` in nixos-runtime-modules) become reachable without polluting the user's environment. The trailing one-line comment naming the reason for `doCheck = false` is the convention.

## Project layout

```
.
├── Cargo.toml
├── Cargo.lock
├── flake.nix
├── flake.lock
├── package.nix
├── README.md
├── CHANGELOG.md         (when project is released)
├── LICENSE
├── docs/
│   └── plans/           ( /tt:plan output )
├── src/
│   ├── main.rs          (binary crate)
│   ├── lib.rs           (library crate)
│   └── <modules>.rs
└── tests/
    └── <integration>.rs (integration tests)
```

- Binary entry: `src/main.rs`. Keep it thin — parse args, call into `lib`.
- Library entry: `src/lib.rs`. All testable logic lives behind the library surface.
- Integration tests: `tests/<name>.rs`. One file per distinct integration scenario (`nvimkata/tests/{challenge,curriculum,nvim,state}.rs`).
- Unit tests: inline `#[cfg(test)] mod tests` at the bottom of each module file.

## Idiom expectations

- **`thiserror` for libraries, `anyhow` for binaries.** Libraries surface typed errors; binaries collapse them with context.
- **`tracing` over `log`.** Structured events for everything operationally relevant. `tracing-subscriber` configured at the binary boundary.
- **Avoid `unwrap()` outside tests, examples, and `main()` of binaries.** When you must, use `expect("...")` with a message that explains the invariant.
- **No `unsafe` without justification in a comment AND a covering test.** If the project never needs `unsafe`, `#![forbid(unsafe_code)]` at the crate root.
- **Prefer iterators and combinators over manual loops** where they read better (clippy's pedantic group flags many of these).
- **Newtype for domain primitives** (currency, identifiers, paths). Don't pass raw `String` / `u64` across module boundaries when the domain has a name for the thing.
- **`#[must_use]` on builders and `Result`-likes** that consumers might silently drop.

## CHANGELOG

`Keep a Changelog` + SemVer. Versions match `Cargo.toml`. See `/tt:act:bump`.

## Gotchas
- `rust-toolchain.toml` and the Nix toolchain can disagree. Don't ship a `rust-toolchain.toml` unless you also pin its content from the flake.
- `cargo install` inside the project installs to `~/.cargo/bin` and silently shadows the Nix-provided toolchain. Document in the README if this matters.
- Workspace `default-members` exists; use it when `cargo run` from the root should default to one specific crate.
- `cargo clippy --fix` rewrites code in place — re-run clippy to verify; it does not always preserve formatting (`rustfmt` after).
