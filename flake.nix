# https://github.com/Misterio77/nix-config
# https://github.com/jhvst/nix-config
{
  description = "Tupakkatapa's flake";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "http://torgue.coditon.com:5000"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "torgue.coditon.com:deBXOnPXp2vEHu4BAvh7TY2aUIOhT481ohsECftxO0E="
    ];
    extraOptions = ''
      download-attempts = 3
      connect-timeout = 5
      fallback = true
    '';
  };

  inputs = {
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";
    agenix-rekey.url = "github:oddlama/agenix-rekey";
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
    nixpkgs-patched.url = "github:majbacka-labs/nixpkgs/patch-init1sh"; # stable
    # nixpkgs-patched.url = "git+file:///home/kari/Workspace/nixpkgs\?ref=patch-init1sh"; # stable
    nixie.url = "git+ssh://git@github.com/majbacka-labs/nixie\?ref=jesse/bugs";
    # nixie.url = "git+file:///home/kari/Workspace/nixie\?ref=jesse/refind-generate";
    homestakeros-base.url = "github:ponkila/HomestakerOS\?dir=nixosModules/base";

    # Other
    musnix.url = "github:musnix/musnix";
    musnix.inputs.nixpkgs.follows = "nixpkgs";
    nix-extras.url = "git+https://git.sr.ht/~dblsaiko/nix-extras";
    coditon-md.url = "github:tupakkatapa/coditon-md";
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
              config.agenix-rekey.package
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
              "gearbox" = gearbox.config.system.build.squashfs;
              "eridian" = eridian.config.system.build.kexecTree;
              # "jakobs" = jakobs.config.system.build.kexecTree;
              "vladof" = vladof.config.system.build.squashfs;
            })
            // packages;

          # Hosts that should use agenix-rekey for secret management
          agenix-rekey.nodes = { inherit (self.nixosConfigurations) vladof torgue maliwan eridian jakobs; };
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
              inputs.agenix-rekey.nixosModules.default
              inputs.agenix.nixosModules.default
              inputs.home-manager.nixosModules.home-manager
              self.nixosModules.sftpClient
              {
                home-manager.sharedModules = [
                  inputs.nixvim.homeManagerModules.nixvim
                ];
              }
            ];
          };

          # Hosts
          torgue = withExtra {
            modules = [
              ./home-manager/users/kari
              ./nixosConfigurations/torgue
              inputs.aagl.nixosModules.default
              inputs.musnix.nixosModules.musnix
              inputs.nixos-hardware.nixosModules.common-gpu-amd
              self.nixosModules.autoScrcpy
              {
                age.rekey = {
                  localStorageDir = ./nixosConfigurations/torgue/secrets/rekey;
                  masterIdentities = [{
                    identity = ./master.hmac;
                    pubkey = "age1snpq9cusnjf7rnhjmrtjnzrs6cjpasx82h9j77fe9hewgk60lgcqnnvejw";
                  }];
                  storageMode = "local";
                };
              }
            ];
          };

          vladof = withExtra {
            modules = [
              ./home-manager/users/kari/minimal-gui.nix
              ./nixosConfigurations/vladof
              inputs.nixie.nixosModules.squashfs
              inputs.coditon-md.nixosModules.default
              inputs.nixos-hardware.nixosModules.common-gpu-intel
              {
                age.rekey = {
                  localStorageDir = ./nixosConfigurations/vladof/secrets/rekey;
                  masterIdentities = [{
                    identity = ./master.hmac;
                    pubkey = "age1snpq9cusnjf7rnhjmrtjnzrs6cjpasx82h9j77fe9hewgk60lgcqnnvejw";
                  }];
                  storageMode = "local";
                };
              }
            ];
          };

          eridian = withExtra {
            modules = [
              ./home-manager/users/kari/minimal.nix
              ./nixosConfigurations/eridian
              inputs.nixie.nixosModules.nixie
              inputs.homestakeros-base.nixosModules.kexecTree
              {
                age.rekey = {
                  localStorageDir = ./nixosConfigurations/eridian/secrets/rekey;
                  masterIdentities = [{
                    identity = ./master.hmac;
                    pubkey = "age1snpq9cusnjf7rnhjmrtjnzrs6cjpasx82h9j77fe9hewgk60lgcqnnvejw";
                  }];
                  storageMode = "local";
                };
              }
            ];
          };

          maliwan = withExtra {
            modules = [
              ./home-manager/users/kari/minimal-gui.nix
              ./nixosConfigurations/maliwan
              inputs.nixos-hardware.nixosModules.common-gpu-intel
              {
                age.rekey = {
                  localStorageDir = ./nixosConfigurations/maliwan/secrets/rekey;
                  masterIdentities = [{
                    identity = ./master.hmac;
                    pubkey = "age1snpq9cusnjf7rnhjmrtjnzrs6cjpasx82h9j77fe9hewgk60lgcqnnvejw";
                  }];
                  storageMode = "local";
                };
              }
            ];
          };

          bandit.modules = [
            ./nixosConfigurations/bandit
            ./home-manager/users/core
            inputs.homestakeros-base.nixosModules.kexecTree
          ];

          gearbox.modules = [
            ./nixosConfigurations/gearbox
            ./home-manager/users/core
            inputs.nixie.nixosModules.squashfs
            inputs.nixos-hardware.nixosModules.common-gpu-intel
          ];

          # jakobs = withExtra {
          #   system = "aarch64-linux";
          #   modules = [
          #     ./home-manager/users/kari/minimal.nix
          #     ./nixosConfigurations/jakobs
          #     inputs.homestakeros-base.nixosModules.kexecTree
          #     inputs.nixos-hardware.nixosModules.raspberry-pi-4
          #     {
          #       age.rekey = {
          #         localStorageDir = ./nixosConfigurations/jakobs/secrets/rekey;
          #         masterIdentities = [{
          #           identity = ./master.hmac;
          #           pubkey = "age1snpq9cusnjf7rnhjmrtjnzrs6cjpasx82h9j77fe9hewgk60lgcqnnvejw";
          #         }];
          #         storageMode = "local";
          #       };
          #       home-manager.sharedModules = [
          #         inputs.nixvim.homeManagerModules.nixvim
          #       ];
          #     }
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
            }
            // (with inputs.nixpkgs-stable.lib; {
              "bandit" = nixosSystem (withDefaults bandit);
            })
            // (with inputs.nixpkgs-patched.lib; {
              "gearbox" = nixosSystem (withDefaults gearbox);
              "vladof" = nixosSystem (withDefaults vladof);
            });

          # NixOS modules
          nixosModules = {
            sftpClient.imports = [ ./nixosModules/sftp-client.nix ];
            autoScrcpy.imports = [ ./nixosModules/auto-scrcpy.nix ];
            rsyncBackup.imports = [ ./nixosModules/rsync-backup.nix ];
          };
        };
    };
}
