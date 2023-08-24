# https://github.com/Misterio77/nix-config
# https://github.com/jhvst/nix-config
{
  description = "Tupakkatapa's flake";

  inputs = {
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    hyprwm-contrib.url = "github:hyprwm/contrib";
    hyprwm-contrib.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pre-commit-hooks-nix.url = "github:hercules-ci/pre-commit-hooks.nix/flakeModule";
  };

  # Add the inputs declared above to the argument attribute set
  outputs = {
    self,
    darwin,
    flake-parts,
    home-manager,
    nixpkgs,
    nixpkgs-stable,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} rec {
      imports = [
        inputs.flake-root.flakeModule
        inputs.pre-commit-hooks-nix.flakeModule
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

        # Git hook scripts for identifying issues before submission
        pre-commit.settings = {
          hooks = {
            shellcheck.enable = true;
            alejandra.enable = true;
          };
        };

        # Devshells for bootstrapping
        # Accessible through 'nix develop' or 'nix-shell' (legacy)
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            cpio
            git
            nix
            nix-tree
            rsync
            ssh-to-age
            zstd
          ];
          inputsFrom = [
            config.flake-root.devShell
          ];
          shellHook = ''
            ${config.pre-commit.installationScript}
          '';
        };

        # Custom packages and aliases for building hosts
        # Accessible through 'nix build', 'nix run', etc
        # packages = with flake.nixosConfigurations; {
        #   "hostname" = hostname.config.system.build.kexecTree;
        # };
      };
      flake = let
        inherit (self) outputs;

        torque = {
          system = "x86_64-linux";
          specialArgs = {inherit inputs outputs;};
          modules = [
            ./nixosConfigurations/torque
            ./home-manager/users/kari
            ./system
            ./system/bootloaders/default.nix
            home-manager.nixosModules.home-manager
          ];
        };

        maliwan = {
          system = "x86_64-linux";
          specialArgs = {inherit inputs outputs;};
          modules = [
            ./nixosConfigurations/maliwan
            ./home-manager/users/kari
            ./system
            ./system/bootloaders/default.nix
            home-manager.nixosModules.home-manager
          ];
        };

        hyperion = {
          system = "aarch64-darwin";
          specialArgs = {inherit inputs outputs;};
          modules = [
            ./nixosConfigurations/hyperion
            ./home-manager/users/kari/darwin.nix
            ./system/nix-settings.nix
            home-manager.darwinModules.home-manager
          ];
        };
      in {
        # Patches and version overrides for some packages
        overlays = import ./overlays {inherit inputs;};

        # Not upstreamed NixOS modules
        #nixosModules = import ./modules;

        # NixOS configuration entrypoints
        nixosConfigurations =
          with nixpkgs.lib; {
            "torque" = nixosSystem torque;
            "maliwan" = nixosSystem maliwan;
          }
          # // (with nixpkgs-stable.lib; {})
          ;

        # Darwin configuration entrypoints
        darwinConfigurations = with darwin.lib; {
          "hyperion" = darwinSystem hyperion;
        };
      };
    };
}
