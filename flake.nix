{
  description = "Tupakkatapa's flake";

  inputs = {
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    hyprland.url = "github:hyprwm/Hyprland";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  # Add the inputs declared above to the argument attribute set
  outputs = {
    self,
    darwin,
    flake-parts,
    home-manager,
    hyprland,
    nixpkgs,
    nixpkgs-stable,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} rec {
      imports = [
        inputs.flake-root.flakeModule
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
        };

        # Custom packages and aliases for building hosts
        # Accessible through 'nix build', 'nix run', etc
        packages = with flake.nixosConfigurations; {
          #"hostname" = hostname.config.system.build.kexecTree;
        };
      };
      flake = let
        inherit (self) outputs;

        torque = {
          system = "x86_64-linux";
          specialArgs = {inherit inputs outputs;};
          modules = [
            ./nixosConfigurations/torque
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
            ./system
            ./system/bootloaders/default.nix
            home-manager.nixosModules.home-manager
          ];
        };
      in {
        # Patches and version overrides for some packages
        overlays = import ./overlays {inherit inputs;};

        # NixOS configuration entrypoints
        nixosConfigurations = with nixpkgs.lib;
          {
            "torque" = nixosSystem torque;
            "maliwan" = nixosSystem maliwan;
          }
          // (with nixpkgs-stable.lib; {});

        # Darwin configuration entrypoints
        darwinConfigurations = with darwin.lib; {};
      };
    };
}
