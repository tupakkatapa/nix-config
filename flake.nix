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
    devenv.url = "github:cachix/devenv";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    # Secret management
    agenix.url = "github:ryantm/agenix";
    agenix-rekey.url = "github:oddlama/agenix-rekey";
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";

    # Hyprland
    hyprland-plugins.inputs.nixpkgs.follows = "nixpkgs";
    hyprland-plugins.url = "github:hyprwm/hyprland-plugins";
    hyprwm-contrib.inputs.nixpkgs.follows = "nixpkgs";
    hyprwm-contrib.url = "github:hyprwm/contrib";

    # Netboot stuff
    nixie.url = "git+ssh://git@github.com/majbacka-labs/nixie?ref=jesse/dev31";
    runtime-modules.url = "github:tupakkatapa/nixos-runtime-modules";
    sftp-mount.url = "github:tupakkatapa/nixos-sftp-mount";
    store-remount.url = "github:ponkila/nixos-store-remount";

    # Other
    coditon-md.url = "github:tupakkatapa/coditon-md";
    levari.url = "github:tupakkatapa/levari";
    mozid.url = "github:tupakkatapa/mozid";
    ping-sweep.url = "github:tupakkatapa/ping-sweep";
    nix-extras.url = "git+https://git.sr.ht/~dblsaiko/nix-extras";
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
            "2mp3" = pkgs.callPackage ./packages/2mp3 { };
            "monitor-adjust" = pkgs.callPackage ./packages/monitor-adjust { };
            "pinit" = pkgs.callPackage ./packages/pinit { };
            "pipewire-out-switcher" = pkgs.callPackage ./packages/pipewire-out-switcher { };
            "tt-utils" = pkgs.callPackage ./packages/tt-utils { };
            # Wofi scripts
            "dm-pipewire-out-switcher" = pkgs.callPackage ./packages/wofi-scripts/dm-pipewire-out-switcher { };
            "dm-radio" = pkgs.callPackage ./packages/wofi-scripts/dm-radio { };
            # Notify scripts
            "notify-brightness" = pkgs.callPackage ./packages/notify-scripts/notify-brightness { };
            "notify-not-hyprprop" = pkgs.callPackage ./packages/notify-scripts/notify-not-hyprprop { };
            "notify-pipewire-out-switcher" = pkgs.callPackage ./packages/notify-scripts/notify-pipewire-out-switcher { };
            "notify-screenshot" = pkgs.callPackage ./packages/notify-scripts/notify-screenshot { };
            "notify-volume" = pkgs.callPackage ./packages/notify-scripts/notify-volume { };
            # Inputs
            inherit (inputs'.levari.packages) levari;
            inherit (inputs'.nixie.packages) lkddb-filter;
            inherit (inputs'.nixie.packages) pxe-generate;
            inherit (inputs'.nixie.packages) refind-generate;
            inherit (inputs'.ping-sweep.packages) ping-sweep;
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
              deadnix.enable = true;
              nixpkgs-fmt.enable = true;
              rustfmt.enable = true;
              shfmt.enable = true;
              statix.enable = true;
            };
          };

          # Development shell -> 'nix develop' or 'direnv allow'
          devenv.shells.default = {
            packages = [
              config.agenix-rekey.package
            ];
            env = {
              NIX_CONFIG = ''
                accept-flake-config = true
                extra-experimental-features = flakes nix-command
                warn-dirty = false
              '';
            };
            git-hooks.hooks.treefmt = {
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
              "torgue" = torgue.config.system.build.kexecTree;
              "vladof" = vladof.config.system.build.kexecTree;
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

          # Create lib instance with custom helpers
          customLib = import ./library { inherit (inputs.nixpkgs) lib; };

          # Base configuration applied to all hosts
          withDefaults = config: {
            specialArgs = {
              inherit inputs outputs customLib;
              unstable = import inputs.nixpkgs-unstable {
                system = config.system or "x86_64-linux";
                config.allowUnfree = true;
              };
            };
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
                system.stateVersion = "25.05";
              }
            ];
          };

          # Optional additional modules
          withExtra = config: {
            modules = config.modules or [ ] ++ [
              inputs.agenix-rekey.nixosModules.default
              inputs.agenix.nixosModules.default
              inputs.home-manager.nixosModules.home-manager
              inputs.nix-extras.nixosModules.common
              inputs.nixie.nixosModules.refindGenerate
              inputs.runtime-modules.nixosModules.runtimeModules
              inputs.store-remount.nixosModules.storeRemount
              inputs.sftp-mount.nixosModules.sftpClient
              self.nixosModules.stateSaver
              ({ config, ... }: {
                home-manager = {
                  sharedModules = [
                    inputs.nixvim.homeManagerModules.nixvim
                    inputs.nix-index-database.hmModules.nix-index
                    {
                      programs.nix-index.enable = true;
                      programs.nix-index-database.comma.enable = true;
                    }
                  ];
                  extraSpecialArgs = {
                    inherit (config.networking) hostName;
                    inherit customLib;
                    inherit (inputs) mozid;
                    unstable = import inputs.nixpkgs-unstable {
                      system = config.system or "x86_64-linux";
                      config.allowUnfree = true;
                    };
                  };
                  useGlobalPkgs = true;
                };
                age.rekey = {
                  masterIdentities = [{
                    identity = ./master.hmac;
                    pubkey = "age19xu98r52uq33f7lu5z6zafysvnx9snq72x3j6gtcvkd0a8ew8q9q34nw3u";
                  }];
                };
              })
            ];
          };

          # Hosts
          torgue = withExtra {
            modules = [
              ./home-manager/users/kari
              ./nixosConfigurations/torgue
              ./system/kexec-tree.nix
            ];
          };

          vladof = withExtra {
            modules = [
              ./home-manager/users/kari/minimal-gui.nix
              ./nixosConfigurations/vladof
              ./system/kexec-tree.nix
              inputs.coditon-md.nixosModules.default
              inputs.nixie.nixosModules.nixie
              inputs.sftp-mount.nixosModules.sftpServer
            ];
          };

          maliwan = withExtra {
            modules = [
              ./home-manager/users/kari
              ./nixosConfigurations/maliwan
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
              "bandit" = nixosSystem (withDefaults bandit);
              "maliwan" = nixosSystem (withDefaults maliwan);
              "torgue" = nixosSystem (withDefaults torgue);
              "vladof" = nixosSystem (withDefaults vladof);
            };

          # NixOS modules
          nixosModules = {
            autoScrcpy.imports = [ ./nixosModules/auto-scrcpy.nix ];
            rsyncBackup.imports = [ ./nixosModules/rsync-backup.nix ];
            stateSaver.imports = [ ./nixosModules/state-saver.nix ];
          };
        };
    };
}
