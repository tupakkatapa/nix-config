{ pkgs, ... }:
{
  imports = [
    # ./hyprbars.nix
    # ./swayidle.nix
    # ./swaylock.nix
    # ./dunst.nix
    ./mako.nix
    ./gtk.nix
    ./hyprland.nix
    ./rgb.nix
    ./waybar.nix
    ./wofi.nix
  ];

  home.packages = with pkgs; [
    wl-clipboard
  ];
}
