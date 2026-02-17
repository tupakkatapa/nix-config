# nix-config

Tupakkatapa's NixOS flake. Five ephemeral netboot hosts, two users, Hyprland desktop, nixvim, fish shell, foot terminal. All hosts are truly declarative — they boot from network images built by Nixie (closed-source DHCP/PXE at `github:majbacka-labs/nixie`), making them stateless except for explicitly persisted paths.

## Commands

```bash
# Build and test locally (does NOT persist across reboot on ephemeral hosts)
sudo nixos-rebuild test --impure --flake path:~/nix-config#$(hostname) --accept-flake-config

# Format all nix/shell files
nix fmt

# Enter devshell (also via direnv)
nix develop

# Rekey secrets after adding host or changing master keys
agenix-rekey -a

# Build a kexecTree image for a host
nix build .#<hostname>

# Remote rebuild
nixos-rebuild test --impure --ask-sudo-password --sudo --flake .#<hostname> --target-host <user>@<ip>

# Garbage collect (local)
nix-collect-garbage --delete-older-than 7d
```

## Architecture

**Flake-parts** based. Entry point: `flake.nix`. Two composition helpers:
- `withDefaults` — base system: kernel, locale, openssh, nix settings, overlays, stateVersion
- `withExtra` — adds: home-manager, agenix secrets, nixvim, nix-index, nixie modules, runtime-modules, monitoring, claude-code homeModule

All hosts get `withDefaults`. Desktop/server hosts additionally get `withExtra`.

### Hosts

| Host | User | Role | Deploy | Key modules |
|------|------|------|--------|-------------|
| `torgue` | kari | AMD desktop, Hyprland | netboot | gaming-amd, pipewire, podman, runtime-modules |
| `maliwan` | kari | AMD laptop, Hyprland | refind | gaming-amd, pipewire, podman |
| `vladof` | kari (minimal-gui) | Homelab, Firefox kiosk | netboot | nixie, molesk, sftp-server, services/* |
| `hyperion` | core (minimal) | Router + Nixie netboot server | refind | nixie, dns, firewall, wireguard |
| `bandit` | core (minimal) | Headless minimal | netboot | (bare minimum) |

### Directory structure

```
flake.nix                          # Entry point, host definitions, withDefaults/withExtra
system/                            # Shared NixOS base configs (base.nix, openssh.nix, nix-settings.nix, kexec-tree.nix)
library/                           # customLib: hyprland helpers, xdg mime helpers, base16 color schemes
nixosConfigurations/<host>/        # Host-specific: hardware, networking, persistence, services
  .config/                         # Shared NixOS modules (gaming-amd, pipewire, podman, keyd, yubikey, tuigreet-hypr, ai-tools)
nixosModules/                      # Reusable NixOS modules (monitoring, state-saver, auto-scrcpy)
homeModules/                       # Reusable HM modules (claude-code plugin system)
home-manager/
  users/<user>/                    # User configs, layered: minimal → minimal-passwd → minimal-gui → default
    .config/                       # Per-app HM configs (fish, neovim, tmux, foot, yazi, git, claude/, firefox/)
  hosts/<host>/                    # Host-specific HM (conditionally imported if path exists)
    .config/base01/                # Shared graphical "rice" (hyprland, waybar, wofi, mako, gtk, foot theme, nixvim theme)
      rice01/                      # Current rice variant (colors, wallpaper, animations)
packages/                          # Custom packages (kb-shortcuts, monitor-adjust, pinit, 2mp3, claude-plugins, chroma-mcp, fat-nix-deps)
docs/                              # Setup guides (new host, yubikey, fido2-luks)
```

### User config layering

`kari` user configs extend incrementally:
1. `minimal.nix` — user account, fish shell, groups, SSH keys, direnv, git, neovim (nixvim), tmux, yazi. Conditionally imports host-specific HM config if `home-manager/hosts/<hostname>/` exists.
2. `minimal-passwd.nix` — extends minimal. Adds agenix secrets, wireguard, SSH match blocks, SFTP mounts, git signing.
3. `minimal-gui.nix` — extends minimal. Adds foot, firefox, mpv, imv, fonts, session variables (BROWSER, TERMINAL, THEME, FONT).
4. `default.nix` — extends minimal-passwd + minimal-gui. Adds claude-code config, xdg mimes, Hyprland startup programs, android dev.

`core` user is defined inline in `core/minimal.nix` with fish, eza, neovim, and passwordless sudo. No home-manager.

### Key patterns

- **Session variables drive theming**: `THEME`, `BROWSER`, `TERMINAL`, `FILEMANAGER`, `FONT` set per-user, rice adapts via `customLib.colors.${THEME}`.
- **customLib** injected via `specialArgs` to all modules. Contains: `customLib.hyprland.{generateMonitors, generateWorkspaces, generateWorkspaceBindings}`, `customLib.xdg.createMimes`, `customLib.colors.<scheme>`.
- **Conditional host HM import**: `optionalPaths [ ../../hosts/${config.networking.hostName}/default.nix ]` — only imports if the path exists.
- **kexecTree**: All hosts build a kexec-bootable squashfs image via `system/kexec-tree.nix` with overlay root filesystem.
- **Runtime modules**: `torgue` uses `services.runtimeModules` to toggle configs (retroarch, ai-tools, daw) at runtime without rebuild.
- **Persistence**: Ephemeral hosts use `state-saver` module + host-specific `persistence.nix` to bind-mount persistent data from attached drives.
- **Secrets**: agenix + agenix-rekey with FIDO2 HMAC age plugins. Master identity keys are `master.hmac` and `master-2.hmac` in repo root.

## Stack specifics

**Shell**: Fish with vi keybindings. Abbreviations, not aliases. `q` = exit, `c` = clear, `buidl` = nixos-rebuild test.

**Terminal**: Foot (Wayland-native, xterm-256color, dpi-aware).

**WM**: Hyprland. Mod key is `ALT` (not SUPER). SUPER is used for programs (B=browser, F=filemanager, V=editor). Navigation: `ALT+H/J/K/L`. Workspaces: `ALT+0-9`. Submap `ALT+S` for TUI apps.

**Editor**: Nixvim (neovim via nix-community/nixvim). Leader = Space. Neo-tree (`<leader>e`), Telescope (`<leader>ff`, `<leader>fg`), LazyGit (`<leader>g`), BufferLine (Tab/S-Tab), cmp with tmux source. LSP: bashls, nixd.

**Tmux**: Prefix `C-Space`, vi mode, mouse on. Splits: `v` (horizontal), `g` (vertical). Minimal status bar.

**File manager**: Yazi with fish integration, smart-enter plugin, jump-to-char. Also zathura for PDFs.

**Secrets**: agenix-rekey. Hardware keys: YubiKey (ed25519-sk), Trezor (ed25519-sk, GPG). SSH agent with fish integration.

**Networking**: systemd-networkd everywhere, iwd for WiFi. WireGuard tunnels (`home`, `dinar`) for VPN to `hyperion` (router at coditon.com). Internal network `10.42.0.0/24`.

**SFTP**: vladof serves SFTP. Desktop hosts mount via `services.sftpClient` to `/mnt/sftp`, then bind-mount to `~/Documents`, `~/Media`, `~/Downloads/remote`, `~/Workspace/remote`.

## Related repositories

- **Nixie** (closed-source): `github:majbacka-labs/nixie` — DHCP/PXE netboot module. Local: `~/Workspace/{local,remote}/nixie`. Current branch: `jesse/dev31`.
- **nixos.fi** (informational): `github:majbacka-labs/nixos.fi` — Public docs about the Nixie netboot approach.
- **nixos-runtime-modules**: `github:tupakkatapa/nixos-runtime-modules` — Toggle NixOS module configurations at runtime.
- **nixos-sftp-mount**: `github:tupakkatapa/nixos-sftp-mount` — NixOS module for SFTP server/client mounting.
- **mozid**: `github:tupakkatapa/mozid` — Firefox extension ID resolver (CLI + Nix lib).

## Code style

- Formatter: `nix fmt` runs treefmt with nixpkgs-fmt, deadnix, statix, shellcheck, shfmt.
- Pre-commit hooks configured but `check.enable = false` (manual via `pre-commit run`).
- Nix files: 2-space indent, nixpkgs-fmt style. Use `let/in` blocks, avoid `with pkgs;` in most places (explicit `pkgs.` preferred except `home.packages`).
- New packages go in `packages/`, new NixOS modules in `nixosModules/`, new HM modules in `homeModules/`.
- Host naming: Borderlands gun manufacturers (torgue, maliwan, vladof, hyperion, bandit).
- NEVER suggest `apt install`, `brew install`, or `pip install`. Use `nix-shell -p` for temporary, add to config for permanent.

## Gotchas

- `users.mutableUsers = false` — passwords must be set declaratively or via agenix.
- Hosts are **ephemeral**. `nixos-rebuild test` does NOT survive reboot. Changes must be committed and images rebuilt/kexec'd to persist.
- `nixpkgs.config.allowUnfree = true` is set globally.
- `pure-eval = false` and `accept-flake-config = true` — impure evaluation is intentional for development workflow.
- `nix-access-tokens` secret provides GitHub API tokens to avoid rate limits.
- Blog content under `nixosConfigurations/vladof/services/blog-contents` is all rights reserved (rest is GPL-3.0).
- `.gitignore` ignores `.claude` and `**/CLAUDE.md` except root and kari's claude config CLAUDE.md.
- The `claude` fish abbreviation wraps claude-code in a tmux session: `tmux new-session 'claude -c'`.
