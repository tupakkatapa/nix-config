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

    # Default apps by user
    home.sessionVariables = {
      BROWSER = "firefox";
      FONT = "JetBrainsMono Nerd Font";
      FILEMANAGER = "yazi";
      TERMINAL = "foot";
    };

    # Allow fonts trough home.packages
    fonts.fontconfig.enable = true;

    home.packages = with pkgs; [
      (pkgs.nerdfonts.override {
        fonts = [ "JetBrainsMono" ];
      })
    ];
  };
}
