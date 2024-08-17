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

    # Screenshare
    programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        # obs-backgroundremoval
        # obs-pipewire-audio-capture
      ];
    };

    home.packages = with pkgs; [
      monitor-adjust

      # GUI
      # czkawka
      libreoffice-qt
      # obsidian
      qemu
      rpi-imager
      chromium
      palemoon-bin
      filezilla
      arduino-ide
      discord

      # Fun
      # cbonsai
      # cmatrix
      # cool-retro-term
      # nudoku
      # rig
      # sl
      # termusic
      # ttyper
      # tui-journal

      # Media creation and editing
      aseprite
      gimp-with-plugins
      kdenlive
      video-trimmer

      # Music production
      qjackctl
      ardour
      audacity
      guitarix
      gxplugins-lv2
      ladspaPlugins

      # High Quality Games
      # osu-lazer
      # runelite

      # CLI
      android-tools
      grub2
      ventoy
      # chatgpt-cli

      # Lang
      rustc
      cargo
      rustfmt
      gcc
      jdk22

      # System Utilities
      nix-tree

      # Networking
      nmap
      wireguard-go
      wireguard-tools
    ];
  };
}
