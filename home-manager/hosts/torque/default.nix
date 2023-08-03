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
    ./config/swayidle.nix
    ./config/swaylock.nix
    ./config/waybar.nix
    ./config/wofi.nix
  ];

  home.packages = with pkgs; [
    # GUI Apps
    nsxiv
    xfce.thunar
    xfce.thunar-archive-plugin

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
