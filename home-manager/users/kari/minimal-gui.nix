{ pkgs
, ...
}:
let
  user = "kari";
in
{
  # This configuration extends the minimal version
  imports = [ ./minimal.nix ];

  # Home-manager config
  home-manager.users."${user}" = {
    imports = [
      ./.config/foot.nix
      ./.config/firefox
      ./.config/mpv.nix
      ./.config/imv.nix
    ];

    # Allow fonts trough home.packages
    fonts.fontconfig.enable = true;

    # Default apps by user
    home.sessionVariables = {
      BROWSER = "firefox";
      FONT = "JetBrainsMono Nerd Font";
      TERMINAL = "foot";
      THEME = "gruvbox-dark-medium";
    };

    home.packages = with pkgs; [
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    ];
  };
}
