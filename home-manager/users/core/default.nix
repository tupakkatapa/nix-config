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
    imports = [ ./.config/foot.nix ]
      # Importing host-spesific home-manager config if it exists
      ++ optionalPaths [ ../../hosts/${config.networking.hostName}/default.nix ];

    # Allow fonts trough home.packages
    fonts.fontconfig.enable = true;

    # Default apps by user
    home.sessionVariables = {
      TERMINAL = "foot";
      BROWSER = "librewolf";
      FONT = "Noto Sans Mono";
    };

    home.packages = with pkgs; [
      librewolf
      noto-fonts
    ];

    programs.home-manager.enable = true;
    home.stateVersion = "24.05";
  };
}


