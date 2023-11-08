# https://github.com/Misterio77/nix-config
# https://github.com/jhvst/nix-config
{
  description = "Tupakkatapa's flake";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "http://buidl0.ponkila.com:5000"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "buidl0.ponkila.com:qJZUo9Aji8cTc0v6hIGqbWT8sy+IT/rmSKUFTfhVGGw="
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
            scripts.pxe-serve.exec = ''
              nix run git+ssh://git@github.com/majbacka-labs/Nix-PXE#pxe-serve -- "$@"
            '';
            enterShell = ''
              cat <<INFO

              ### Tupakkatapa's flake ###

              Available commands:

                pxe-serve       : Serves NixOS configurations from a flake as netboot images
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
          "vladof" = vladof.config.system.build.kexecTree;
        };
      };
      flake = let
        inherit (self) outputs;

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
          system = "x86_64-linux";
          specialArgs = {inherit inputs outputs;};
          modules =
            [
              ./home-manager/users/kari
              ./nixosConfigurations/torque
              aagl.nixosModules.default
            ]
            ++ defaultModules;
        };

        vladof = {
          system = "x86_64-linux";
          specialArgs = {inherit inputs outputs;};
          modules =
            [
              ./home-manager/users/kari/minimal.nix
              ./nixosConfigurations/vladof
              ./system/formats/netboot-kexec.nix
            ]
            ++ defaultModules;
        };

        maliwan = {
          system = "x86_64-linux";
          specialArgs = {inherit inputs outputs;};
          modules =
            [
              ./home-manager/users/kari
              ./nixosConfigurations/maliwan
            ]
            ++ defaultModules;
        };

        bandit = {
          system = "x86_64-linux";
          specialArgs = {inherit inputs outputs;};
          modules =
            [
              ./home-manager/users/kari/minimal.nix
              ./nixosConfigurations/bandit
              ./system/formats/netboot-kexec.nix
            ]
            ++ defaultModules;
        };

        hyperion = {
          system = "aarch64-darwin";
          specialArgs = {inherit inputs outputs;};
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
          system = "aarch64-linux";
          specialArgs = {inherit inputs outputs;};
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
        nixosConfigurations =
          with nixpkgs.lib; {
            "bandit" = nixosSystem bandit;
            "jakobs" = nixosSystem jakobs;
            "maliwan" = nixosSystem maliwan;
            "torque" = nixosSystem torque;
            "vladof" = nixosSystem vladof;
          }
          # // (with nixpkgs-stable.lib; {
          # })
          ;

        # Darwin configuration entrypoints
        darwinConfigurations = with darwin.lib; {
          "hyperion" = darwinSystem hyperion;
        };
      };
    };
}
