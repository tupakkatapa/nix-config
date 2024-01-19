# https://github.com/Misterio77/nix-config
# https://github.com/jhvst/nix-config
{
  description = "Tupakkatapa's flake";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "http://192.168.1.127:5000"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "torque.coditon.com:deBXOnPXp2vEHu4BAvh7TY2aUIOhT481ohsECftxO0E="
    ];
  };

  inputs = {
    devenv.url = "github:cachix/devenv";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    hyprwm-contrib.inputs.nixpkgs.follows = "nixpkgs";
    hyprwm-contrib.url = "github:hyprwm/contrib";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:mic92/sops-nix";

    # Genshin Impact
    aagl.inputs.nixpkgs.follows = "nixpkgs";
    aagl.url = "github:ezKEa/aagl-gtk-on-nix";

    # Netboot stuff
    nixpkgs-patched.url = "github:majbacka-labs/nixpkgs/patch-init1sh"; # stable
    nix-pxe.url = "git+ssh://git@github.com/majbacka-labs/Nix-PXE";
    nixobolus.url = "github:ponkila/nixobolus";
  };

  outputs = {
    self,
    aagl,
    coditon-blog,
    flake-parts,
    home-manager,
    nix-pxe,
    nixobolus,
    nixpkgs,
    nixpkgs-patched,
    nixvim,
    sops-nix,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} rec {
      imports = [
        inputs.devenv.flakeModule
        inputs.flake-parts.flakeModules.easyOverlay
      ];

      systems = nixpkgs.lib.systems.flakeExposed;

      perSystem = {
        pkgs,
        lib,
        config,
        system,
        ...
      }: {
        # Overlays
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            self.overlays.default
          ];
          config = {};
        };
        overlayAttrs = {
          inherit
            (config.packages)
            ping-sweep
            print-banner
            dm-pipewire-out-switcher
            dm-quickfile
            dm-radio
            notify-screenshot
            notify-volume
            notify-pipewire-out-switcher
            notify-not-hyprprop
            lkddb-filter
            ;
        };

        # Nix code formatter, accessible through 'nix fmt'
        formatter = nixpkgs.legacyPackages.${system}.alejandra;

        # Development shell, accessible trough 'nix develop' or 'direnv allow'
        devenv.shells = {
          default = {
            packages = with pkgs; [
              sops
              ssh-to-age
            ];
            env = {
              NIX_CONFIG = ''
                accept-flake-config = true
                extra-experimental-features = flakes nix-command
                warn-dirty = false
              '';
            };
            scripts.init-qemu.exec = ''
              nix run github:ponkila/homestaking-infra?dir=scripts/init-qemu#init-qemu -- "$@"
            '';
            scripts.pxe-generate.exec = ''
              nix run git+ssh://git@github.com/majbacka-labs/Nix-PXE#pxe-generate -- "$@"
            '';
            scripts.lkddb-filter.exec = ''
              nix run git+ssh://git@github.com/majbacka-labs/Nix-PXE#lkddb-filter -- "$@"
            '';
            enterShell = ''
              cat <<INFO

              ### Tupakkatapa's flake ###

              Available commands:

                pxe-generate    : Generates netboot images and iPXE menu from a flake
                lkddb-filter    : Filter LKDDb with PCI data
                init-qemu       : Boot up a host using QEMU

              INFO
            '';
            pre-commit.hooks = {
              alejandra.enable = true;
              shellcheck.enable = true;
              rustfmt.enable = true;
            };
            # Workaround for https://github.com/cachix/devenv/issues/760
            containers = pkgs.lib.mkForce {};
          };
        };

        # Custom packages, accessible trough 'nix build', 'nix run', etc.
        packages =
          rec {
            "ping-sweep" = pkgs.callPackage ./packages/ping-sweep {};
            "print-banner" = pkgs.callPackage ./packages/print-banner {};
            # Wofi scripts
            "dm-pipewire-out-switcher" = pkgs.callPackage ./packages/wofi-scripts/dm-pipewire-out-switcher {};
            "dm-quickfile" = pkgs.callPackage ./packages/wofi-scripts/dm-quickfile {};
            "dm-radio" = pkgs.callPackage ./packages/wofi-scripts/dm-radio {};
            # Notify scripts
            "notify-screenshot" = pkgs.callPackage ./packages/notify-scripts/notify-screenshot {};
            "notify-volume" = pkgs.callPackage ./packages/notify-scripts/notify-volume {};
            "notify-pipewire-out-switcher" = pkgs.callPackage ./packages/notify-scripts/notify-pipewire-out-switcher {};
            "notify-not-hyprprop" = pkgs.callPackage ./packages/notify-scripts/notify-not-hyprprop {};
            # From other projects
            "lkddb-filter" = inputs.nix-pxe.packages.${system}.lkddb-filter;
          }
          # Entrypoint aliases, accessible trough 'nix build'
          // (with flake.nixosConfigurations; {
            "bandit" = bandit.config.system.build.kexecTree;
            "jakobs" = jakobs.config.system.build.kexecTree;
            "vladof" = vladof.config.system.build.squashfs;
          });
      };
      flake = let
        inherit (self) outputs;

        specialArgs = {inherit self inputs outputs;};

        defaultModules = [
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager.sharedModules = [
              nixvim.homeManagerModules.nixvim
            ];
            nixpkgs.overlays = [self.overlays.default];
            system.stateVersion = "23.11";
          }
          ./system
        ];

        torque = {
          inherit specialArgs;
          system = "x86_64-linux";
          modules =
            [
              ./home-manager/users/kari
              ./nixosConfigurations/torque
              aagl.nixosModules.default
            ]
            ++ defaultModules;
        };

        vladof = {
          inherit specialArgs;
          system = "x86_64-linux";
          modules =
            [
              ./home-manager/users/kari/minimal-gui.nix
              ./nixosConfigurations/vladof
              nix-pxe.nixosModules.squashfs
              coditon-blog.nixosModules.default
            ]
            ++ defaultModules;
        };

        maliwan = {
          inherit specialArgs;
          system = "x86_64-linux";
          modules =
            [
              ./home-manager/users/kari
              ./nixosConfigurations/maliwan
              aagl.nixosModules.default
            ]
            ++ defaultModules;
        };

        bandit = {
          inherit specialArgs;
          system = "x86_64-linux";
          modules =
            [
              ./home-manager/users/kari/minimal.nix
              ./nixosConfigurations/bandit
              nixobolus.nixosModules.kexecTree
            ]
            ++ defaultModules;
        };

        jakobs = {
          inherit specialArgs;
          system = "aarch64-linux";
          modules =
            [
              ./home-manager/users/kari/minimal.nix
              ./nixosConfigurations/jakobs
              nixobolus.nixosModules.kexecTree
            ]
            ++ defaultModules;
        };
      in {
        # NixOS configuration entrypoints
        nixosConfigurations = with nixpkgs.lib;
          {
            "bandit" = nixosSystem bandit;
            "jakobs" = nixosSystem jakobs;
            "maliwan" = nixosSystem maliwan;
            "torque" = nixosSystem torque;
          }
          // (with nixpkgs-patched.lib; {
            "vladof" = nixosSystem vladof;
          });
      };
    };
}
