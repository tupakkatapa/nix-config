{ pkgs
, ...
}:
let
  user = "kari";
in
{
  # This configuration extends the minimal-passwd version
  imports = [ ./minimal-passwd.nix ];

  # Home-manager config
  home-manager.users."${user}" = {
    imports = [
      ./.config/foot.nix
      ./.config/firefox
      ./.config/mpv.nix
      ./.config/imv.nix
    ];

    # Default apps
    home.sessionVariables = {
      BROWSER = "firefox";
      FONT = "JetBrainsMono Nerd Font";
      FILEMANAGER = "yazi";
      TERMINAL = "foot";
    };

    # Allow fonts trough home.packages
    fonts.fontconfig.enable = true;

    home.packages = with pkgs; [
      ferdium
      plexamp
      sublime-merge

      (pkgs.nerdfonts.override {
        fonts = [ "JetBrainsMono" ];
      })
    ];
  };
}
