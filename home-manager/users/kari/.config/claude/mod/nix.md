# Nix project & module context (tupakkatapa house style)

Conventions from `~/Workspace/tupakkatapa/{nixos-runtime-modules,nixos-tpm-host-key,molesk,kaloriina,anytui,ftpilot,nvimkata,ping-sweep,mozid,gh-envsync}`. Use this when planning, scaffolding, or reviewing any Nix-heavy project. Per-project `./CLAUDE.md` may override anything here.

## Philosophy
- **Declarative over imperative.** No global state outside the Nix store. Configuration is data; reload by rebuild, not by mutation.
- **Pin to a stable release.** `github:NixOS/nixpkgs/nixos-26.05` is the current default. `nixos-unstable` only when a project needs a feature not yet in stable; say why in the README.
- **One devshell, one source of truth.** The devshell defines the build/test/format toolchain; pre-commit runs the same tools.
- **No CI workflows; `nix flake check` and the pre-commit hooks are the gate.** No project has GitHub Actions. If CI is added, it runs `nix flake check`.

Other contexts: shell `~/.claude/tt/mod/sh.md`, Rust `~/.claude/tt/mod/rs.md`, JS `~/.claude/tt/mod/js.md`. Lint suppressions (`# statix:ignore`, `# deadnix: skip`) follow the global rule in `~/.claude/CLAUDE.md`.

## Flake shape (flake-parts)

Use **flake-parts** for any project with a devshell, hooks or more than one output. Skeleton common to `nixos-runtime-modules/flake.nix`, `molesk/flake.nix`, `kaloriina/flake.nix`, `anytui/flake.nix`, `nixos-tpm-host-key/flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, ... }@inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.git-hooks.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

      perSystem = { self', pkgs, config, lib, ... }: {
        # treefmt, pre-commit: see below
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ /* toolchain */ pre-commit ];
          shellHook = config.pre-commit.installationScript;
        };
        packages = {
          <name> = pkgs.callPackage ./package.nix { };
          default = self'.packages.<name>;
        };
        checks = { /* see Checks */ };
      };

      flake.nixosModules = {
        <name> = import ./module.nix;
        default = self.nixosModules.<name>;
      };
    };
}
```

- `systems = inputs.nixpkgs.lib.systems.flakeExposed` is the default (7 of 8 flake-parts projects). Exception: a project tied to Linux hardware lists its systems (`nixos-tpm-host-key`: `[ "x86_64-linux" "aarch64-linux" ]`).
- `treefmt-nix` and `git-hooks` follow `nixpkgs`.
- Projects that ship an overlay import `inputs.flake-parts.flakeModules.easyOverlay` and set `overlayAttrs` (`anytui/flake.nix`, `ftpilot/flake.nix`, `nvimkata/flake.nix`).
- A single-script tool may use a plain flake with `packages.${system}` built by `nixpkgs.lib.genAttrs` (`mozid/flake.nix`, `gh-envsync/flake.nix`; both list four systems by hand and have no formatter or hooks). New projects use the flake-parts skeleton.

## treefmt

From `nixos-runtime-modules/flake.nix`:

```nix
treefmt.config = {
  projectRootFile = "flake.nix";
  flakeFormatter = true;
  flakeCheck = true;
  programs = {
    nixpkgs-fmt.enable = true;
    deadnix.enable = true;
    statix.enable = true;
  };
};
```

`nix fmt` runs treefmt; `flakeCheck = true` puts it in `nix flake check`. Per language: `rustfmt` and `taplo` (Rust), `prettier` (JS), `shellcheck` and `shfmt` (shell, as in `nixos-tpm-host-key/flake.nix`). Exclude input data and vendored files from formatting (`settings.formatter.prettier.excludes` in molesk, `settings.global.excludes` in kaloriina).

## Pre-commit hooks

Same in every flake-parts project:

```nix
pre-commit.check.enable = false;
pre-commit.settings.hooks = {
  treefmt = {
    enable = true;
    package = config.treefmt.build.wrapper;
  };
};
```

`check.enable = false` keeps the hooks out of `nix flake check`; they fire on `git commit` through the devshell's `shellHook`. Language hooks are in `rs.md` and `js.md`. `.pre-commit-config.yaml` is generated; ignore it.

## Checks

`nix flake check` carries what runs in the sandbox:
- Lint and unit tests as derivations, sharing the command string with the pre-commit hook (`lint` and `unit` in `molesk/flake.nix`; `webLint`/`webUnit` in `kaloriina/flake.nix`).
- NixOS VM tests for a module, via `pkgs.testers.runNixOSTest`, Linux only (`molesk/tests/module.nix`, `kaloriina/flake.nix`, `nixos-tpm-host-key/tests/vm.nix`).
- Package tests exposed as `passthru.tests` and listed in `checks` (`nixos-tpm-host-key/packages/tpm-host-key/default.nix`).
- Module evaluation checks (`nixos-runtime-modules/flake.nix`).

## NixOS module style

Shape of `molesk/module.nix` (also `kaloriina/module.nix`, `nixos-runtime-modules/nixosModules/default.nix`):

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.services.<name>;
in
{
  options.services.<name> = {
    enable = lib.mkEnableOption "<name>";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
      description = "The <name> package to run.";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port to listen on.";
    };
    openFirewall = lib.mkOption { /* bool, default false */ };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.<name> = { /* ... */ };
    networking.firewall = lib.mkIf cfg.openFirewall { /* ... */ };
  };
}
```

- `mkEnableOption` for the switch; `mkOption` with `type`, `default`, `description` for the rest.
- All implementation under `config = lib.mkIf cfg.enable`.
- Validate with types (`lib.types.port`, `lib.types.package`).
- The firewall opens only on `openFirewall`.
- Build `ExecStart` with `utils.escapeSystemdExecArgs` (molesk), not string concatenation.
- Harden services: dedicated user and group, `NoNewPrivileges = true`, `ProtectSystem = "strict"`, `ProtectHome = true` (kaloriina) or `"tmpfs"` with `BindReadOnlyPaths` when the service reads paths under home (molesk), plus the `Protect*`/`Restrict*` set in `molesk/module.nix`.

## Packaging

- Derive `pname` and `version` from the manifest (`lib.importTOML ./Cargo.toml`, `lib.importJSON ./package.json`); never hand-maintain them. Rust: `rs.md`. JS: `js.md`. Shell: `sh.md`.
- Limit `src`: `lib.sourceByRegex` with anchored patterns (Rust packages) or `lib.fileset.toSource` (`molesk/package.nix`, checks in kaloriina).
- Runtime tools reach a binary through `makeWrapper` and `wrapProgram --prefix PATH : ${lib.makeBinPath [ ... ]}`.
- `meta` carries `description`, `license`, `mainProgram` (molesk, kaloriina, tpm-host-key).

## `.gitignore` baseline

Most common entries across the projects:

```
result
.direnv
.pre-commit-config.yaml
```

Plus per language: `target/` (Rust); `node_modules`, `/test-results/`, `/playwright-report/` (JS).

## README shape

1. Title and one-sentence purpose.
2. Getting Started: flake input block and minimal usage.
3. Options table for NixOS module projects.
4. Examples, with shell output where helpful.
5. No CI badges.

Released projects keep a `CHANGELOG.md` (see `/tt:act:changelog`, `/tt:act:bump`). Plans live in `docs/plans/`.

## Gotchas
- `accept-flake-config = true` belongs in user `nix.conf`, not in the project flake.
- A treefmt formatter comes from nixpkgs at the pinned revision, not from the system.
- Do not ship a `rust-toolchain.toml`; the flake's nixpkgs pin sets the toolchain.
