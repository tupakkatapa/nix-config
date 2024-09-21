# https://github.com/Misterio77/nix-config
# https://github.com/jhvst/nix-config
{
  description = "Tupakkatapa's flake";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    extraOptions = ''
      download-attempts = 3
      connect-timeout = 5
      fallback = true
    '';
  };

  inputs = {
    agenix.url = "github:ryantm/agenix";
    devenv.url = "github:cachix/devenv";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    # Hyprland
    hyprwm-contrib.inputs.nixpkgs.follows = "nixpkgs";
    hyprwm-contrib.url = "github:hyprwm/contrib";

    # Genshin Impact
    aagl.inputs.nixpkgs.follows = "nixpkgs";
    aagl.url = "github:ezKEa/aagl-gtk-on-nix";

    # Netboot stuff
    nixie.url = "git+ssh://git@github.com/majbacka-labs/nixie\?ref=jesse/bugs";
    homestakeros-base.url = "github:ponkila/HomestakerOS\?dir=nixosModules/base";

    # Index
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # Other
    musnix.url = "github:musnix/musnix";
    musnix.inputs.nixpkgs.follows = "nixpkgs";
    nix-extras.url = "git+https://git.sr.ht/~dblsaiko/nix-extras";
    coditon-md.url = "github:tupakkatapa/coditon-md";
    mozid.url = "github:tupakkatapa/mozid";
  };

  outputs = { self, ... }@inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } rec {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      imports = [
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
            "tupakkatapa-utils" = pkgs.callPackage ./packages/tupakkatapa-utils { };
            "monitor-adjust" = pkgs.callPackage ./packages/monitor-adjust { };
            "ping-sweep" = pkgs.callPackage ./packages/ping-sweep { };
            "pipewire-out-switcher" = pkgs.callPackage ./packages/pipewire-out-switcher { };
            "pinit" = pkgs.callPackage ./packages/pinit { };
            "musrand" = pkgs.callPackage ./packages/musrand { };
            # Wofi scripts
            "dm-pipewire-out-switcher" = pkgs.callPackage ./packages/wofi-scripts/dm-pipewire-out-switcher { };
            "dm-quickfile" = pkgs.callPackage ./packages/wofi-scripts/dm-quickfile { };
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
            inherit (inputs'.agenix.packages) agenix;
            inherit (inputs'.mozid.packages) mozid;

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
            };
          };

          # Development shell -> 'nix develop' or 'direnv allow'
          devenv.shells.default = {
            packages = with pkgs; [
              ssh-to-age
              pxe-generate
              nix-tree
              agenix
              mozid
              lkddb-filter
              pinit
            ];
            env = {
              NIX_CONFIG = ''
                accept-flake-config = true
                extra-experimental-features = flakes nix-command
                warn-dirty = false
              '';
            };
            pre-commit.hooks = {
              rustfmt.enable = false;
              # shellcheck.enable = true;
              treefmt = {
                enable = true;
                package = config.treefmt.build.wrapper;
              };
            };
            # Workaround for https://github.com/cachix/devenv/issues/760
            containers = pkgs.lib.mkForce { };
          };

          # Custom packages and entrypoint aliases -> 'nix run' or 'nix build'
          packages =
            (with flake.nixosConfigurations; {
              "bandit" = bandit.config.system.build.kexecTree;
              "gearbox" = gearbox.config.system.build.kexecTree;
              "eridian" = eridian.config.system.build.kexecTree;
              # "jakobs" = jakobs.config.system.build.kexecTree;
              "vladof" = vladof.config.system.build.kexecTree;
              "torgue" = torgue.config.system.build.kexecTree;
            })
            // packages;
        };
      flake =
        let
          inherit (self) outputs;

          # Base configuration applied to all hosts
          withDefaults = config: {
            specialArgs = { inherit inputs outputs; };
            system = config.system or "x86_64-linux";
            modules = config.modules or [ ] ++ [
              inputs.nix-extras.nixosModules.all
              ./system/base.nix
              ./system/nix-settings.nix
              ./system/openssh.nix
              {
                nixpkgs.overlays = [
                  self.overlays.default
                ];
                system.stateVersion = "24.05";
              }
            ];
          };

          # Optional additional modules
          withExtra = config: {
            modules = config.modules or [ ] ++ [
              inputs.agenix.nixosModules.default
              inputs.home-manager.nixosModules.home-manager
              self.nixosModules.sftpClient
              {
                home-manager.sharedModules = [
                  inputs.nixvim.homeManagerModules.nixvim
                  inputs.nix-index-database.hmModules.nix-index
                  {
                    programs.nix-index.enable = true;
                    programs.nix-index-database.comma.enable = true;
                  }
                ];
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
              inputs.nixos-hardware.nixosModules.common-gpu-amd
              self.nixosModules.autoScrcpy
            ];
          };

          vladof = withExtra {
            modules = [
              ./home-manager/users/kari/minimal-gui.nix
              ./nixosConfigurations/vladof
              ./system/kexec-tree.nix
              inputs.coditon-md.nixosModules.default
              # inputs.homestakeros-base.nixosModules.kexecTree
              inputs.nixos-hardware.nixosModules.common-gpu-intel
              inputs.nixie.nixosModules.nixie
            ];
          };

          eridian = withExtra {
            modules = [
              ./home-manager/users/kari/minimal.nix
              ./nixosConfigurations/eridian
              ./system/kexec-tree.nix
              inputs.nixie.nixosModules.nixie
              # inputs.homestakeros-base.nixosModules.kexecTree
            ];
          };

          maliwan = withExtra {
            modules = [
              ./home-manager/users/kari/minimal-gui.nix
              ./nixosConfigurations/maliwan
              inputs.nixos-hardware.nixosModules.common-gpu-intel
            ];
          };

          bandit.modules = [
            ./nixosConfigurations/bandit
            ./home-manager/users/core
            ./system/kexec-tree.nix
            # inputs.homestakeros-base.nixosModules.kexecTree
          ];

          gearbox.modules = [
            ./nixosConfigurations/gearbox
            ./home-manager/users/core
            ./system/kexec-tree.nix
            # inputs.homestakeros-base.nixosModules.kexecTree
            inputs.nixos-hardware.nixosModules.common-gpu-intel
          ];

          # jakobs = withExtra {
          #   system = "aarch64-linux";
          #   modules = [
          #     ./home-manager/users/kari/minimal.nix
          #     ./nixosConfigurations/jakobs
          #     inputs.homestakeros-base.nixosModules.kexecTree
          #     inputs.nixos-hardware.nixosModules.raspberry-pi-4
          #   ];
          # };
        in
        {
          # NixOS configuration entrypoints
          nixosConfigurations = with inputs.nixpkgs.lib;
            {
              "eridian" = nixosSystem (withDefaults eridian);
              # "jakobs" = nixosSystem (withDefaults jakobs);
              "maliwan" = nixosSystem (withDefaults maliwan);
              "torgue" = nixosSystem (withDefaults torgue);
              "vladof" = nixosSystem (withDefaults vladof);
              "gearbox" = nixosSystem (withDefaults gearbox);
              "bandit" = nixosSystem (withDefaults bandit);
            };

          # NixOS modules
          nixosModules = {
            sftpClient.imports = [ ./nixosModules/sftp-client.nix ];
            autoScrcpy.imports = [ ./nixosModules/auto-scrcpy.nix ];
            rsyncBackup.imports = [ ./nixosModules/rsync-backup.nix ];
          };
        };
    };
}
