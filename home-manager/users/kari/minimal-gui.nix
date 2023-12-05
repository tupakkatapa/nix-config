{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  user = "kari";
in {
  # This configuration extends the minimal version
  imports = [
    ./minimal.nix
  ];

  # Home-manager config
  home-manager.users."${user}" = rec {
    imports = [
      ./config/alacritty.nix
      ./config/firefox
      ./config/mpv.nix
    ];

    # Default apps
    home.sessionVariables = {
      BROWSER = "firefox";
      TERMINAL = "alacritty";
      FONT = "JetBrainsMono Nerd Font";
    };

    home.packages = with pkgs; [
      (pkgs.nerdfonts.override {
        fonts = [
          "JetBrainsMono"
        ];
      })
    ];
  };
}
