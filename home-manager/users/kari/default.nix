# https://github.com/hyper-dot/Arch-Hyprland
{ pkgs
, ...
}:
let
  user = "kari";
in
{
  # This configuration extends the minimal-gui version
  imports = [ ./minimal-gui.nix ];

  # Misc
  programs.anime-game-launcher.enable = true;

  # Home-manager config
  home-manager.users."${user}" = rec {
    # Default apps
    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = {
      "application/msword" = [ "writer.desktop" ];
      "application/vnd.oasis.opendocument.spreadsheet" = [ "impress.desktop" ];
      "application/vnd.oasis.opendocument.text" = [ "writer.desktop" ];
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [ "writer.desktop" ];
      "text/csv" = [ "impress.desktop" ];
    };
    xdg.configFile."mimeapps.list".force = true;

    home.packages = with pkgs; [
      #### SELF
      monitor-adjust

      #### GUI
      czkawka
      # gimp-with-plugins
      libreoffice-qt
      #obsidian
      qemu
      rpi-imager
      video-trimmer
      chromium
      palemoon-bin
      filezilla
      kdenlive

      ### Fun
      cool-retro-term
      activate-linux
      cbonsai
      cmatrix
      rig
      sl
      tui-journal
      termusic
      ttyper
      nudoku

      #### High Quality Games
      osu-lazer
      runelite

      #### CLI
      android-tools
      grub2
      ventoy
      chatgpt-cli

      #### Lang
      rustc
      cargo
      rustfmt
      gcc

      #### System Utilities
      nix-tree

      #### Networking
      nmap
      wireguard-go
      wireguard-tools
    ];
  };
}
