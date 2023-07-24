{
  description = "Tupakkatapa's flake";

  inputs = {
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    mission-control.url = "github:Platonic-Systems/mission-control";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";
    pre-commit-hooks-nix.url = "github:hercules-ci/pre-commit-hooks.nix/flakeModule";
    sops-nix.url = "github:Mic92/sops-nix";
    hyprland.url = "github:hyprwm/Hyprland";
  };

  # Add the inputs declared above to the argument attribute set
  outputs =
    { self
    , darwin
    , flake-parts
    , home-manager
    , hyprland
    , nixpkgs
    , nixpkgs-stable
    , sops-nix
    , ...
    }@inputs:

    flake-parts.lib.mkFlake { inherit inputs; } rec {

      imports = [
        inputs.flake-root.flakeModule
        inputs.mission-control.flakeModule
        inputs.pre-commit-hooks-nix.flakeModule
      ];
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      perSystem = { pkgs, lib, config, system, ... }: {
        # Nix code formatter, accessible through 'nix fmt'
        formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

        # Git hook scripts for identifying issues before submission
        pre-commit.settings = {
          # hooks = {
          #   shellcheck.enable = true;
          #   nixpkgs-fmt.enable = true;
          #   flakecheck = {
          #     enable = true;
          #     name = "flakecheck";
          #     description = "Check whether the flake evaluates and run its tests.";
          #     entry = "nix flake check --no-warn-dirty";
          #     language = "system";
          #     pass_filenames = false;
          #   };
          # };
        };
        # Do not perform hooks with 'nix flake check'
        pre-commit.check.enable = false;

        # Development tools for devshell
        mission-control.scripts = {
          nsq = {
            description = "Get and update the nix-store queries.";
            exec = ''
              sh ./scripts/get-store-queries.sh
            '';
            category = "Development Tools";
          };
          qemu = {
            description = "Use QEMU to boot up a host.";
            exec = ''
              nix run path:scripts/init-qemu#init-qemu -- "$@"
            '';
            category = "Development Tools";
          };
          disko = {
            description = "Format disks according to the mount.nix of the current host.";
            exec = ''
              nix run github:nix-community/disko -- --mode zap_create_mount ./nixosConfigurations/"$(hostname)"/mounts.nix
            '';
            category = "System Utilities";
          };
        };

        # Devshells for bootstrapping
        # Accessible through 'nix develop' or 'nix-shell' (legacy)
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            git
            nix
            nix-tree
            sops
            ssh-to-age
            rsync
            zstd
            cpio
          ];
          inputsFrom = [
            config.flake-root.devShell
            config.mission-control.devShell
          ];
          shellHook = ''
            ${config.pre-commit.installationScript}
          '';
        };

        # Custom packages and aliases for building hosts
        # Accessible through 'nix build', 'nix run', etc
        packages = with flake.nixosConfigurations; {
          # "torque" = torque.config.system.build.kexecTree;
          # "maliwan" = maliwan.config.system.build.kexecTree;
        };
      };
      flake =
        let
          inherit (self) outputs;

          torque = {
            system = "x86_64-linux";
            specialArgs = { inherit inputs outputs; };
            modules = [
              ./nixosConfigurations/torque
              ./system
              ./system/bootloaders/default.nix
              ./home-manager/kari
              sops-nix.nixosModules.sops
              home-manager.nixosModules.home-manager
            ];
          };

          maliwan = {
            system = "x86_64-linux";
            specialArgs = { inherit inputs outputs; };
            modules = [
              ./nixosConfigurations/torque
              ./system
              ./home-manager/kari
              ./system/bootloaders/default.nix
              sops-nix.nixosModules.sops
              home-manager.nixosModules.home-manager
            ];
          };
        in
        {
          # Patches and version overrides for some packages
          overlays = import ./overlays { inherit inputs; };

          # NixOS configuration entrypoints
          nixosConfigurations = with nixpkgs.lib; {
            "torque" = nixosSystem torque;
            "maliwan" = nixosSystem maliwan;
          } // (with nixpkgs-stable.lib; { });

          # Darwin configuration entrypoints        
          darwinConfigurations = with darwin.lib; { };
        };
    };
}
