# https://github.com/Misterio77/nix-config
# https://github.com/jhvst/nix-config
{
  description = "Tupakkatapa's flake";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "http://torque.coditon.com:5000"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "torque.coditon.com:deBXOnPXp2vEHu4BAvh7TY2aUIOhT481ohsECftxO0E="
    ];
  };

  inputs = {
    aagl.inputs.nixpkgs.follows = "nixpkgs";
    aagl.url = "github:ezKEa/aagl-gtk-on-nix";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    devenv.url = "github:cachix/devenv";
    firefox-addons.inputs.nixpkgs.follows = "nixpkgs";
    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    hyprwm-contrib.inputs.nixpkgs.follows = "nixpkgs";
    hyprwm-contrib.url = "github:hyprwm/contrib";
    nixpkgs-stable-patched.url = "github:majbacka-labs/nixpkgs/patch-init1sh";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:mic92/sops-nix";
  };

  # Add the inputs declared above to the argument attribute set
  outputs = {
    self,
    aagl,
    darwin,
    flake-parts,
    home-manager,
    nixpkgs,
    nixpkgs-stable,
    nixpkgs-stable-patched,
    nixvim,
    sops-nix,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} rec {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      perSystem = {
        config,
        lib,
        pkgs,
        system,
        ...
      }: {
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
              nix run git+ssh://git@github.com/majbacka-labs/Nix-PXE\?ref=stage1net#pxe-generate -- "$@"
            '';
            scripts.lkddb-filter.exec = ''
              nix run git+ssh://git@github.com/majbacka-labs/Nix-PXE\?ref=stage1net#lkddb-filter -- "$@"
            '';
            enterShell = ''
              cat <<INFO

              ### Tupakkatapa's flake ###

              Available commands:

                pxe-generate    : Generates netboot images and iPXE menu from a flake
                init-qemu       : Boot up a host using QEMU

              INFO
            '';
            pre-commit.hooks = {
              alejandra.enable = true;
              shellcheck.enable = true;
            };
            # Workaround for https://github.com/cachix/devenv/issues/760
            containers = pkgs.lib.mkForce {};
          };
        };

        # Custom packages and aliases for building hosts
        # Accessible through 'nix build', 'nix run', etc
        packages = with flake.nixosConfigurations; {
          "bandit" = bandit.config.system.build.kexecTree;
          "jakobs" = jakobs.config.system.build.kexecTree;
          "vladof" = vladof.config.system.build.squashfs;
        };
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
              ./home-manager/users/kari/minimal.nix
              ./nixosConfigurations/vladof
              ./system/formats/netboot-squashfs.nix
              ./system/patches/init1-network-base.nix
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
              ./system/formats/netboot-kexec.nix
            ]
            ++ defaultModules;
        };

        hyperion = {
          inherit specialArgs;
          system = "aarch64-darwin";
          modules = [
            ./home-manager/users/kari/darwin.nix
            ./nixosConfigurations/hyperion
            ./system/nix-settings.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.sharedModules = [
                nixvim.homeManagerModules.nixvim
              ];
            }
          ];
        };

        jakobs = {
          inherit specialArgs;
          system = "aarch64-linux";
          modules =
            [
              ./home-manager/users/kari/minimal.nix
              ./nixosConfigurations/jakobs
              ./system/formats/netboot-kexec.nix
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
          // (with nixpkgs-stable-patched.lib; {
            "vladof" = nixosSystem vladof;
          });

        # Darwin configuration entrypoints
        darwinConfigurations = with darwin.lib; {
          "hyperion" = darwinSystem hyperion;
        };
      };
    };
}
