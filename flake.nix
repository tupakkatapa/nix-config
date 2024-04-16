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
    devenv.url = "github:cachix/devenv";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:mic92/sops-nix";
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
    nixie.url = "git+ssh://git@github.com/majbacka-labs/nixie\?ref=jesse/bugs";
    homestakeros-base.url = "github:ponkila/HomestakerOS\?dir=nixosModules/base";

    # Other
    nix-extras.url = "git+https://git.sr.ht/~dblsaiko/nix-extras";
    coditon-md.url = "github:tupakkatapa/coditon-md";
  };

  outputs =
    { self
    , aagl
    , coditon-md
    , flake-parts
    , home-manager
    , homestakeros-base
    , nix-extras
    , nixie
    , nixos-hardware
    , nixpkgs
    , nixpkgs-patched
    , nixpkgs-stable
    , nixvim
    , sops-nix
    , ...
    } @ inputs:
    flake-parts.lib.mkFlake { inherit inputs; } rec {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.devenv.flakeModule
        inputs.flake-parts.flakeModules.easyOverlay
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        { pkgs
        , lib
        , config
        , system
        , inputs'
        , ...
        }:
        let
          packages = rec {
            "tupakkatapa-utils" = pkgs.callPackage ./packages/tupakkatapa-utils { };
            "monitor-adjust" = pkgs.callPackage ./packages/monitor-adjust { };
            "ping-sweep" = pkgs.callPackage ./packages/ping-sweep { };
            "pipewire-out-switcher" = pkgs.callPackage ./packages/pipewire-out-switcher { };
            "pinit" = pkgs.callPackage ./packages/pinit { };
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
              sops
              ssh-to-age
              pxe-generate
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
              treefmt.enable = true;
            };
            pre-commit.settings.treefmt.package = config.treefmt.build.wrapper;
            # Workaround for https://github.com/cachix/devenv/issues/760
            containers = pkgs.lib.mkForce { };
          };

          # Custom packages and entrypoint aliases -> 'nix run' or 'nix build'
          packages =
            (with flake.nixosConfigurations; {
              "bandit" = bandit.config.system.build.kexecTree;
              "gearbox" = gearbox.config.system.build.squashfs;
              "eridian" = eridian.config.system.build.kexecTree;
              "jakobs" = jakobs.config.system.build.kexecTree;
              "vladof" = vladof.config.system.build.squashfs;
            })
            // packages;
        };
      flake =
        let
          inherit (self) outputs;

          withDefaults = config: {
            specialArgs = { inherit inputs outputs; };
            system = config.system or "x86_64-linux";
            modules =
              config.modules
              ++ [
                sops-nix.nixosModules.sops
                home-manager.nixosModules.home-manager
                nix-extras.nixosModules.all
                self.nixosModules.sftpClient
                self.nixosModules.rsyncBackup
                self.nixosModules.autoScrcpy
                {
                  home-manager.sharedModules = [
                    nixvim.homeManagerModules.nixvim
                  ];
                  nixpkgs.overlays = [
                    self.overlays.default
                  ];
                  system.stateVersion = "23.11";
                }
                ./system/base.nix
                ./system/nix-settings.nix
                ./system/openssh.nix
              ];
          };

          torgue.modules = [
            ./home-manager/users/kari
            ./nixosConfigurations/torgue
            aagl.nixosModules.default
            nixos-hardware.nixosModules.common-gpu-amd
          ];

          vladof.modules = [
            ./home-manager/users/kari/minimal-gui.nix
            ./nixosConfigurations/vladof
            nixie.nixosModules.squashfs
            coditon-md.nixosModules.default
            nixos-hardware.nixosModules.common-gpu-intel
          ];

          eridian.modules = [
            ./home-manager/users/kari/minimal.nix
            ./nixosConfigurations/eridian
            nixie.nixosModules.nixie
            homestakeros-base.nixosModules.kexecTree
          ];

          maliwan.modules = [
            ./home-manager/users/kari/minimal-gui.nix
            ./nixosConfigurations/maliwan
            nixos-hardware.nixosModules.common-gpu-intel
          ];

          bandit.modules = [
            ./nixosConfigurations/bandit
            ./home-manager/users/core
            homestakeros-base.nixosModules.kexecTree
          ];

          gearbox.modules = [
            ./nixosConfigurations/gearbox
            ./home-manager/users/core
            nixie.nixosModules.squashfs
            nixos-hardware.nixosModules.common-gpu-intel
          ];

          jakobs = {
            system = "aarch64-linux";
            modules = [
              ./home-manager/users/kari/minimal.nix
              ./nixosConfigurations/jakobs
              homestakeros-base.nixosModules.kexecTree
              inputs.nixos-hardware.nixosModules.raspberry-pi-4
            ];
          };
        in
        {
          # NixOS configuration entrypoints
          nixosConfigurations = with nixpkgs.lib;
            {
              "eridian" = nixosSystem (withDefaults eridian);
              "jakobs" = nixosSystem (withDefaults jakobs);
              "maliwan" = nixosSystem (withDefaults maliwan);
              "torgue" = nixosSystem (withDefaults torgue);
            }
            // (with nixpkgs-stable.lib; {
              "bandit" = nixosSystem (withDefaults bandit);
            })
            // (with nixpkgs-patched.lib; {
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
