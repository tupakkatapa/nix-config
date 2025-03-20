# https://github.com/Misterio77/nix-config
# https://github.com/jhvst/nix-config
{
  description = "Tupakkatapa's flake";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
    ];
    extraOptions = ''
      download-attempts = 3
      connect-timeout = 5
      fallback = true
    '';
  };

  inputs = {
    devenv.url = "github:cachix/devenv?ref=v1.3.1"; # https://github.com/cachix/devenv/issues/1733
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    # Secret management
    agenix.url = "github:ryantm/agenix";
    agenix-rekey.url = "github:oddlama/agenix-rekey";
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";

    # Hyprland
    hyprwm-contrib.inputs.nixpkgs.follows = "nixpkgs";
    hyprwm-contrib.url = "github:hyprwm/contrib";
    hyprland-plugins.url = "github:hyprwm/hyprland-plugins";
    hyprland-plugins.inputs.nixpkgs.follows = "nixpkgs";

    # Games
    aagl.inputs.nixpkgs.follows = "nixpkgs";
    aagl.url = "github:ezKEa/aagl-gtk-on-nix";

    # Netboot stuff
    nixie.url = "git+ssh://git@github.com/majbacka-labs/nixie\?ref=jesse/bugs";

    # Index
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # Other
    musnix.url = "github:musnix/musnix";
    musnix.inputs.nixpkgs.follows = "nixpkgs";
    nix-extras.url = "git+https://git.sr.ht/~dblsaiko/nix-extras";
    coditon-md.url = "github:tupakkatapa/coditon-md";
    mozid.url = "github:tupakkatapa/mozid";
    levari.url = "github:tupakkatapa/levari";
    sftp-mount.url = "github:tupakkatapa/sftp-mount";
    runtime-modules.url = "github:tupakkatapa/nixos-runtime-modules";
  };

  outputs = { self, ... }@inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } rec {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.agenix-rekey.flakeModule
        inputs.devenv.flakeModule
        inputs.flake-parts.flakeModules.easyOverlay
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        { pkgs
        , config
        , system
        , inputs'
        , ...
        }:
        let
          packages = {
            "tt-utils" = pkgs.callPackage ./packages/tt-utils { };
            "monitor-adjust" = pkgs.callPackage ./packages/monitor-adjust { };
            "ping-sweep" = pkgs.callPackage ./packages/ping-sweep { };
            "pipewire-out-switcher" = pkgs.callPackage ./packages/pipewire-out-switcher { };
            "pinit" = pkgs.callPackage ./packages/pinit { };
            "2mp3" = pkgs.callPackage ./packages/2mp3 { };
            # Wofi scripts
            "dm-pipewire-out-switcher" = pkgs.callPackage ./packages/wofi-scripts/dm-pipewire-out-switcher { };
            "dm-radio" = pkgs.callPackage ./packages/wofi-scripts/dm-radio { };
            # Notify scripts
            "notify-brightness" = pkgs.callPackage ./packages/notify-scripts/notify-brightness { };
            "notify-screenshot" = pkgs.callPackage ./packages/notify-scripts/notify-screenshot { };
            "notify-volume" = pkgs.callPackage ./packages/notify-scripts/notify-volume { };
            "notify-pipewire-out-switcher" = pkgs.callPackage ./packages/notify-scripts/notify-pipewire-out-switcher { };
            "notify-not-hyprprop" = pkgs.callPackage ./packages/notify-scripts/notify-not-hyprprop { };
            # Inputs
            inherit (inputs'.nixie.packages) lkddb-filter;
            inherit (inputs'.nixie.packages) pxe-generate;
            inherit (inputs'.mozid.packages) mozid;
            inherit (inputs'.levari.packages) levari;
            inherit (inputs'.hyprland-plugins.packages) hyprbars;
          };
        in
        {
          # Overlays
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              self.overlays.default
            ];
            config = { };
          };
          overlayAttrs = packages;

          # Nix code formatter -> 'nix fmt'
          treefmt.config = {
            projectRootFile = "flake.nix";
            flakeFormatter = true;
            flakeCheck = true;
            programs = {
              nixpkgs-fmt.enable = true;
              deadnix.enable = true;
              statix.enable = true;
              rustfmt.enable = true;
            };
          };

          # Development shell -> 'nix develop' or 'direnv allow'
          devenv.shells.default = {
            packages = [ config.agenix-rekey.package ];
            env = {
              NIX_CONFIG = ''
                accept-flake-config = true
                extra-experimental-features = flakes nix-command
                warn-dirty = false
              '';
            };
            pre-commit.hooks.treefmt = {
              enable = true;
              package = config.treefmt.build.wrapper;
            };
            # Workaround for https://github.com/cachix/devenv/issues/760
            containers = pkgs.lib.mkForce { };
          };

          # Custom packages and entrypoint aliases -> 'nix run' or 'nix build'
          packages =
            (with flake.nixosConfigurations; {
              "bandit" = bandit.config.system.build.kexecTree;
              "vladof" = vladof.config.system.build.kexecTree;
              "torgue" = torgue.config.system.build.kexecTree;
            })
            // packages;

          # Whitelist hosts using agenix-rekey
          agenix-rekey.nixosConfigurations = {
            inherit (self.nixosConfigurations)
              torgue
              vladof
              maliwan
              ;
          };
        };
      flake =
        let
          inherit (self) outputs;

          # Base configuration applied to all hosts
          withDefaults = config: {
            specialArgs = { inherit inputs outputs; };
            system = config.system or "x86_64-linux";
            modules = config.modules or [ ] ++ [
              ./system/base.nix
              ./system/minimal.nix
              ./system/nix-settings.nix
              ./system/openssh.nix
              {
                nixpkgs.overlays = [
                  self.overlays.default
                ];
                system.stateVersion = "24.11";
              }
            ];
          };

          # Optional additional modules
          withExtra = config: {
            modules = config.modules or [ ] ++ [
              inputs.agenix-rekey.nixosModules.default
              inputs.agenix.nixosModules.default
              inputs.home-manager.nixosModules.home-manager
              inputs.runtime-modules.nixosModules.runtimeModules
              inputs.sftp-mount.nixosModules.sftpClient
              self.nixosModules.stateSaver
              {
                home-manager.sharedModules = [
                  inputs.nixvim.homeManagerModules.nixvim
                  inputs.nix-index-database.hmModules.nix-index
                  {
                    programs.nix-index.enable = true;
                    programs.nix-index-database.comma.enable = true;
                  }
                ];
                age.rekey = {
                  masterIdentities = [{
                    identity = ./master.hmac;
                    pubkey = "age19xu98r52uq33f7lu5z6zafysvnx9snq72x3j6gtcvkd0a8ew8q9q34nw3u";
                  }];
                };
              }
            ];
          };

          # Hosts
          torgue = withExtra {
            modules = [
              ./home-manager/users/kari
              ./nixosConfigurations/torgue
              ./system/kexec-tree.nix
              inputs.aagl.nixosModules.default
              inputs.musnix.nixosModules.musnix
              inputs.nixie.nixosModules.nixRemount
              inputs.nixie.nixosModules.refindGenerate
              inputs.nixos-hardware.nixosModules.common-gpu-amd
            ];
          };

          vladof = withExtra {
            modules = [
              ./home-manager/users/kari/minimal-gui.nix
              ./nixosConfigurations/vladof
              ./system/kexec-tree.nix
              inputs.coditon-md.nixosModules.default
              inputs.nix-extras.nixosModules.common
              inputs.nixie.nixosModules.nixRemount
              inputs.nixie.nixosModules.refindGenerate
              inputs.nixie.nixosModules.nixie
              inputs.nixos-hardware.nixosModules.common-gpu-intel
              inputs.sftp-mount.nixosModules.sftpServer
            ];
          };

          maliwan = withExtra {
            modules = [
              ./home-manager/users/kari
              ./nixosConfigurations/maliwan
              inputs.nixos-hardware.nixosModules.common-gpu-intel
            ];
          };

          bandit.modules = [
            ./home-manager/users/core/minimal.nix
            ./nixosConfigurations/bandit
            ./system/kexec-tree.nix
          ];
        in
        {
          # NixOS configuration entrypoints
          nixosConfigurations = with inputs.nixpkgs.lib;
            {
              "maliwan" = nixosSystem (withDefaults maliwan);
              "torgue" = nixosSystem (withDefaults torgue);
              "vladof" = nixosSystem (withDefaults vladof);
              "bandit" = nixosSystem (withDefaults bandit);
            };

          # NixOS modules
          nixosModules = {
            stateSaver.imports = [ ./nixosModules/state-saver.nix ];
            autoScrcpy.imports = [ ./nixosModules/auto-scrcpy.nix ];
            rsyncBackup.imports = [ ./nixosModules/rsync-backup.nix ];
          };
        };
    };
}
