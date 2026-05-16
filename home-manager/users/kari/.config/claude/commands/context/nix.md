
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

# Nix project & module context (tupakkatapa house style)

Concrete conventions distilled from `~/Workspace/local/tupakkatapa/{nixos-runtime-modules,nixos-sftp-mount,ftpilot,levari,molesk,mozid,gh-dotenv-sync,nvimkata,ping-sweep,anytui}`. Use this when planning, scaffolding, or reviewing any Nix-heavy project. Per-project `./CLAUDE.md` may override anything here.

## Philosophy
- **Declarative over imperative.** No global state outside the Nix store. Configuration is data; reload by rebuild, not by mutation.
- **Pin to a stable release for shipped projects.** `github:NixOS/nixpkgs/nixos-25.11` is the current default. `nixos-unstable` is acceptable when a project relies on a feature not yet in stable; pin it deliberately and document why in the README.
- **One devshell, one source of truth.** The devshell defines the build/test/format toolchain. CI (when present) runs `nix flake check`; pre-commit runs the same tools locally.
- **CI is optional, `nix flake check` is the gate.** No GitHub Actions in any current project. `nix flake check` validates module evaluation, formatter, and (when wired) pre-commit hooks. If CI is added later, it should run that single command.

Cross-language conventions linked from this file:
- Shell scripts: `/tt:context:shell`.
- Rust projects layered on this Nix substrate: `/tt:context:rust`.
- JS projects layered on this Nix substrate: `/tt:context:javascript`.

**No `# statix:ignore` / `# deadnix: skip` without a justifying comment** on the line above naming the lint and the reason. Fix the warning first. Matches the global rule in `~/.claude/CLAUDE.md`.

## Flake shape (flake-parts)

Use **flake-parts** for any project with more than one output. Canonical skeleton (mirrors `nixos-runtime-modules/flake.nix`, `ftpilot/flake.nix`, `molesk/flake.nix`):

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, ... } @inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.git-hooks.flakeModule
        inputs.treefmt-nix.flakeModule
        # inputs.flake-parts.flakeModules.easyOverlay  # when shipping an overlay
      ];

      perSystem = { pkgs, config, lib, system, ... }: {
        # treefmt config — see below
        # pre-commit config — see below
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ /* toolchain */ pre-commit ];
          shellHook = config.pre-commit.installationScript;
        };
        packages.default = pkgs.callPackage ./package.nix { };
      };

      flake = {
        nixosModules = { /* when shipping NixOS modules */ };
      };
    };
}
```

Notes:
- `systems = inputs.nixpkgs.lib.systems.flakeExposed;` — never hardcode `[ "x86_64-linux" "aarch64-linux" ]`.
- All `treefmt-nix` / `git-hooks` / overlay inputs follow `nixpkgs` (`.inputs.nixpkgs.follows = "nixpkgs"`). Keeps closure small.
- `inputs.flake-parts.flakeModules.easyOverlay` when the project ships an overlay (see `ftpilot/flake.nix`).

For a trivial single-script project (one shell tool, no devshell complexity), skip flake-parts and use a plain `flake.nix` with explicit `outputs.${system}.{packages,formatter}` (see `gh-dotenv-sync/flake.nix`, `mozid/flake.nix`).

## treefmt config

```nix
treefmt.config = {
  projectRootFile = "flake.nix";
  flakeFormatter = true;
  flakeCheck = true;
  programs = {
    nixpkgs-fmt.enable = true;
    deadnix.enable = true;
    statix.enable = true;
    # add per-language: rustfmt (Rust), prettier (JS), taplo (TOML-heavy)
  };
};
```

`nix fmt` runs treefmt. CI checks it via `flakeCheck = true`. Per-language formatters added in `/tt:context:{rust,javascript}`. Shell-script formatting (`shellcheck`, `shfmt`) is opt-in per project — see `/tt:context:shell` for the snippet — not part of the default Nix stack.

## Pre-commit hooks

```nix
pre-commit.check.enable = false;
pre-commit.settings.hooks = {
  treefmt = {
    enable = true;
    package = config.treefmt.build.wrapper;
  };
  # per-language hooks added in /tt:context:{rust,javascript}
};
```

`pre-commit.check.enable = false` keeps `nix flake check` fast (it doesn't try to run every hook at evaluation time). Hooks fire on `git commit` via the installation script in the devshell `shellHook`.

## NixOS module style

Pattern observed in `nixos-sftp-mount/nixosModules/{sftpClient,sftpServer}.nix`, `nixos-runtime-modules/nixosModules/`, `molesk/module.nix`:

```nix
{ config, lib, ... }:
let cfg = config.services.myThing;
in {
  options.services.myThing = {
    enable = lib.mkEnableOption "myThing service";
    user = lib.mkOption {
      type = lib.types.str;
      default = "mything";
      description = "User to run myThing as.";
    };
    settings = lib.mkOption {
      type = lib.types.submodule {
        options = {
          port = lib.mkOption {
            type = lib.types.port;
            default = 8080;
          };
        };
      };
      default = { };
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.myThing = { /* ... */ };
  };
}
```

Rules:
- `mkEnableOption` for the on/off switch; `mkOption` with explicit `type`, `default`, `description` for everything else.
- All implementation under `config = lib.mkIf cfg.enable { ... }`. Never leak config outside the `mkIf`.
- Submodules for grouped options. Defaults propagate through `cfg.<group>.<option>`.
- Validate at the type system (`lib.types.port`, `lib.types.path`, refinements) where possible.
- For services: hardening defaults (`NoNewPrivileges`, `ProtectSystem = "strict"`, `ProtectHome = true`, dedicated user/group).

## Packaging — the real idiom

Pattern from `nixos-runtime-modules/package.nix`, `levari/package.nix`, `ping-sweep/package.nix`, `nvimkata/package.nix`:

```nix
{ rustPlatform, lib, pkgs, ... }:
let
  manifest = (lib.importTOML ./Cargo.toml).package;
in
rustPlatform.buildRustPackage {
  pname = manifest.name;
  inherit (manifest) version;

  nativeBuildInputs = with pkgs; [ pkg-config ];
  buildInputs = with pkgs; [ /* runtime libs */ ];

  src = lib.sourceByRegex ./. [
    "^Cargo.toml$"
    "^Cargo.lock$"
    "^src.*$"
    "^tests.*$"
  ];

  cargoLock.lockFile = ./Cargo.lock;

  # Tests run in pre-commit, not in nix build
  doCheck = false;
}
```

Key points (verified against real packages):
- `manifest = (lib.importTOML ./Cargo.toml).package;` then `pname = manifest.name; inherit (manifest) version;`. Never hand-maintain `pname`/`version`.
- `sourceByRegex` patterns are **anchored** (`^Cargo.toml$`, `^src.*$`). Faster builds, cleaner closures.
- `doCheck = false` is the default when tests require a non-trivial runtime (nix daemon, network, hardware). Add a one-line comment naming the reason. When tests run cleanly in the sandbox, omit the field and inherit `true`.
- For binaries with runtime tool dependencies: `nativeBuildInputs = [ makeWrapper ];` and `postInstall = '' wrapProgram $out/bin/${pname} --prefix PATH : ${lib.makeBinPath [ /* deps */ ]} ''`.

## `.gitignore` baseline

Every project should ignore:

```
result
result-*
/target
/node_modules
/.direnv
/.envrc.local
```

`result` symlinks from `nix build`; `target` is Cargo's; `node_modules` for Yarn/npm; `.direnv` for direnv's cache.

## `shell.nix` fallback shim

When the project must support non-flake consumers (rare, only when an external tool needs it):

```nix
# shell.nix
(import
  (
    let lock = builtins.fromJSON (builtins.readFile ./flake.lock); in
    fetchTarball {
      url = "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
      sha256 = lock.nodes.flake-compat.locked.narHash;
    }
  )
  { src = ./.; }
).shellNix
```

Add `flake-compat` to inputs:

```nix
flake-compat = {
  url = "github:edolstra/flake-compat";
  flake = false;
};
```

Don't add by reflex; only when a documented consumer needs it (see `levari/shell.nix`).

## README shape

1. **Title + one-sentence purpose.**
2. **Getting Started** — flake input block + minimal usage example.
3. **Modules / Options table** (for NixOS module projects) — bold names, type, default, description.
4. **Examples** — shell session output where helpful.
5. **No CI badges** until a CI workflow actually exists.

## CHANGELOG

`Keep a Changelog` format (keepachangelog.com, current 1.1.0). Sections: `Added / Changed / Deprecated / Removed / Fixed / Security`. SemVer. Versions match the upstream manifest. See `/tt:actions:bump`.

## Gotchas
- `nixpkgs.config.allowUnfree = true` if the project pulls anything proprietary; document why per project.
- `accept-flake-config = true` belongs in user `nix.conf`, not in the project flake.
- `pure-eval = false` is acceptable for development workflows; flag it if a downstream consumer needs purity.
- `rust-toolchain.toml` shipped alongside a Nix toolchain disagrees silently. Either don't ship one, or pin it from the flake.
- Treefmt's `programs.X.enable` is package-resolved; if a formatter isn't on the system, the build fails — that's intended (one source of truth).
