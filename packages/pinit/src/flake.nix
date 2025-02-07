{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, ... }@inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
      ];

      perSystem =
        { pkgs
        , system
        , ...
        }:
        let
          packages = {
            foobar = pkgs.callPackage ./package.nix { };
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

          # Development shell -> 'nix develop' or 'direnv allow'
          devShells.default = pkgs.callPackage ./shell.nix { inherit pkgs; };

          # Custom packages and entrypoint aliases -> 'nix run' or 'nix build'
          packages = packages // { default = packages.foobar; };
        };

      flake =
        {
          nixosModules = {
            foobar.imports = [ ./module.nix ];
          };
        };
    };
}
