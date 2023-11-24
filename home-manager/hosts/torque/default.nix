{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  # Allow access to flake inputs with 'home-manager.extraSpecialArgs = { inherit inputs; };'
  hyprprop = inputs.hyprwm-contrib.packages.${pkgs.system}.hyprprop;
in {
  # This file should be imported under 'home-manager.users.<username>'
  # See 'users/kari/minimal.nix' for an example how to do this conditionally

  imports = [
    #./config/swayidle.nix
    #./config/swaylock.nix
    ./config/dunst.nix
    ./config/gtk.nix
    ./config/hyprland
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
    (pkgs.nerdfonts.override {
      fonts = [
        "JetBrainsMono"
      ];
    })
    font-awesome # for waybar

    # WM Apps
    blueberry
    grim
    gummy
    hyprpicker
    hyprprop
    jq
    pamixer
    pavucontrol
    playerctl
    pulseaudio
    slurp
    swaybg
    wl-clipboard
  ];
}
