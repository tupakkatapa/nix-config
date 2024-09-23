{ pkgs, config, inputs, ... }:
let
  user = "core";
  optionalPaths = paths: builtins.filter (path: builtins.pathExists path) paths;
in
{
  # This configuration extends the minimal version
  imports = [ ./minimal.nix ];

  # Allows access to flake inputs and custom packages
  home-manager.extraSpecialArgs = { inherit inputs pkgs; };

  # Move existing files rather than exiting with an error
  home-manager.backupFileExtension = "bak";

  home-manager.users."${user}" = {
    # Importing host-spesific home-manager config if it exists
    imports = optionalPaths [ ../../hosts/${config.networking.hostName}/default.nix ];

    # Default apps
    home.sessionVariables = {
      TERMINAL = "foot";
      BROWSER = "librewolf";
    };

    home.packages = with pkgs; [
      librewolf
    ];

    programs.foot.enable = true;
    programs.home-manager.enable = true;
    home.stateVersion = "24.05";
  };
}


