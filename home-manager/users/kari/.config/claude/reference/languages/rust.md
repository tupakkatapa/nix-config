# Rust project context (tupakkatapa house style)

Conventions from `~/Workspace/tupakkatapa/{nixos-runtime-modules,nvimkata,anytui,ftpilot,kaloriina,ping-sweep}`. Assumes the Nix layer in `~/.claude/tt/languages/nix.md`. Shell scripts follow `~/.claude/tt/languages/shell.md`. Per-project `./CLAUDE.md` may override anything here.

## Philosophy
- **Pedantic clippy.** Code merges only with `clippy::pedantic` and `clippy::cognitive_complexity` denied. `#[allow(...)]` follows the global suppression rule in `~/.claude/CLAUDE.md`.
- **No `[lints]` table in Cargo.toml.** No project has one; the pre-commit hook is the single place of enforcement.
- **`cargo test` runs in pre-commit.** It also runs in `nix build` when the tests pass in the sandbox (kaloriina); otherwise `doCheck = false` with a comment that names the reason (nixos-runtime-modules).
- **No profile overrides without a measurement.**
- **Latest stable Rust, no MSRV.** The flake's nixpkgs pin sets the toolchain. `rustup` is not in any devshell.

## Cargo.toml

Single crate, shape of `kaloriina/Cargo.toml` and `nvimkata/Cargo.toml`:

```toml
[package]
name = "<name>"
version = "0.1.0"
edition = "2024"
license = "GPL-3.0-or-later"

[dependencies]

[dev-dependencies]
```

- `edition = "2024"` is the default (4 of 6); nixos-runtime-modules and ping-sweep are still on 2021.
- `license` is set in kaloriina and nvimkata; `description` only in kaloriina, where `package.nix` reads it for `meta`. No project sets `authors` or `repository`.

Workspace, from `anytui/Cargo.toml` (ftpilot has the same shape):

```toml
[workspace]
resolver = "2"
members = [
    "packages/tuigreat",
    "packages/voltui",
]

[workspace.package]
version = "0.1.2"
edition = "2024"

[workspace.dependencies]
tuigreat = { path = "packages/tuigreat" }
ratatui = "0.29"
crossterm = "0.28"
```

Member, from `anytui/packages/voltui/Cargo.toml`:

```toml
[package]
name = "voltui"
version = "0.2.0"
edition.workspace = true

[dependencies]
tuigreat.workspace = true
ratatui.workspace = true
```

Members live in `packages/<name>/`, each with its own `default.nix`. In anytui each crate has its own version and `[workspace.package].version` is the release version; the `version-check` hook (`anytui/scripts/check-versions.sh`) fails when a changed crate keeps its version. ftpilot members inherit with `version.workspace = true`.

## Pre-commit hooks

Added to the hooks block of `nix.md`. From `nixos-runtime-modules/flake.nix`; identical entries in anytui, ftpilot and nvimkata:

```nix
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
```

Exception: kaloriina, the newest project, runs `cargo clippy --all-targets -- …` and plain `cargo test` (it has no features), and widens `files` to the fixtures the tests read. Use `--all-targets` in new projects so tests are linted too.

## treefmt and devshell

- treefmt: `rustfmt.enable = true` in every project; `taplo.enable = true` in nvimkata and kaloriina. No `rustfmt.toml`.
- Devshell packages: `cargo clippy rustc rustfmt pre-commit`, plus `cargo-tarpaulin` (nixos-runtime-modules, nvimkata, anytui) or `rust-analyzer` (kaloriina, ping-sweep), plus build inputs such as `pkg-config`.

## Packaging

From `nixos-runtime-modules/package.nix`, without its alias symlink:

```nix
{ rustPlatform
, pkgs
, lib
, nix
}:
let
  manifest = (lib.importTOML ./Cargo.toml).package;
in
rustPlatform.buildRustPackage rec {
  pname = manifest.name;
  inherit (manifest) version;

  nativeBuildInputs = with pkgs; [
    pkg-config
    makeWrapper
  ];

  src = lib.sourceByRegex ./. [
    "^Cargo.toml$"
    "^Cargo.lock$"
    "^src.*$"
    "^tests.*$"
  ];

  cargoLock.lockFile = ./Cargo.lock;

  postInstall = ''
    wrapProgram $out/bin/${pname} \
      --prefix PATH : ${lib.makeBinPath [ nix ]}
  '';

  # Tests require access to a /nix/ and a nix daemon; we run them at pre-commit instead
  doCheck = false;
}
```

- `sourceByRegex` patterns are anchored; add every directory the build or tests read (`^challenges.*$` in nvimkata, `^web.*$` and `^build.rs$` in kaloriina).
- A package with no runtime tools drops `makeWrapper` and `postInstall` (`ping-sweep/package.nix`).
- A workspace member builds from the workspace root: `src = lib.sourceByRegex ../.. [ … "^packages.*$" ]`, `cargoLock.lockFile = ../../Cargo.lock`, `cargoBuildFlags = [ "--package" pname ]` (`anytui/packages/voltui/default.nix`).
- When tests run in the sandbox, set what the sandbox lacks in `preCheck` (`SSL_CERT_FILE`, `TZDIR` in `kaloriina/package.nix`) and add `meta` with `mainProgram`.

## Project layout

```
Cargo.toml  Cargo.lock  flake.nix  flake.lock  package.nix
README.md  CHANGELOG.md  LICENSE
docs/plans/          ( /tt:plan output )
src/main.rs          thin: parse arguments, call into lib
src/lib.rs           testable logic
tests/<scenario>.rs  one file per scenario (nvimkata/tests/{challenge,curriculum,nvim,state}.rs)
```

Unit tests: inline `#[cfg(test)] mod tests` at the bottom of the module.

## Idiom expectations

- **`anyhow` in binaries, `thiserror` for typed library errors** (kaloriina uses both; nixos-runtime-modules uses `anyhow`).
- **`tracing` over `log`**, with `tracing-subscriber` set up in `main` (kaloriina).
- **No `unwrap()` outside tests.** Use `expect("...")` with the invariant when a panic is right.
- **`#![forbid(unsafe_code)]` at the crate root** when the project needs no `unsafe` (`kaloriina/src/lib.rs`).
- **Newtypes for domain primitives** across module boundaries.

## Gotchas
- `cargo install` in the project puts binaries in `~/.cargo/bin`, ahead of the Nix toolchain.
- `cargo clippy --fix` does not keep formatting; run `nix fmt` after it.
