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
  home-manager.users."${user}" = rec {
    imports = [
      ./.config/alacritty.nix
      ./.config/firefox
      ./.config/mpv.nix
    ];

    # Default apps
    home.sessionVariables = {
      BROWSER = "firefox";
      TERMINAL = "alacritty";
      FONT = "JetBrainsMono Nerd Font";
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
