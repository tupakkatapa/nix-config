{ pkgs, ... }:
{
  imports = [
    ./mako.nix
    ./gtk.nix
    ./hyprland.nix
    ./waybar.nix
    ./wofi.nix
  ];

  home.packages = with pkgs; [
    wl-clipboard
  ];
}
