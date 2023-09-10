{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  # TODO: inputs not in scope, hence commented out hyprprop
  hyprprop = inputs.hyprwm-contrib.packages.${pkgs.system}.hyprprop;
in {
  # Just a reminder that this file should be imported under 'home-manager.users.<username>'
  imports = [
    ./config/dunst.nix
    ./config/gtk.nix
    ./config/hyprland
    #./config/swayidle.nix
    #./config/swaylock.nix
    ./config/waybar.nix
    ./config/wofi.nix
  ];

  home.sessionVariables = {
    FILEMANAGER = lib.mkDefault "nautilus";
  };

  home.packages = with pkgs; [
    # File manager
    gnome3.nautilus
    gnome3.file-roller
    zathura
    imv

    # WM Apps
    blueberry
    grim
    gummy
    hyprpicker
    #hyprprop
    jq
    mpv
    pamixer
    pavucontrol
    playerctl
    pulseaudio
    slurp
    swaybg
    wl-clipboard
  ];
}
