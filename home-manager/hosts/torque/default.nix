{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: {
  # This file should be imported under 'home-manager.users.<username>'
  # See 'home-manager/users/kari/minimal.nix' for an example how to do this conditionally

  imports = [
    #./config/swayidle.nix
    #./config/swaylock.nix
    ./config/dunst.nix
    ./config/gtk.nix
    ./config/hyprland.nix
    ./config/waybar.nix
    ./config/wofi.nix
  ];

  # Default apps
  home.sessionVariables = {
    FILEMANAGER = "nautilus";
    FONT = "JetBrainsMono Nerd Font";
  };
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "application/pdf" = ["org.pwmt.zathura.desktop"];
    "all/text" = ["org.gnome.TextEditor"];
    "image/jpeg" = ["imv.desktop"];
    "image/png" = ["imv.desktop"];
  };
  xdg.configFile."mimeapps.list".force = true;

  # Allow fonts trough home.packages
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # File manager
    gnome3.nautilus
    gnome3.file-roller
    gnome-text-editor
    zathura
    imv

    # Fonts
    (pkgs.nerdfonts.override {fonts = ["JetBrainsMono"];})
    font-awesome # for waybar

    # WM Apps
    swaybg
    wl-clipboard
    pavucontrol
    pulseaudio
  ];
}
