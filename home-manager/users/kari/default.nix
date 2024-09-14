# https://github.com/hyper-dot/Arch-Hyprland
{ pkgs
, ...
}@args:
let
  user = "kari";
  helpers = import ../../helpers.nix args;
in
{
  # This configuration extends the minimal-gui version
  imports = [ ./minimal-gui.nix ];

  # Misc
  # programs.anime-game-launcher.enable = true;

  # Home-manager config
  home-manager.users."${user}" = {
    # Default apps
    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = helpers.createMimes {
      text = [ "writer.desktop" ];
      spreadsheet = [ "calc.desktop" ];
      presentation = [ "impress.desktop" ];
    };
    xdg.configFile."mimeapps.list".force = true;

    home.packages = with pkgs; [
      monitor-adjust

      # GUI
      libreoffice-qt
      chromium

      # Media creation and editing
      aseprite
      gimp-with-plugins
      kdenlive
      video-trimmer

      # Music production
      ardour
      audacity
      guitarix
      gxplugins-lv2
      ladspaPlugins
      qjackctl
      tuxguitar

      # High Quality Games
      # osu-lazer
      # runelite

      # Networking
      wireguard-go
      wireguard-tools
    ];
  };
}
